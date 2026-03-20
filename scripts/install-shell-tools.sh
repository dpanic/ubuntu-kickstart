#!/bin/bash
set -euo pipefail

# Install shell tooling: zsh, oh-my-zsh, fzf, starship, direnv, plugins, nvm
# Author: Dusan Panic <dpanic@gmail.com>
# Replicates a full zsh dev environment from scratch
# Safe to re-run -- idempotent (skips already-installed components)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

skip()    { echo -e "  ${GREEN}[SKIP]${NC} $1"; }
install() { echo -e "  ${YELLOW}[INSTALL]${NC} $1"; }

echo "=== Shell Tools Setup ==="
echo ""

# [1/8] zsh
echo "[1/8] zsh..."
if command -v zsh &>/dev/null; then
    skip "zsh $(zsh --version | head -1) already installed"
else
    install "installing zsh"
    sudo apt-get update -qq
    sudo apt-get install -y zsh
fi

if [[ "$(basename "$SHELL")" != "zsh" ]]; then
    install "setting zsh as default shell (requires password)"
    chsh -s "$(command -v zsh)"
else
    skip "zsh is already the default shell"
fi

# [2/8] oh-my-zsh
echo "[2/8] oh-my-zsh..."
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    skip "oh-my-zsh already installed at ~/.oh-my-zsh"
else
    install "cloning oh-my-zsh"
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi

# [3/8] fzf (from git, NOT apt)
echo "[3/8] fzf..."
if [[ -d "$HOME/.fzf" ]]; then
    skip "fzf already installed at ~/.fzf"
else
    install "cloning fzf from git"
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --all --no-bash --no-fish
fi

# [4/8] starship prompt
echo "[4/8] starship..."
if command -v starship &>/dev/null; then
    skip "starship $(starship --version | head -1) already installed"
else
    install "installing starship"
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
fi

# [5/8] direnv
echo "[5/8] direnv..."
if command -v direnv &>/dev/null; then
    skip "direnv $(direnv version) already installed"
else
    install "installing direnv via apt"
    sudo apt-get update -qq
    sudo apt-get install -y direnv
fi

# [6/8] zsh plugins (custom)
echo "[6/8] zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    skip "zsh-autosuggestions already installed"
else
    install "cloning zsh-autosuggestions"
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    skip "zsh-syntax-highlighting already installed"
else
    install "cloning zsh-syntax-highlighting"
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# [7/8] nvm
echo "[7/8] nvm..."
if [[ -d "$HOME/.nvm" ]]; then
    skip "nvm already installed at ~/.nvm"
else
    install "installing nvm"
    LATEST_NVM=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${LATEST_NVM}/install.sh" | PROFILE=/dev/null bash
fi

# [8/9] git config
echo "[8/9] git config..."
if [[ -f "$HOME/.gitconfig" ]]; then
    skip "~/.gitconfig already exists (not overwriting)"
    echo "  Review template: $REPO_DIR/configs/gitconfig.template"
else
    install "copying gitconfig.template -> ~/.gitconfig"
    cp "$REPO_DIR/configs/gitconfig.template" "$HOME/.gitconfig"
fi

if [[ -n "${KICKSTART_USER_NAME:-}" ]]; then
    git config --global user.name "$KICKSTART_USER_NAME"
    echo "  git user.name = $KICKSTART_USER_NAME"
fi
if [[ -n "${KICKSTART_USER_EMAIL:-}" ]]; then
    git config --global user.email "$KICKSTART_USER_EMAIL"
    echo "  git user.email = $KICKSTART_USER_EMAIL"
fi
if [[ -z "${KICKSTART_USER_NAME:-}" && -z "${KICKSTART_USER_EMAIL:-}" ]]; then
    current_name=$(git config --global user.name 2>/dev/null || true)
    current_email=$(git config --global user.email 2>/dev/null || true)
    if [[ "$current_name" == "CHANGEME" || -z "$current_name" ]]; then
        echo ""
        echo "  IMPORTANT: set your git identity:"
        echo '    git config --global user.name "Your Name"'
        echo '    git config --global user.email "your@email.com"'
    fi
fi

# install git-lfs if missing
if command -v git-lfs &>/dev/null; then
    skip "git-lfs already installed"
else
    install "installing git-lfs via apt"
    sudo apt-get update -qq
    sudo apt-get install -y git-lfs
    git lfs install
fi

# [9/9] config files
echo "[9/9] config files..."
mkdir -p "$HOME/.config"

if [[ -f "$HOME/.config/starship.toml" ]]; then
    skip "~/.config/starship.toml already exists (not overwriting)"
else
    install "copying starship.toml"
    cp "$REPO_DIR/configs/starship.toml" "$HOME/.config/starship.toml"
fi

if [[ -f "$HOME/.zshrc" ]]; then
    skip "~/.zshrc already exists (not overwriting)"
    echo ""
    echo "  To see what the template includes, run:"
    echo "    diff ~/.zshrc $REPO_DIR/configs/zshrc.template"
    echo ""
    echo "  Key lines to ensure are in your .zshrc:"
    echo "    plugins=(fzf git zsh-autosuggestions zsh-syntax-highlighting)"
    echo '    eval "$(starship init zsh)"'
    echo '    eval "$(direnv hook zsh)"'
    echo '    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'
else
    install "copying zshrc.template -> ~/.zshrc"
    cp "$REPO_DIR/configs/zshrc.template" "$HOME/.zshrc"
fi

echo ""
echo "=== Shell tools setup complete ==="
echo ""
echo "Installed: zsh, oh-my-zsh, fzf, starship, direnv, zsh plugins, nvm, git config"
echo "Start a new terminal or run: exec zsh"
