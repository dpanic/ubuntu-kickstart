#!/bin/bash
set -euo pipefail

# Kickstart
# Author: Dusan Panic <dpanic@gmail.com>
# https://github.com/dpanic/ubuntu-kickstart
#
# Interactive TUI launcher using Charmbracelet's gum
# Supports Ubuntu (apt) and macOS (brew)

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$REPO_DIR/modules"
LOG_DIR="$REPO_DIR/logs"
mkdir -p "$LOG_DIR"

source "$REPO_DIR/lib.sh"

# ─── Bootstrap gum ───────────────────────────────────────────────────────────

ensure_gum() {
    if command -v gum &>/dev/null; then
        return
    fi

    echo "gum not found -- installing Charmbracelet gum..."
    if is_macos; then
        ensure_brew
        brew install gum
    else
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key \
            | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
            | sudo tee /etc/apt/sources.list.d/charm.list >/dev/null
        sudo apt-get update -qq
        sudo apt-get install -y gum
    fi
    echo ""
}

ensure_gum

# ─── Colors & styles ─────────────────────────────────────────────────────────

ACCENT="212"       # pink
ACCENT2="39"       # cyan
BORDER="rounded"
OK_COLOR="78"      # green
WARN_COLOR="208"   # orange
BOLD_WHITE=$'\033[1;37m'
DIM=$'\033[2m'
RST=$'\033[0m'

# ─── Banner ──────────────────────────────────────────────────────────────────

show_banner() {
    local title subtitle author banner

    title=$(gum style \
        --foreground "$ACCENT" \
        --bold \
        "  Kickstart")

    subtitle=$(gum style \
        --foreground "$ACCENT2" \
        --faint \
        "  System optimization & dev environment setup")

    author=$(gum style \
        --faint \
        "  by Dusan Panic <dpanic@gmail.com>")

    banner=$(printf "%s\n%s\n%s" "$title" "$subtitle" "$author")

    gum style \
        --border "$BORDER" \
        --border-foreground "$ACCENT" \
        --padding "1 3" \
        --margin "1 0" \
        "$banner"
}

# ─── Item registry ───────────────────────────────────────────────────────────
# Format: "os|script|component|label"
#   os: "all", "linux", or "macos"
#   component empty = standalone script
#   component set   = sub-item of a grouped script

ALL_ITEMS=(
    # ── Optimizations ──
    "linux|gnome/optimize.sh||GNOME Optimize -- disable animations, sounds, hot corners"
    "linux|nautilus/optimize.sh||Nautilus Optimize -- restrict Tracker, limit thumbnails"
    "linux|apparmor/setup.sh||AppArmor Setup -- learning mode with Slack reminder"
    "linux|kernel/optimize.sh|sysctl|Kernel ▸ sysctl.conf (network, memory, conntrack tuning)"
    "linux|kernel/optimize.sh|limits|Kernel ▸ file descriptor & process limits"
    "linux|kernel/optimize.sh|scheduler|Kernel ▸ I/O scheduler (none -- SSD/NVMe)"
    "linux|kernel/optimize.sh|autotune|Kernel ▸ RAM-based autotune service"
    "linux|sshd/setup.sh||SSH ▸ sshd hardening (disables password auth)"
    # ── Installations ──
    "all|---||"
    "all|---||── Installations ─────────────────────────────"
    "all|shell/install.sh|zsh|Shell ▸ zsh + oh-my-zsh"
    "all|shell/install.sh|fzf|Shell ▸ fzf (fuzzy finder)"
    "all|shell/install.sh|starship|Shell ▸ starship prompt"
    "all|shell/install.sh|direnv|Shell ▸ direnv"
    "all|shell/install.sh|plugins|Shell ▸ zsh plugins (autosuggestions, syntax-highlighting)"
    "all|shell/install.sh|nvm|Shell ▸ nvm (Node version manager)"
    "all|shell/install.sh|git|Shell ▸ git config (LFS, SSH-over-HTTPS)"
    "linux|shell/install.sh|byobu|Shell ▸ byobu + tmux"
    "all|---||"
    "all|terminal/install.sh|ncdu|Terminal ▸ ncdu (disk analyzer)"
    "all|yazi/install.sh||Yazi -- terminal file manager"
    "all|---||"
    "all|docker/install.sh||Docker -- engine, compose, buildx, daemon config"
    "all|go/install.sh||Go -- programming language from go.dev"
    "all|neovim/install.sh||Neovim + LazyVim -- editor with IDE features"
    "all|---||"
    "linux|browsers/install.sh|chrome|Browser ▸ Google Chrome"
    "linux|browsers/install.sh|brave|Browser ▸ Brave"
    "linux|browsers/install.sh|signal|App ▸ Signal Desktop"
    "linux|peazip/install.sh||PeaZip -- archive manager (200+ formats)"
)

check_installed() {
    local script="$1" component="$2"
    case "$script" in
        ---) return 1 ;;
        gnome/optimize.sh|nautilus/optimize.sh|apparmor/setup.sh)
            return 1 ;;
        kernel/optimize.sh)
            case "$component" in
                sysctl)    [[ -f /etc/sysctl.conf ]] && grep -q "tcp_congestion_control = bbr" /etc/sysctl.conf 2>/dev/null ;;
                limits)    [[ -f /etc/security/limits.conf ]] && grep -q "KICKSTART" /etc/security/limits.conf 2>/dev/null ;;
                scheduler) [[ -f /etc/udev/rules.d/60-scheduler.rules ]] ;;
                autotune)  [[ -f /usr/bin/autotune.sh ]] && systemctl is-enabled autotune.service &>/dev/null ;;
                *)         return 1 ;;
            esac ;;
        sshd/setup.sh)
            [[ -f /etc/ssh/sshd_config ]] && grep -q "KICKSTART" /etc/ssh/sshd_config 2>/dev/null ;;
        shell/install.sh)
            case "$component" in
                zsh)     [[ -d "$HOME/.oh-my-zsh" ]] && command -v zsh &>/dev/null ;;
                fzf)     [[ -d "$HOME/.fzf" ]] ;;
                starship) command -v starship &>/dev/null ;;
                direnv)  command -v direnv &>/dev/null ;;
                plugins) [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]] ;;
                nvm)     [[ -d "$HOME/.nvm" ]] ;;
                byobu)   command -v byobu &>/dev/null ;;
                git)     [[ -f "$HOME/.gitconfig" ]] ;;
                *)       return 1 ;;
            esac ;;
        terminal/install.sh)
            case "$component" in
                ncdu)  command -v ncdu &>/dev/null ;;
                *)     return 1 ;;
            esac ;;
        docker/install.sh)   command -v docker &>/dev/null ;;
        go/install.sh)       command -v go &>/dev/null || [[ -x /usr/local/go/bin/go ]] ;;
        yazi/install.sh)     command -v yazi &>/dev/null ;;
        neovim/install.sh)   command -v nvim &>/dev/null ;;
        browsers/install.sh)
            case "$component" in
                chrome) command -v google-chrome &>/dev/null || command -v google-chrome-stable &>/dev/null ;;
                brave)  command -v brave-browser &>/dev/null ;;
                signal) command -v signal-desktop &>/dev/null ;;
                *)      return 1 ;;
            esac ;;
        peazip/install.sh)   command -v peazip &>/dev/null || (dpkg -l peazip 2>/dev/null | grep -q '^ii') ;;
        *) return 1 ;;
    esac
}

build_items() {
    ITEMS=()
    for entry in "${ALL_ITEMS[@]}"; do
        local item_os="${entry%%|*}"
        local rest="${entry#*|}"
        if [[ "$item_os" == "all" ]] || [[ "$item_os" == "$OS" ]]; then
            ITEMS+=("$rest")
        fi
    done
}

build_items

# ─── Update availability checks (parallel) ───────────────────────────────────

declare -A UPDATE_AVAIL

_git_update_check() {
    local dir="$1"
    local branch
    branch=$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null) || branch="master"
    timeout 5 git -C "$dir" fetch origin --depth=1 -q 2>/dev/null || return
    local loc rem
    loc=$(git -C "$dir" rev-parse HEAD 2>/dev/null)
    rem=$(git -C "$dir" rev-parse "origin/$branch" 2>/dev/null)
    if [[ -n "$loc" && -n "$rem" ]]; then
        [[ "$loc" != "$rem" ]] && echo "update" || echo "latest"
    fi
}

_gh_release_check() {
    local current="$1" repo="$2"
    local latest
    latest=$(curl -fsSI -m 5 "https://github.com/$repo/releases/latest" 2>/dev/null \
        | grep -i '^location:' | sed 's|.*/v\?||' | tr -d '\r\n')
    [[ -z "$latest" || -z "$current" ]] && return
    [[ "$current" != "$latest" ]] && echo "update" || echo "latest"
}

_UPDATE_TMPDIR=""

_run_update_checks() {
    local tmpdir="$1"
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    [[ -d "$HOME/.fzf" ]] && \
        (_git_update_check "$HOME/.fzf" > "$tmpdir/fzf") &

    [[ -d "$HOME/.oh-my-zsh" ]] && \
        (_git_update_check "$HOME/.oh-my-zsh" > "$tmpdir/zsh") &

    [[ -d "$zsh_custom/plugins/zsh-autosuggestions" ]] && \
        (_git_update_check "$zsh_custom/plugins/zsh-autosuggestions" > "$tmpdir/plugins_a") &

    [[ -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]] && \
        (_git_update_check "$zsh_custom/plugins/zsh-syntax-highlighting" > "$tmpdir/plugins_s") &

    command -v starship &>/dev/null && \
        (v=$(starship --version 2>/dev/null | awk '{print $2}' | head -1)
         _gh_release_check "$v" "starship/starship" > "$tmpdir/starship") &

    [[ -d "$HOME/.nvm" ]] && \
        (v=$(cd "$HOME/.nvm" && git describe --tags --abbrev=0 HEAD 2>/dev/null | sed 's/^v//')
         _gh_release_check "$v" "nvm-sh/nvm" > "$tmpdir/nvm") &

    (command -v go &>/dev/null || [[ -x /usr/local/go/bin/go ]]) && \
        (v=$( (go version 2>/dev/null || /usr/local/go/bin/go version 2>/dev/null) | awk '{print $3}')
         latest=$(curl -fsSL -m 5 https://go.dev/VERSION?m=text 2>/dev/null | head -1)
         [[ -n "$v" && -n "$latest" ]] && { [[ "$v" != "$latest" ]] && echo "update" || echo "latest"; } > "$tmpdir/go") &

    command -v yazi &>/dev/null && \
        (v=$(yazi --version 2>/dev/null | awk '{print $2}' | head -1)
         _gh_release_check "$v" "sxyazi/yazi" > "$tmpdir/yazi") &

    command -v nvim &>/dev/null && \
        (v=$(nvim --version 2>/dev/null | head -1 | sed 's/NVIM v//' | awk '{print $1}')
         _gh_release_check "$v" "neovim/neovim" > "$tmpdir/neovim") &

    command -v lazygit &>/dev/null && \
        (v=$(lazygit --version 2>/dev/null | grep -o 'version=[^,]*' | head -1 | cut -d= -f2)
         _gh_release_check "$v" "jesseduffield/lazygit" > "$tmpdir/lazygit") &

    (dpkg -l peazip 2>/dev/null | grep -q '^ii') && \
        (v=$(dpkg -l peazip 2>/dev/null | awk '/^ii/{print $3}' | cut -d'-' -f1)
         _gh_release_check "$v" "peazip/PeaZip" > "$tmpdir/peazip") &

    wait
}

check_updates() {
    _UPDATE_TMPDIR=$(mktemp -d /tmp/kickstart-updates-XXXXXX)

    export -f _git_update_check _gh_release_check _run_update_checks
    export _UPDATE_TMPDIR

    gum spin --spinner dot --title "  Checking for updates..." -- \
        bash -c '_run_update_checks "$_UPDATE_TMPDIR"'

    local f key
    for f in "$_UPDATE_TMPDIR"/*; do
        [[ -f "$f" ]] || continue
        key=$(basename "$f")
        UPDATE_AVAIL["$key"]=$(cat "$f")
    done

    # Combine plugin sub-checks into a single "plugins" status
    local pa="${UPDATE_AVAIL[plugins_a]:-}" ps="${UPDATE_AVAIL[plugins_s]:-}"
    if [[ "$pa" == "update" || "$ps" == "update" ]]; then
        UPDATE_AVAIL[plugins]="update"
    elif [[ "$pa" == "latest" && "$ps" == "latest" ]]; then
        UPDATE_AVAIL[plugins]="latest"
    elif [[ -n "$pa" || -n "$ps" ]]; then
        UPDATE_AVAIL[plugins]="${pa:-$ps}"
    fi
    unset 'UPDATE_AVAIL[plugins_a]' 'UPDATE_AVAIL[plugins_s]'

    rm -rf "$_UPDATE_TMPDIR"
}

_get_update_status() {
    local script="$1" component="$2"
    case "$script" in
        shell/install.sh)    echo "${UPDATE_AVAIL[$component]:-}" ;;
        go/install.sh)       echo "${UPDATE_AVAIL[go]:-}" ;;
        yazi/install.sh)     echo "${UPDATE_AVAIL[yazi]:-}" ;;
        neovim/install.sh)
            local ns="${UPDATE_AVAIL[neovim]:-}" ls="${UPDATE_AVAIL[lazygit]:-}"
            if [[ "$ns" == "update" || "$ls" == "update" ]]; then echo "update"
            elif [[ -n "$ns" || -n "$ls" ]]; then echo "latest"
            fi ;;
        peazip/install.sh)   echo "${UPDATE_AVAIL[peazip]:-}" ;;
        *)                      echo "" ;;
    esac
}

get_labels() {
    for entry in "${ITEMS[@]}"; do
        local script="${entry%%|*}"
        local rest="${entry#*|}"
        local component="${rest%%|*}"
        local label="${rest#*|}"

        if [[ "$script" == "---" ]]; then
            if [[ -z "$label" ]]; then
                printf '\033[1G\033[2K\n'
            else
                printf '\033[1G\033[2K   %s%s%s\n' "$DIM" "$label" "$RST"
            fi
            continue
        fi

        local ustatus
        ustatus=$(_get_update_status "$script" "$component")

        case "$ustatus" in
            update) echo "$label ${BOLD_WHITE}[update available]${RST}" ;;
            latest) echo "$label [latest]" ;;
            *)
                if check_installed "$script" "$component"; then
                    echo "$label [installed]"
                else
                    echo "$label"
                fi ;;
        esac
    done
}

# ─── Selection parser ────────────────────────────────────────────────────────
# Turns selected labels into ordered (script, components) pairs

declare -A SCRIPT_COMPONENTS
SCRIPT_ORDER=()

parse_selection() {
    SCRIPT_COMPONENTS=()
    SCRIPT_ORDER=()

    while IFS= read -r label; do
        [[ -z "$label" ]] && continue
        # Strip \r, ANSI escape codes, and leading/trailing whitespace
        label="${label//$'\r'/}"
        label=$(echo "$label" | sed 's/\x1b\[[0-9;]*m//g')
        label="${label#"${label%%[![:space:]]*}"}"
        label="${label%"${label##*[![:space:]]}"}"
        [[ -z "$label" ]] && continue
        label="${label% \[installed\]}"
        label="${label% \[latest\]}"
        label="${label% \[update available\]}"

        for entry in "${ITEMS[@]}"; do
            local script="${entry%%|*}"
            [[ "$script" == "---" ]] && continue
            local e_label="${entry#*|}"
            e_label="${e_label#*|}"
            if [[ "$e_label" == "$label" ]]; then
                local rest="${entry#*|}"
                local component="${rest%%|*}"

                if [[ -z "${SCRIPT_COMPONENTS[$script]+_}" ]]; then
                    SCRIPT_ORDER+=("$script")
                    SCRIPT_COMPONENTS["$script"]=""
                fi

                if [[ -n "$component" ]]; then
                    SCRIPT_COMPONENTS["$script"]+="$component "
                fi
                break
            fi
        done
    done
}

# ─── User profile ────────────────────────────────────────────────────────────

collect_user_info() {
    local needs_info=false

    for script in "${SCRIPT_ORDER[@]}"; do
        case "$script" in
            shell/install.sh|docker/install.sh|apparmor/setup.sh)
                local comps="${SCRIPT_COMPONENTS[$script]}"
                if [[ "$script" == "shell/install.sh" && -n "$comps" && "$comps" != *git* ]]; then
                    continue
                fi
                needs_info=true
                ;;
        esac
    done

    if [[ "$needs_info" != true ]]; then
        return
    fi

    local existing_name existing_email
    existing_name=$(git config --global user.name 2>/dev/null || true)
    existing_email=$(git config --global user.email 2>/dev/null || true)

    echo ""
    gum style --foreground "$ACCENT" --bold "  Setup info"
    gum style --faint "  Used for git config. Leave blank to skip."
    echo ""

    export KICKSTART_USER_NAME
    KICKSTART_USER_NAME=$(gum input \
        --prompt "  Full name: " \
        --value "${existing_name:-}" \
        --placeholder "Dusan Panic" \
        --prompt.foreground "$ACCENT") || true

    export KICKSTART_USER_EMAIL
    KICKSTART_USER_EMAIL=$(gum input \
        --prompt "  Email:     " \
        --value "${existing_email:-}" \
        --placeholder "you@example.com" \
        --prompt.foreground "$ACCENT") || true

    if [[ -n "$KICKSTART_USER_NAME" && -n "$KICKSTART_USER_EMAIL" ]]; then
        echo ""
        gum style --foreground "$OK_COLOR" \
            "  → $KICKSTART_USER_NAME <$KICKSTART_USER_EMAIL>"
    fi
}

# ─── Run selected scripts ────────────────────────────────────────────────────

run_scripts() {
    local ran=0
    local failed=0
    local results=()

    for script in "${SCRIPT_ORDER[@]}"; do
        local components="${SCRIPT_COMPONENTS[$script]}"
        components="${components% }"   # trim trailing space

        local script_path="$MODULES_DIR/$script"
        [[ ! -x "$script_path" ]] && chmod +x "$script_path"

        local logname="${script//\//-}"
        local logfile="$LOG_DIR/${logname%.sh}-$(date +%Y%m%d-%H%M%S).log"

        echo ""
        gum style --foreground "$ACCENT2" --bold "━━━ Running: $script ━━━"
        if [[ -n "$components" ]]; then
            gum style --faint "  components: $components"
        fi
        echo ""

        local rc=0
        if [[ "$script" == "apparmor/setup.sh" ]]; then
            if [[ "$ACTION_FLAG" == "--uninstall" ]]; then
                sudo bash "$script_path" --uninstall 2>&1 | tee "$logfile" || rc=${PIPESTATUS[0]}
            else
                local webhook
                webhook=$(gum input \
                    --prompt "Slack webhook URL: " \
                    --placeholder "https://hooks.slack.com/services/T.../B.../xxx" \
                    --prompt.foreground "$ACCENT" < /dev/tty) || true
                if [[ -z "$webhook" ]]; then
                    echo "  Skipped (no webhook URL provided)"
                    results+=("$(gum style --foreground "$WARN_COLOR" "  ⊘ $script (skipped)")")
                    continue
                fi
                sudo bash "$script_path" "$webhook" 2>&1 | tee "$logfile" || rc=${PIPESTATUS[0]}
            fi
        else
            # shellcheck disable=SC2086
            bash "$script_path" $components $ACTION_FLAG 2>&1 | tee "$logfile" || rc=${PIPESTATUS[0]}
        fi

        if [[ $rc -eq 0 ]]; then
            ran=$((ran + 1))
            results+=("$(gum style --foreground "$OK_COLOR" "  ✓ $script")")
        else
            failed=$((failed + 1))
            results+=("$(gum style --foreground 196 "  ✗ $script (exit $rc)")")
        fi
    done

    echo ""
    local mode_label="Install"
    [[ "$ACTION_FLAG" == "--update" ]] && mode_label="Update"
    [[ "$ACTION_FLAG" == "--uninstall" ]] && mode_label="Uninstall"

    local summary
    summary=$(printf "%s\n\n%s\n\n%s\n\n%s" \
        "$(gum style --foreground "$ACCENT" --bold "  Results ($mode_label)")" \
        "$(printf '%s\n' "${results[@]}")" \
        "$(gum style --faint "  $ran succeeded, $failed failed")" \
        "$(gum style --faint "  Logs: $LOG_DIR/")")

    gum style \
        --border "$BORDER" \
        --border-foreground "$OK_COLOR" \
        --padding "1 2" \
        --margin "1 0" \
        "$summary"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    clear
    check_updates
    clear

    local menu_height=$(( $(tput lines) - 9 ))
    [[ "$menu_height" -lt 10 ]] && menu_height=10

    local chosen
    chosen=$(get_labels \
        | gum choose \
            --no-limit \
            --no-strip-ansi \
            --height "$menu_height" \
            --cursor-prefix "[▸] " \
            --selected-prefix "[✓] " \
            --unselected-prefix "[ ] " \
            --cursor.foreground "$ACCENT" \
            --selected.foreground "$ACCENT2" \
            --header $'  🚀 Kickstart — by Dusan Panic\n\n  SPACE = toggle  ·  ENTER = confirm\n\n   ── Optimizations ─────────────────────────────' \
            --header.foreground "$ACCENT") || true

    if [[ -z "$chosen" ]]; then
        gum style --foreground "$WARN_COLOR" "  Nothing selected. Exiting."
        exit 0
    fi

    parse_selection <<< "$chosen"

    local count=${#SCRIPT_ORDER[@]}

    echo ""
    local mode
    mode=$(gum choose \
        --header "Mode:" \
        --cursor.foreground "$ACCENT" \
        --selected.foreground "$ACCENT2" \
        "Install (skip already installed)" \
        "Update (refresh to latest versions)" \
        "Uninstall (remove / revert selected)") || true

    if [[ -z "$mode" ]]; then
        gum style --foreground "$WARN_COLOR" "  No mode selected. Exiting."
        exit 0
    fi

    ACTION_FLAG=""
    if [[ "$mode" == *Update* ]]; then
        ACTION_FLAG="--update"
    elif [[ "$mode" == *Uninstall* ]]; then
        ACTION_FLAG="--uninstall"
    fi

    if [[ "$ACTION_FLAG" != "--uninstall" ]]; then
        collect_user_info
    fi

    echo ""
    if gum confirm --prompt.foreground "$ACCENT" "Run $count script(s) in ${mode%% *} mode?"; then
        run_scripts
    else
        gum style --foreground "$WARN_COLOR" "  Cancelled."
    fi
}

main "$@"
