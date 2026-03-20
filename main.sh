#!/bin/bash
set -euo pipefail

# Ubuntu Kickstart
# Author: Dusan Panic <dpanic@gmail.com>
# https://github.com/dpanic/ubuntu-kickstart
#
# Interactive TUI launcher using Charmbracelet's gum

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$REPO_DIR/scripts"
LOG_DIR="$REPO_DIR/logs"
mkdir -p "$LOG_DIR"

# ─── Bootstrap gum ───────────────────────────────────────────────────────────

ensure_gum() {
    if command -v gum &>/dev/null; then
        return
    fi

    echo "gum not found -- installing Charmbracelet gum..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key \
        | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
        | sudo tee /etc/apt/sources.list.d/charm.list >/dev/null
    sudo apt-get update -qq
    sudo apt-get install -y gum
    echo ""
}

ensure_gum

# ─── Colors & styles ─────────────────────────────────────────────────────────

ACCENT="212"       # pink
ACCENT2="39"       # cyan
BORDER="rounded"
OK_COLOR="78"      # green
WARN_COLOR="208"   # orange

# ─── Banner ──────────────────────────────────────────────────────────────────

show_banner() {
    local title subtitle author banner

    title=$(gum style \
        --foreground "$ACCENT" \
        --bold \
        "  Ubuntu Kickstart")

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

# ─── Script registry ─────────────────────────────────────────────────────────
# Format: "script_filename|display_label"

SCRIPTS=(
    "gnome-optimize.sh|GNOME Optimize -- disable animations, sounds, hot corners"
    "nautilus-optimize.sh|Nautilus Optimize -- restrict Tracker, limit thumbnails"
    "apparmor-setup.sh|AppArmor Setup -- learning mode with Slack reminder"
    "install-shell-tools.sh|Shell Tools -- zsh, oh-my-zsh, fzf, starship, direnv, plugins, nvm, git"
    "install-terminal-tools.sh|Terminal Tools -- byobu, tmux, duf, ncdu"
    "install-docker.sh|Docker -- engine, compose, buildx, daemon config"
    "install-yazi.sh|Yazi -- terminal file manager"
    "install-neovim.sh|Neovim + LazyVim -- editor with IDE features"
    "install-peazip.sh|PeaZip -- archive manager (200+ formats)"
)

get_labels() {
    for entry in "${SCRIPTS[@]}"; do
        echo "${entry#*|}"
    done
}

label_to_script() {
    local label="$1"
    for entry in "${SCRIPTS[@]}"; do
        if [[ "${entry#*|}" == "$label" ]]; then
            echo "${entry%%|*}"
            return
        fi
    done
}

# ─── User profile ─────────────────────────────────────────────────────────────

collect_user_info() {
    local needs_info=false

    for label in "$@"; do
        case "$label" in
            *Shell\ Tools*|*Docker*|*AppArmor*) needs_info=true ;;
        esac
    done

    if [[ "$needs_info" != true ]]; then
        return
    fi

    # Try to pre-fill from existing git config
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

    while IFS= read -r label; do
        [[ -z "$label" ]] && continue

        local script
        script=$(label_to_script "$label")
        [[ -z "${script:-}" ]] && continue

        local script_path="$SCRIPTS_DIR/$script"
        [[ ! -x "$script_path" ]] && chmod +x "$script_path"

        local logfile="$LOG_DIR/${script%.sh}-$(date +%Y%m%d-%H%M%S).log"

        echo ""
        gum style --foreground "$ACCENT2" --bold "━━━ Running: $script ━━━"
        echo ""

        local rc=0
        if [[ "$script" == "apparmor-setup.sh" ]]; then
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
        else
            bash "$script_path" 2>&1 | tee "$logfile" || rc=${PIPESTATUS[0]}
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
    local summary
    summary=$(printf "%s\n\n%s\n\n%s\n\n%s" \
        "$(gum style --foreground "$ACCENT" --bold '  Results')" \
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
    show_banner

    gum style --foreground "$ACCENT2" --faint \
        "  ┌ System: items 1-3    └ Dev Tools: items 4-9"
    echo ""

    local chosen
    chosen=$(get_labels \
        | gum choose \
            --no-limit \
            --height 12 \
            --cursor-prefix "○ " \
            --selected-prefix "◉ " \
            --unselected-prefix "○ " \
            --cursor.foreground "$ACCENT" \
            --selected.foreground "$ACCENT2" \
            --header "SPACE = toggle, ENTER = confirm:" \
            --header.foreground "$ACCENT") || true

    if [[ -z "$chosen" ]]; then
        gum style --foreground "$WARN_COLOR" "  Nothing selected. Exiting."
        exit 0
    fi

    local count
    count=$(echo "$chosen" | wc -l)

    collect_user_info $chosen

    echo ""
    if gum confirm --prompt.foreground "$ACCENT" "Run $count selected script(s)?"; then
        echo "$chosen" | run_scripts
    else
        gum style --foreground "$WARN_COLOR" "  Cancelled."
    fi
}

main "$@"
