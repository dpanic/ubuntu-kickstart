#!/bin/bash
set -euo pipefail

# Install Neovim (AppImage) + LazyVim starter config + dependencies
# Author: Dusan Panic <dpanic@gmail.com>
# Safe to re-run -- idempotent

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

skip()    { echo -e "  ${GREEN}[SKIP]${NC} $1"; }
install() { echo -e "  ${YELLOW}[INSTALL]${NC} $1"; }

echo "=== Neovim + LazyVim Setup ==="
echo ""

# [1/5] Neovim AppImage
echo "[1/5] neovim..."
if command -v nvim &>/dev/null; then
    skip "nvim $(nvim --version | head -1) already installed"
else
    install "downloading latest Neovim AppImage"
    APPIMAGE_URL=$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest \
        | grep '"browser_download_url"' \
        | grep 'nvim-linux-x86_64\.appimage"' \
        | head -1 \
        | cut -d'"' -f4)

    if [[ -z "$APPIMAGE_URL" ]]; then
        echo "  ERROR: could not find nvim.appimage in latest release"
        exit 1
    fi

    TMP_FILE=$(mktemp /tmp/nvim-XXXXXX.appimage)
    echo "  downloading: $APPIMAGE_URL"
    curl -fsSL -o "$TMP_FILE" "$APPIMAGE_URL"
    chmod +x "$TMP_FILE"
    sudo mv "$TMP_FILE" /usr/local/bin/nvim
    echo "  installed: $(nvim --version | head -1)"
fi

# [2/5] ripgrep + fd-find (apt)
echo "[2/5] ripgrep + fd-find..."
PKGS_TO_INSTALL=()
if command -v rg &>/dev/null; then
    skip "ripgrep $(rg --version | head -1) already installed"
else
    PKGS_TO_INSTALL+=(ripgrep)
fi

if command -v fdfind &>/dev/null || command -v fd &>/dev/null; then
    skip "fd-find already installed"
else
    PKGS_TO_INSTALL+=(fd-find)
fi

if [[ ${#PKGS_TO_INSTALL[@]} -gt 0 ]]; then
    install "installing ${PKGS_TO_INSTALL[*]} via apt"
    sudo apt-get update -qq
    sudo apt-get install -y "${PKGS_TO_INSTALL[@]}"
fi

# [3/5] lazygit
echo "[3/5] lazygit..."
if command -v lazygit &>/dev/null; then
    skip "lazygit $(lazygit --version 2>/dev/null | grep -oP 'version=\K[^,]+' || echo '?') already installed"
else
    install "downloading latest lazygit from GitHub"
    LAZYGIT_URL=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
        | grep '"browser_download_url"' \
        | grep 'Linux_x86_64.tar.gz"' \
        | head -1 \
        | cut -d'"' -f4)

    if [[ -z "$LAZYGIT_URL" ]]; then
        echo "  ERROR: could not find lazygit Linux_x86_64 tarball"
        exit 1
    fi

    TMP_DIR=$(mktemp -d /tmp/lazygit-XXXXXX)
    echo "  downloading: $LAZYGIT_URL"
    curl -fsSL "$LAZYGIT_URL" | tar -xz -C "$TMP_DIR"
    sudo mv "$TMP_DIR/lazygit" /usr/local/bin/lazygit
    sudo chmod +x /usr/local/bin/lazygit
    rm -rf "$TMP_DIR"
    echo "  installed: lazygit $(lazygit --version 2>/dev/null | grep -oP 'version=\K[^,]+' || echo '?')"
fi

# [4/5] LazyVim starter config
echo "[4/5] LazyVim config..."
NVIM_CONFIG="$HOME/.config/nvim"
if [[ -d "$NVIM_CONFIG" ]]; then
    if [[ -f "$NVIM_CONFIG/lazyvim.json" ]] || [[ -f "$NVIM_CONFIG/lazy-lock.json" ]]; then
        skip "LazyVim config already present at ~/.config/nvim/"
    else
        BACKUP="${NVIM_CONFIG}.bak.$(date +%s)"
        install "backing up existing nvim config to $BACKUP"
        mv "$NVIM_CONFIG" "$BACKUP"
        git clone --depth=1 https://github.com/LazyVim/starter "$NVIM_CONFIG"
        rm -rf "$NVIM_CONFIG/.git"
    fi
else
    install "cloning LazyVim starter to ~/.config/nvim/"
    git clone --depth=1 https://github.com/LazyVim/starter "$NVIM_CONFIG"
    rm -rf "$NVIM_CONFIG/.git"
fi

# [5/5] FUSE check (required for AppImage)
echo "[5/5] FUSE support..."
if command -v fusermount &>/dev/null || command -v fusermount3 &>/dev/null; then
    skip "FUSE already available"
else
    install "installing libfuse2 (required for AppImage)"
    sudo apt-get update -qq
    sudo apt-get install -y libfuse2
fi

echo ""
echo "=== Neovim + LazyVim setup complete ==="
echo ""
echo "Run 'nvim' to launch. LazyVim will auto-install plugins on first start."
echo ""
echo "Recommended: add to your .zshrc:"
echo '  export EDITOR=nvim'
