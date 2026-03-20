#!/bin/bash
set -euo pipefail

# Install PeaZip archiver from GitHub releases (.deb)
# Author: Dusan Panic <dpanic@gmail.com>
# Handles 200+ archive formats (7z, rar, zip, tar, zstd, brotli, etc.)
# Safe to re-run -- idempotent

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

skip()    { echo -e "  ${GREEN}[SKIP]${NC} $1"; }
install() { echo -e "  ${YELLOW}[INSTALL]${NC} $1"; }

echo "=== PeaZip Archiver ==="
echo ""

# [1/2] Install PeaZip
echo "[1/2] peazip..."
if dpkg -l peazip &>/dev/null 2>&1 && dpkg -l peazip | grep -q '^ii'; then
    PEAZIP_VER=$(dpkg -l peazip | awk '/^ii/{print $3}')
    skip "peazip ${PEAZIP_VER} already installed"
else
    install "fetching latest PeaZip GTK2 .deb from GitHub"
    DEB_URL=$(curl -fsSL https://api.github.com/repos/peazip/PeaZip/releases/latest \
        | grep '"browser_download_url"' \
        | grep -i 'gtk2.*amd64\.deb\|amd64.*gtk2.*\.deb' \
        | head -1 \
        | cut -d'"' -f4)

    if [[ -z "$DEB_URL" ]]; then
        DEB_URL=$(curl -fsSL https://api.github.com/repos/peazip/PeaZip/releases/latest \
            | grep '"browser_download_url"' \
            | grep -i '\.deb' \
            | grep -iv 'qt' \
            | head -1 \
            | cut -d'"' -f4)
    fi

    if [[ -z "$DEB_URL" ]]; then
        echo "  ERROR: could not find PeaZip .deb in latest release"
        echo "  Check: https://github.com/peazip/PeaZip/releases"
        exit 1
    fi

    TMP_DEB=$(mktemp /tmp/peazip-XXXXXX.deb)
    echo "  downloading: $DEB_URL"
    curl -fsSL -o "$TMP_DEB" "$DEB_URL"
    sudo dpkg -i "$TMP_DEB" || sudo apt-get install -f -y
    rm -f "$TMP_DEB"

    PEAZIP_VER=$(dpkg -l peazip 2>/dev/null | awk '/^ii/{print $3}' || echo '?')
    echo "  installed: peazip ${PEAZIP_VER}"
fi

# [2/2] Verify
echo "[2/2] verification..."
if command -v peazip &>/dev/null; then
    skip "peazip binary found at $(command -v peazip)"
else
    echo "  peazip installed via dpkg but not in PATH"
    echo "  try: /usr/bin/peazip or check the .desktop entry"
fi

echo ""
echo "=== PeaZip installation complete ==="
echo ""
echo "PeaZip integrates with Nautilus context menu automatically."
echo "Supported formats: 7z, rar, zip, tar.gz, zstd, brotli, and 200+ more."
