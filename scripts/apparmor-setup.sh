#!/bin/bash
set -euo pipefail

# AppArmor Learning Mode Setup
# Author: Dusan Panic <dpanic@gmail.com>
# Installs utils, switches all profiles to complain mode,
# sets up a systemd timer to send a Slack reminder after 7 days.
# Does NOT auto-enforce -- you review and enforce manually.
#
# Usage:
#   sudo ./apparmor-setup.sh <slack-webhook-url>
#
# Example:
#   sudo ./apparmor-setup.sh https://hooks.slack.com/services/T.../B.../xxx

if [[ $EUID -ne 0 ]]; then
    echo "Error: this script must be run as root (sudo)."
    exit 1
fi

WEBHOOK_URL="${1:-}"
LEARNING_DAYS=7
SCRIPT_PATH="/usr/local/bin/apparmor-remind.sh"
SERVICE_PATH="/etc/systemd/system/apparmor-enforce.service"
TIMER_PATH="/etc/systemd/system/apparmor-enforce.timer"

if [[ -z "$WEBHOOK_URL" ]]; then
    echo "Error: Slack webhook URL is required."
    echo "Usage: sudo $0 <webhook-url>"
    exit 1
fi

echo "=== AppArmor Learning Mode Setup ==="
echo "  Learning period: ${LEARNING_DAYS} days"
echo "  Webhook: ${WEBHOOK_URL:0:50}..."
echo ""

echo "[1/5] Installing apparmor-utils and extra profiles..."
apt-get install -y apparmor-utils apparmor-profiles apparmor-profiles-extra
echo "  done."

echo "[2/5] Switching all profiles to complain (learning) mode..."
aa-complain /etc/apparmor.d/* 2>&1 | tail -5
echo ""
COMPLAIN_COUNT=$(aa-status 2>/dev/null | grep -c "complain" || echo "?")
ENFORCE_COUNT=$(aa-status 2>/dev/null | grep -c "enforce" || echo "?")
echo "  Profiles in complain mode: $COMPLAIN_COUNT"
echo "  Profiles still in enforce: $ENFORCE_COUNT (snap-confine, kernel-level)"
echo "  done."

echo "[3/5] Creating Slack reminder script at $SCRIPT_PATH..."
cat > "$SCRIPT_PATH" << 'REMIND_SCRIPT'
#!/bin/bash
WEBHOOK_URL="__WEBHOOK_URL__"
HOSTNAME=$(hostname)
PROFILES_COUNT=$(aa-status 2>/dev/null | grep -c "complain" || echo "?")
LOG_VIOLATIONS=$(journalctl -t kernel --since "__LEARNING_DAYS__ days ago" 2>/dev/null | grep -c 'apparmor="ALLOWED"' || echo "0")

curl -s -X POST "$WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d @- <<EOFMSG
{
  "username": "AppArmor Bot",
  "icon_emoji": ":shield:",
  "text": ":shield: *AppArmor: __LEARNING_DAYS__-dnevni learning period je zavrsen*\n\n*Host:* \`${HOSTNAME}\`\n*Profila u complain modu:* ${PROFILES_COUNT}\n*Zabelezenih dozvoljenih krsenja:* ${LOG_VIOLATIONS}\n\n---\n\n*Sta se desavalo poslednjih __LEARNING_DAYS__ dana?*\nSvi AppArmor profili su bili u *complain (learning) modu*. To znaci da AppArmor NIJE blokirao nista, ali je BELEZIO svako ponasanje aplikacija koje bi inace bilo blokirano. Ovo sluzi da se nauci sta je normalan rad sistema.\n\n*Sta sad treba da uradis:*\n\n1. Pregledaj naucena pravila interaktivno:\n\`\`\`\nsudo aa-logprof\n\`\`\`\nOvo ti pokazuje svako krsenje i pita te da li da ga dozvolis (Allow), zabrani (Deny), ili ignorise.\n\n2. Kada zavrsis pregled, prebaci sve profile u enforce mod:\n\`\`\`\nsudo aa-enforce /etc/apparmor.d/*\n\`\`\`\n\n3. Proveri status:\n\`\`\`\nsudo aa-status | head -20\n\`\`\`\n\n*Ako nisi spreman* -- nema zurbe. Profili ostaju u complain modu dok ih rucno ne prebacis. Nista se nece pokvariti.\n\n---\n_Ovaj podsetnik je automatski poslan sa systemd timera. Timer je sada onemogucen._"
}
EOFMSG

logger "AppArmor: learning period reminder sent to Slack."
systemctl disable apparmor-enforce.timer 2>/dev/null || true
REMIND_SCRIPT

sed -i "s|__WEBHOOK_URL__|${WEBHOOK_URL}|g" "$SCRIPT_PATH"
sed -i "s|__LEARNING_DAYS__|${LEARNING_DAYS}|g" "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"
echo "  done."

echo "[4/5] Creating systemd timer (fires in ${LEARNING_DAYS} days)..."
cat > "$SERVICE_PATH" << EOF
[Unit]
Description=AppArmor learning reminder (Slack notification)

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
EOF

cat > "$TIMER_PATH" << EOF
[Unit]
Description=Trigger AppArmor reminder after ${LEARNING_DAYS} days

[Timer]
OnActiveSec=${LEARNING_DAYS}d
AccuracySec=1h

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now apparmor-enforce.timer
echo "  done."

echo "[5/5] Sending test message to Slack..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "{\"username\": \"AppArmor Bot\", \"icon_emoji\": \":shield:\", \"text\": \":white_check_mark: *AppArmor learning mode aktiviran na \`$(hostname)\`.*\nPodsetnik stize za ${LEARNING_DAYS} dana.\"}")

if [[ "$HTTP_CODE" == "200" ]]; then
    echo "  webhook test: OK (HTTP $HTTP_CODE)"
else
    echo "  webhook test: FAILED (HTTP $HTTP_CODE) -- check the URL"
fi
echo "  done."

echo ""
echo "=== AppArmor setup complete ==="
echo ""
echo "Timer fires on: $(date -d "+${LEARNING_DAYS} days" '+%A %Y-%m-%d %H:%M')"
echo ""
echo "After receiving the Slack reminder, run:"
echo "  sudo aa-logprof          # review learned rules interactively"
echo "  sudo aa-enforce /etc/apparmor.d/*   # switch to enforce mode"
echo "  sudo aa-status | head -20           # verify"
