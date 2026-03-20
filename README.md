<p align="center">
  <img src="https://img.shields.io/badge/Ubuntu-24.04-E95420?style=flat-square&logo=ubuntu&logoColor=white" alt="Ubuntu 24.04" />
  <img src="https://img.shields.io/badge/macOS-Supported-000000?style=flat-square&logo=apple&logoColor=white" alt="macOS" />
  <img src="https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white" alt="Bash" />
  <img src="https://img.shields.io/badge/TUI-gum-FF69B4?style=flat-square" alt="gum TUI" />
</p>

# 🚀 Kickstart

> **One command to bootstrap a full dev environment on Ubuntu or macOS.**

by **Dusan Panic** \<dpanic@gmail.com\>

<p align="center">
  <img src="demo.gif" alt="Kickstart TUI demo" width="720" />
</p>

---

## ⚡ Quick Start

```bash
git clone https://github.com/dpanic/os-kickstart.git
cd os-kickstart
bash main.sh
```

`main.sh` launches an interactive TUI powered by [gum](https://github.com/charmbracelet/gum) where you pick what to install. It auto-installs `gum` if missing.

---

## ✨ Features

- 🎛️ **Interactive TUI** — multi-select menu with real-time update checks
- 🔄 **Install · Update · Uninstall** — fresh install, refresh to latest, or clean removal
- 📦 **Idempotent** — safe to re-run, skips what's already installed
- 🐧🍎 **Cross-platform** — Ubuntu 24.04 + macOS (Linux-only items auto-hidden on Mac)
- ⚡ **Parallel update checks** — checks GitHub/git for new versions in background

---

## 🖥️ What's Included

### 🔧 Optimizations *(Linux only)*

| Script | Description |
|--------|-------------|
| `gnome-optimize.sh` | Disable GNOME animations, sounds, hot corners, non-essential extensions |
| `nautilus-optimize.sh` | Restrict Tracker indexing, limit thumbnails, clear cache |
| `apparmor-setup.sh` | AppArmor learning mode + Slack reminder after 7 days |
| `kernel-optimize.sh` | Kernel sysctl tuning, file descriptor limits, sshd hardening, I/O scheduler, RAM-based autotune |

### 🐚 Shell Environment

| Component | Description |
|-----------|-------------|
| **zsh + oh-my-zsh** | Modern shell with plugin framework |
| **fzf** | Fuzzy finder (installed from Git) |
| **starship** | Cross-shell prompt with custom config |
| **direnv** | Per-directory environment variables |
| **zsh plugins** | autosuggestions + syntax-highlighting |
| **nvm** | Node.js version manager |
| **git config** | LFS, SSH-over-HTTPS, gitconfig template |

### 🖥️ Terminal & Dev Tools

| Tool | Description |
|------|-------------|
| **byobu + tmux** | Terminal multiplexer with mouse support *(Linux)* |
| **ncdu** | Interactive disk usage analyzer |
| **Yazi** | Blazing-fast terminal file manager |
| **Docker** | Engine + Compose + BuildX + daemon config |
| **Go** | Latest from go.dev tarball |
| **Neovim + LazyVim** | IDE-grade editor with ripgrep, fd, lazygit |

### 🌐 Desktop Apps *(Linux only)*

| App | Installation |
|-----|-------------|
| **Google Chrome** | `.deb` → APT repo |
| **Brave** | APT repository |
| **Signal Desktop** | APT repository |
| **PeaZip** | GitHub release `.deb` (200+ archive formats) |

---

## 🔄 Modes

After selecting items, choose a mode:

| Mode | Description |
|------|-------------|
| **Install** | Fresh install, skips already-installed items |
| **Update** | Refresh to latest versions (Git pull, re-download releases) |
| **Uninstall** | Remove installed tools, revert optimizations from backups |

```bash
bash main.sh
# → Select items → Choose mode → Confirm
```

The TUI shows real-time status for each tool:
- `[latest]` — already at newest version
- **`[update available]`** — newer version detected
- `[installed]` — installed, no update check available

---

## 📋 Requirements

| | Requirement |
|-|-------------|
| 🐧 | **Ubuntu 24.04** with GNOME 46 |
| 🍎 | **macOS** with Homebrew (auto-installed if missing) |
| 🌐 | Internet connection (downloads from GitHub, go.dev, APT repos) |
| 🔐 | `apparmor-setup.sh` needs `sudo` and a Slack webhook URL |

---

## 🛡️ Safety

- 📄 Existing `~/.zshrc` is never overwritten (instructions printed instead)
- 💾 Existing `~/.config/nvim` is backed up before LazyVim clone
- 🔒 Snap-related AppArmor profiles stay in enforce mode
- 🗑️ **Uninstall** restores system configs from `.bak-kickstart` backups created during install
- 🐳 Docker data (`/var/lib/docker`) is preserved on uninstall — remove manually if needed

---

## 🎬 Recording the Demo

The demo GIF is recorded with [VHS](https://github.com/charmbracelet/vhs):

```bash
vhs demo.tape
```

---

## 📄 License

MIT

---

<p align="center">
  <sub>Built with ❤️ and <a href="https://github.com/charmbracelet/gum">gum</a></sub>
</p>
