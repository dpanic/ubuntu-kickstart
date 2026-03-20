---
name: Dev tools install scripts
overview: Create install scripts for yazi, neovim+LazyVim, PeaZip, Docker, Java (Oracle JDK 25), Go, and shell tooling in the ubuntu-kickstart repo.
todos:
  - id: install-yazi
    content: Create install-yazi.sh -- download .deb from GitHub, integrate with existing fzf
    status: pending
  - id: install-neovim
    content: Create install-neovim.sh -- AppImage + LazyVim starter config + deps
    status: pending
  - id: install-peazip
    content: Create install-peazip.sh -- download .deb from GitHub releases
    status: pending
  - id: install-shell-tools
    content: Create install-shell-tools.sh -- oh-my-zsh, fzf (git), starship, direnv, zsh plugins
    status: pending
  - id: install-docker
    content: install-docker.sh already created -- Docker Engine + Compose + BuildX + daemon.json
    status: completed
  - id: install-java
    content: Create install-java.sh -- Oracle JDK 25 .deb + OpenJDK 21 fallback + update-alternatives
    status: pending
  - id: install-golang
    content: Create install-golang.sh -- Go tarball to /usr/local/go + env vars
    status: pending
  - id: configs
    content: Copy starship.toml into configs/ directory
    status: pending
  - id: update-readme
    content: Update README.md with all new scripts
    status: pending
  - id: commit-push
    content: Commit and push to GitHub
    status: pending
isProject: false
---

# Dev Tools Install Scripts

Add to the existing `dpanic/ubuntu-optimizer` repo. All scripts follow the same pattern: download latest from GitHub releases, no cargo/rust dependency, idempotent.

## Current setup captured

- **Shell**: zsh + oh-my-zsh (git clone from `ohmyzsh/ohmyzsh`)
- **Prompt**: starship v1.24.2 (binary in `/usr/local/bin/starship`, config in `~/.config/starship.toml`)
- **FZF**: v0.70.0, installed from git clone in `~/.fzf` (NOT apt)
- **direnv**: v2.32.1, installed from apt
- **zsh plugins**: `zsh-autosuggestions` + `zsh-syntax-highlighting` git cloned into `~/.oh-my-zsh/custom/plugins/`
- **NVM**: installed in `~/.nvm`
- **Java**: Oracle JDK 25.0.2 LTS (`jdk-25` .deb) at `/usr/lib/jvm/jdk-25.0.2-oracle-x64/`, OpenJDK 21 JRE as fallback, `update-alternatives` for switching
- **Go**: v1.26.1 tarball at `/usr/local/go/`, GOPATH=`~/go`, GOBIN=`$GOPATH/bin`
- **Docker**: Docker Engine + Compose + BuildX from official apt repo, user in docker group
- **No Neovim**, no Yazi, no file-roller/PeaZip currently installed

## Scripts to create

### 1. `install-yazi.sh` -- Yazi terminal file manager

- Download latest `.deb` from `sxyazi/yazi` GitHub releases (currently v26.1.22)
- Install via `dpkg -i` (no cargo needed)
- Add yazi shell wrapper to `~/.config/yazi/` for `cd`-on-exit behavior
- Configure yazi to use the existing `~/.fzf/bin/fzf` for fuzzy search via `~/.config/yazi/yazi.toml`
- **Key**: does NOT touch fzf -- yazi's deb has zero fzf dependency

### 2. `install-neovim.sh` -- Neovim + LazyVim

- Download latest AppImage from `neovim/neovim` GitHub releases (currently v0.11.6)
- Install to `/usr/local/bin/nvim`, make executable
- Clone LazyVim starter config to `~/.config/nvim/` (from `LazyVim/starter`)
- Install runtime dependencies: `ripgrep`, `fd-find`, `lazygit` (from apt or GitHub releases)
- Set `EDITOR=nvim` note for user's `.zshrc`

### 3. `install-peazip.sh` -- PeaZip archiver (Keka equivalent)

- Download latest GTK2 `.deb` from `peazip/PeaZip` GitHub releases (currently v10.9.0)
- Install via `dpkg -i`
- Handles 7z, rar, zip, tar.gz, brotli, zstd, and 200+ formats
- Integrates with Nautilus context menu automatically

### 4. `install-shell-tools.sh` -- oh-my-zsh, fzf, starship, direnv, plugins

Replicates the user's current shell setup from scratch on a new machine:

- Install zsh + set as default shell
- Clone oh-my-zsh from `ohmyzsh/ohmyzsh`
- Clone fzf from `junegunn/fzf` into `~/.fzf` and run install script (NOT apt)
- Install starship via official installer (`starship.rs`)
- Install direnv from apt
- Clone `zsh-autosuggestions` and `zsh-syntax-highlighting` into oh-my-zsh custom plugins
- Copy the starship.toml config
- Does NOT overwrite existing `.zshrc` -- prints instructions instead

### 5. `install-docker.sh` -- Docker Engine + Compose + BuildX

Already created. Installs from the official Docker apt repo:

- Add Docker GPG key + apt repo for Ubuntu
- Install `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`
- Add current user to `docker` group
- Deploy optimized `daemon.json` from `configs/docker-daemon.json` (16 concurrent downloads, JSON logging with rotation)
- Idempotent -- skips already-installed components

### 6. `install-java.sh` -- Oracle JDK 25 + OpenJDK 21

Replicates the user's current Java setup:

- Install OpenJDK 21 JRE from apt (`openjdk-21-jre`) as baseline/fallback
- Download Oracle JDK 25 `.deb` from Oracle's CDN (`jdk-25` package, currently 25.0.2 LTS)
- Install via `dpkg -i` to `/usr/lib/jvm/jdk-25.0.2-oracle-x64/`
- Configure `update-alternatives` so Oracle JDK 25 is the default `java`
- Set `JAVA_HOME=/usr/lib/jvm/jdk-25.0.2-oracle-x64` (prints `.zshrc` instructions)
- **Key**: uses Oracle's official `.deb` -- no manual tarball extraction

### 7. `install-golang.sh` -- Go (official tarball)

Replicates the user's current Go setup:

- Download latest Go tarball from `go.dev/dl/` (currently go1.26.1.linux-amd64.tar.gz)
- Extract to `/usr/local/go/` (removes previous version first)
- Create `~/go` directory structure (`bin/`, `pkg/`)
- Prints `.zshrc` instructions for environment vars:
  - `GOROOT=/usr/local/go`
  - `GOPATH=$HOME/go`
  - `GOBIN=$GOPATH/bin`
  - PATH additions for both `$GOROOT/bin` and `$GOPATH`
- Idempotent -- detects existing Go version before downloading

### 8. Include `starship.toml` config file

Copy the user's existing starship config into the repo so `install-shell-tools.sh` can deploy it.

## File structure

```
ubuntu-kickstart/
├── main.sh                    (TUI launcher)
├── README.md                  (update with new scripts)
├── scripts/
│   ├── gnome-optimize.sh      (existing)
│   ├── nautilus-optimize.sh   (existing)
│   ├── apparmor-setup.sh      (existing)
│   ├── install-shell-tools.sh (existing)
│   ├── install-terminal-tools.sh (existing)
│   ├── install-docker.sh      (existing)
│   ├── install-yazi.sh        (new)
│   ├── install-neovim.sh      (new)
│   ├── install-peazip.sh      (new)
│   ├── install-java.sh        (new)
│   └── install-golang.sh      (new)
└── configs/
    ├── starship.toml
    ├── zshrc.template
    ├── gitconfig.template
    ├── docker-daemon.json
    └── byobu/
```
