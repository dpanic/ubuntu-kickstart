#!/bin/bash
set -euo pipefail

# Install Docker Engine + Compose from official Docker repo
# Author: Dusan Panic <dpanic@gmail.com>
# Deploys optimized daemon.json (logging, concurrency)
# Safe to re-run -- idempotent

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

skip()    { echo -e "  ${GREEN}[SKIP]${NC} $1"; }
install() { echo -e "  ${YELLOW}[INSTALL]${NC} $1"; }

echo "=== Docker Setup ==="
echo ""

# [1/4] Docker Engine
echo "[1/4] docker engine..."
if command -v docker &>/dev/null; then
    skip "docker $(docker --version | grep -oP 'version \K[^,]+' || echo '?') already installed"
else
    install "installing Docker from official repo"

    sudo apt-get update -qq
    sudo apt-get install -y ca-certificates curl

    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt-get update -qq
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "  installed: $(docker --version)"
fi

# [2/4] Docker Compose (plugin)
echo "[2/4] docker compose..."
if docker compose version &>/dev/null; then
    skip "docker compose $(docker compose version --short 2>/dev/null || echo '?') already installed"
else
    install "docker compose should have been installed with docker-compose-plugin"
    sudo apt-get install -y docker-compose-plugin
fi

# [3/4] Add current user to docker group
echo "[3/4] docker group..."
if groups | grep -q docker; then
    skip "user $(whoami) already in docker group"
else
    install "adding $(whoami) to docker group"
    sudo usermod -aG docker "$(whoami)"
    echo "  NOTE: log out and back in for group change to take effect"
fi

# [4/4] Daemon config
echo "[4/4] daemon.json..."
DAEMON_CFG="/etc/docker/daemon.json"
if [[ -f "$DAEMON_CFG" ]]; then
    skip "$DAEMON_CFG already exists (not overwriting)"
    echo "  Review template: $REPO_DIR/configs/docker-daemon.json"
else
    install "deploying optimized daemon.json"
    sudo mkdir -p /etc/docker
    sudo cp "$REPO_DIR/configs/docker-daemon.json" "$DAEMON_CFG"
    sudo systemctl restart docker 2>/dev/null || true
fi

echo ""
echo "=== Docker setup complete ==="
echo ""
echo "Installed: Docker Engine, Docker Compose, BuildX"
echo ""
echo "Test with: docker run hello-world"
