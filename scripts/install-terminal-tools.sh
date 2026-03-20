#!/bin/bash
set -euo pipefail

# Install terminal tools: byobu/tmux, duf, ncdu
# Author: Dusan Panic <dpanic@gmail.com>
# Safe to re-run -- idempotent

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

skip()    { echo -e "  ${GREEN}[SKIP]${NC} $1"; }
install() { echo -e "  ${YELLOW}[INSTALL]${NC} $1"; }

echo "=== Terminal Tools Setup ==="
echo ""

# [1/4] byobu + tmux
echo "[1/4] byobu + tmux..."
PKGS=()
if command -v byobu &>/dev/null; then
    skip "byobu already installed"
else
    PKGS+=(byobu)
fi

if command -v tmux &>/dev/null; then
    skip "tmux $(tmux -V) already installed"
else
    PKGS+=(tmux)
fi

if [[ ${#PKGS[@]} -gt 0 ]]; then
    install "installing ${PKGS[*]} via apt"
    sudo apt-get update -qq
    sudo apt-get install -y "${PKGS[@]}"
fi

# [2/4] byobu config
echo "[2/4] byobu config..."
BYOBU_DIR="$HOME/.byobu"
BYOBU_CONFIGS=(".tmux.conf" "backend" "color.tmux" "datetime.tmux" "keybindings" "keybindings.tmux" "status")

if [[ -d "$BYOBU_DIR" ]]; then
    local_changed=0
    for cfg in "${BYOBU_CONFIGS[@]}"; do
        src="$REPO_DIR/configs/byobu/$cfg"
        dst="$BYOBU_DIR/$cfg"
        if [[ ! -f "$src" ]]; then
            continue
        fi
        if [[ -f "$dst" ]] && diff -q "$src" "$dst" &>/dev/null; then
            continue
        fi
        if [[ -f "$dst" ]]; then
            install "updating $cfg (old backed up to ${cfg}.bak)"
            cp "$dst" "${dst}.bak"
        else
            install "copying $cfg"
        fi
        cp "$src" "$dst"
        local_changed=$((local_changed + 1))
    done
    if [[ $local_changed -eq 0 ]]; then
        skip "byobu config already up to date"
    fi
else
    install "creating ~/.byobu/ with configs"
    mkdir -p "$BYOBU_DIR"
    for cfg in "${BYOBU_CONFIGS[@]}"; do
        src="$REPO_DIR/configs/byobu/$cfg"
        [[ -f "$src" ]] && cp "$src" "$BYOBU_DIR/$cfg"
    done
fi

# Set tmux as byobu backend
if [[ -f "$BYOBU_DIR/backend" ]] && grep -q "tmux" "$BYOBU_DIR/backend"; then
    skip "byobu backend already set to tmux"
else
    install "setting byobu backend to tmux"
    echo "BYOBU_BACKEND=tmux" > "$BYOBU_DIR/backend"
fi

# [3/4] duf
echo "[3/4] duf..."
if command -v duf &>/dev/null; then
    skip "duf $(duf --version 2>/dev/null | head -1 || echo '?') already installed"
else
    install "downloading latest duf from GitHub"
    DEB_URL=$(curl -fsSL https://api.github.com/repos/muesli/duf/releases/latest \
        | grep '"browser_download_url"' \
        | grep 'linux_amd64\.deb"' \
        | head -1 \
        | cut -d'"' -f4)

    if [[ -z "$DEB_URL" ]]; then
        install "duf not found on GitHub, trying apt"
        sudo apt-get update -qq
        sudo apt-get install -y duf
    else
        TMP_DEB=$(mktemp /tmp/duf-XXXXXX.deb)
        echo "  downloading: $DEB_URL"
        curl -fsSL -o "$TMP_DEB" "$DEB_URL"
        sudo dpkg -i "$TMP_DEB" || sudo apt-get install -f -y
        rm -f "$TMP_DEB"
    fi
    echo "  installed: duf $(duf --version 2>/dev/null | head -1 || echo '?')"
fi

# [4/4] ncdu
echo "[4/4] ncdu..."
if command -v ncdu &>/dev/null; then
    skip "ncdu $(ncdu --version 2>/dev/null | head -1 || echo '?') already installed"
else
    install "installing ncdu via apt"
    sudo apt-get update -qq
    sudo apt-get install -y ncdu
fi

echo ""
echo "=== Terminal tools setup complete ==="
echo ""
echo "Installed: byobu, tmux, duf, ncdu"
echo ""
echo "Quick start:"
echo "  byobu         -- launch terminal multiplexer"
echo "  duf            -- disk usage overview"
echo "  ncdu           -- interactive disk usage analyzer"
