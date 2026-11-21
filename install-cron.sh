#!/bin/bash
# install-cron.sh
# Installation aller CRON-Jobs für Dev-Affiliations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="/usr/local/bin/dev-aff"
LOG_DIR="/var/log/dev-aff"
CRON_USER="${CRON_USER:-devops}"

echo "╔═════════════════════════════════════════════════════════╗"
echo "║  Dev-Affiliations CRON Installation                    ║"
echo "╚═════════════════════════════════════════════════════════╝"
echo ""

# 1. Verzeichnisse erstellen
echo "📁 Erstelle Verzeichnisse..."
sudo mkdir -p "$BIN_DIR"
sudo mkdir -p "$LOG_DIR"
sudo mkdir -p "/opt/dev-aff-backups"
echo "✓ Verzeichnisse erstellt"
echo ""

# 2. Scripts kopieren
echo "📋 Kopiere Scripts..."
sudo cp "$SCRIPT_DIR/cron-fetch-validate.sh" "$BIN_DIR/fetch-and-validate.sh"
sudo cp "$SCRIPT_DIR/cron-cleanup.sh" "$BIN_DIR/cleanup-duplicates.sh"
sudo cp "$SCRIPT_DIR/cron-generate-stats.sh" "$BIN_DIR/generate-stats.sh"
sudo cp "$SCRIPT_DIR/cron-sync-tools.sh" "$BIN_DIR/sync-tools.sh"
sudo cp "$SCRIPT_DIR/cron-quality-check.sh" "$BIN_DIR/quality-check.sh"
sudo cp "$SCRIPT_DIR/cron-archive.sh" "$BIN_DIR/archive-cleanup.sh"
echo "✓ Scripts kopiert"
echo ""

# 3. Scripts ausführbar machen
echo "🔐 Setze Ausführungsrechte..."
sudo chmod +x "$BIN_DIR"/*.sh
sudo chown -R "$CRON_USER:$CRON_USER" "$BIN_DIR"
sudo chown -R "$CRON_USER:$CRON_USER" "$LOG_DIR"
echo "✓ Ausführungsrechte gesetzt"
echo ""

# 4. Crontab installieren
echo "⏰ Installiere CRON-Jobs..."
cat > /tmp/dev-aff-cron.txt << 'EOF'
# Dev-Affiliations Daily CRON Jobs
# ================================

# 00:00 - Fetch & Validate
0 0 * * * /usr/local/bin/dev-aff/fetch-and-validate.sh >> /var/log/dev-aff/fetch.log 2>&1

# 04:00 - Cleanup Duplicates
0 4 * * * /usr/local/bin/dev-aff/cleanup-duplicates.sh >> /var/log/dev-aff/cleanup.log 2>&1

# 08:00 - Generate Stats
0 8 * * * /usr/local/bin/dev-aff/generate-stats.sh >> /var/log/dev-aff/stats.log 2>&1

# 12:00 - Sync Tools
0 12 * * * /usr/local/bin/dev-aff/sync-tools.sh >> /var/log/dev-aff/sync.log 2>&1

# 16:00 - Quality Check
0 16 * * * /usr/local/bin/dev-aff/quality-check.sh >> /var/log/dev-aff/quality.log 2>&1

# 20:00 - Archive & Cleanup
0 20 * * * /usr/local/bin/dev-aff/archive-cleanup.sh >> /var/log/dev-aff/archive.log 2>&1

# 23:00 - Daily Verification
0 23 * * * /usr/local/bin/dev-aff/cron-dashboard.sh >> /var/log/dev-aff/verification.log 2>&1

EOF

sudo -u "$CRON_USER" crontab -l 2>/dev/null | cat - /tmp/dev-aff-cron.txt | sudo -u "$CRON_USER" crontab - || \
    echo "⚠ Crontab konnte nicht installiert werden"

rm /tmp/dev-aff-cron.txt
echo "✓ CRON-Jobs installiert"
echo ""

# 5. Log-Rotation konfigurieren
echo "📜 Konfiguriere Log-Rotation..."
sudo tee /etc/logrotate.d/dev-affiliations > /dev/null << 'EOF'
/var/log/dev-aff/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 devops devops
    sharedscripts
    postrotate
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
EOF
echo "✓ Log-Rotation konfiguriert"
echo ""

# 6. Verifikation
echo "✅ Installation abgeschlossen!"
echo ""
echo "Verifikation:"
echo "─────────────────────────────────────────────────────"
echo "CRON-Jobs für $CRON_USER:"
sudo -u "$CRON_USER" crontab -l | grep -v "^#" | grep -v "^$" | wc -l | xargs echo "  Installierte Jobs:"
echo ""
echo "Verzeichnisse:"
echo "  Bin: $BIN_DIR"
echo "  Logs: $LOG_DIR"
echo "  Backups: /opt/dev-aff-backups"
echo ""
echo "Nächste Schritte:"
echo "  1. CRON-Jobs testen: sudo -u $CRON_USER crontab -l"
echo "  2. Dashboard anschauen: $BIN_DIR/cron-dashboard.sh"
echo "  3. Logs überwachen: tail -f $LOG_DIR/*.log"
echo ""