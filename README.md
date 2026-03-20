# Ubuntu Kickstart

by **Dusan Panic** \<dpanic@gmail.com\>

Optimize Ubuntu 24.04 (GNOME 46) and bootstrap a full dev environment in one shot.

## Quick start

```bash
git clone https://github.com/dpanic/ubuntu-kickstart.git
cd ubuntu-kickstart
./main.sh
```

`main.sh` launches an interactive TUI (powered by [gum](https://github.com/charmbracelet/gum)) where you pick which scripts to run. It auto-installs `gum` if missing.

## Scripts

### System Optimization

#### `gnome-optimize.sh`

Disables GNOME animations, event sounds, hot corners, and non-essential shell extensions.

```bash
./gnome-optimize.sh
```

Edit the `KEEP_EXTENSIONS` array at the top to customize which extensions to keep.

#### `nautilus-optimize.sh`

Restricts Tracker file indexing (removes `~/Downloads` and recursive `$HOME` from index), limits thumbnail generation to local files under 1MB, and clears the thumbnail cache.

```bash
./nautilus-optimize.sh
```

#### `apparmor-setup.sh`

Installs AppArmor utilities, switches all profiles to complain (learning) mode, and sets a systemd timer to send a Slack reminder after 7 days. Does **not** auto-enforce -- you review with `aa-logprof` and enforce manually.

```bash
sudo ./apparmor-setup.sh https://hooks.slack.com/services/T.../B.../xxx
```

### Dev Tools

#### `install-shell-tools.sh`

Sets up a complete zsh environment: oh-my-zsh, fzf (from git), starship prompt, direnv, zsh-autosuggestions, zsh-syntax-highlighting, nvm, and git config (LFS, large repo tuning, SSH-over-HTTPS). Deploys starship.toml, gitconfig, and a reference .zshrc template.

```bash
./install-shell-tools.sh
```

Every step is idempotent -- already-installed tools are detected and skipped.

#### `install-terminal-tools.sh`

Installs [byobu](https://www.byobu.org/) terminal multiplexer (with tmux backend), [duf](https://github.com/muesli/duf) disk usage utility, and [ncdu](https://dev.yorhel.nl/ncdu) interactive disk analyzer. Deploys byobu config with mouse support, 10k scroll history, and custom status bar.

```bash
./scripts/install-terminal-tools.sh
```

#### `install-docker.sh`

Installs [Docker Engine](https://docs.docker.com/engine/install/ubuntu/) + Compose + BuildX from the official Docker apt repo. Adds current user to the docker group and deploys an optimized `daemon.json` (16 concurrent downloads, JSON logging with rotation).

```bash
sudo ./scripts/install-docker.sh
```

#### `install-yazi.sh`

Installs [Yazi](https://github.com/sxyazi/yazi) terminal file manager from the latest GitHub release (.deb). Creates a cd-on-exit shell wrapper.

```bash
./install-yazi.sh
```

#### `install-neovim.sh`

Installs Neovim (AppImage) + [LazyVim](https://www.lazyvim.org/) starter config + dependencies (ripgrep, fd-find, lazygit). Backs up existing nvim config if present.

```bash
./install-neovim.sh
```

#### `install-peazip.sh`

Installs [PeaZip](https://peazip.github.io/) archiver from the latest GitHub release (.deb). Handles 200+ archive formats and integrates with Nautilus context menu.

```bash
./install-peazip.sh
```

## File structure

```
ubuntu-optimizer/
├── main.sh                           # TUI launcher (gum)
├── scripts/
│   ├── gnome-optimize.sh             # GNOME desktop optimization
│   ├── nautilus-optimize.sh          # Nautilus / Tracker optimization
│   ├── apparmor-setup.sh             # AppArmor learning mode setup
│   ├── install-shell-tools.sh        # zsh + oh-my-zsh + fzf + starship + direnv + nvm + git
│   ├── install-terminal-tools.sh     # byobu + tmux + duf + ncdu
│   ├── install-docker.sh             # Docker Engine + Compose + BuildX
│   ├── install-yazi.sh               # Yazi terminal file manager
│   ├── install-neovim.sh             # Neovim + LazyVim + deps
│   └── install-peazip.sh             # PeaZip archiver
├── configs/
│   ├── starship.toml                 # Starship prompt config
│   ├── zshrc.template                # Reference .zshrc with plugins & integrations
│   ├── gitconfig.template            # Git config (LFS, large repo tuning, SSH-over-HTTPS)
│   ├── docker-daemon.json            # Docker daemon config (logging, concurrency)
│   └── byobu/                        # Byobu/tmux config (mouse, keybindings, status bar)
└── README.md
```

## Requirements

- Ubuntu 24.04 with GNOME 46
- `apparmor-setup.sh` requires root (sudo) and a Slack webhook URL
- Install scripts download from GitHub -- internet connection required

## What stays untouched

- No packages are removed, only settings are changed
- Existing `~/.zshrc` is never overwritten (instructions printed instead)
- Existing `~/.config/nvim` is backed up before LazyVim clone
- Snap-related AppArmor profiles stay in enforce mode (kernel-level)
