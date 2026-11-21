#!/bin/bash
# fetch-and-validate.sh
# Täglich um 00:00 Uhr - Daten fetchen und validieren

set -euo pipefail

# Konfiguration
REPO_DIR="/opt/dev-affiliations"
LOG_FILE="/var/log/dev-aff/fetch.log"
ERROR_LOG="/var/log/dev-aff/errors.log"
BACKUP_DIR="/opt/dev-aff-backups"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Logging
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

error() {
    echo "[$TIMESTAMP] ERROR: $1" | tee -a "$ERROR_LOG"
    exit 1
}

log "═══════════════════════════════════════════════════════"
log "▶ FETCH & VALIDATE - $(date)"
log "═══════════════════════════════════════════════════════"

# 1. Backup erstellen
log "📦 Backup erstellen..."
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$BACKUP_FILE" -C "$REPO_DIR" data/ 2>>$ERROR_LOG || error "Backup fehlgeschlagen"
log "✓ Backup: $BACKUP_FILE"

# 2. Git Pull
cd "$REPO_DIR" || error "Kann nicht in $REPO_DIR wechseln"
log "🔄 Git Pull..."
git fetch origin main 2>>$ERROR_LOG || error "Git fetch fehlgeschlagen"
git reset --hard origin/main 2>>$ERROR_LOG || error "Git reset fehlgeschlagen"
log "✓ Git aktualisiert"

# 3. Validierung durchführen
log "✓ Validierung..."
if [ -f "scripts/validate.sh" ]; then
    bash scripts/validate.sh 2>>$ERROR_LOG || error "Validierung fehlgeschlagen"
    log "✓ Validierung erfolgreich"
else
    log "⚠ validate.sh nicht gefunden, überspringe Validierung"
fi

# 4. Statistiken sammeln
TOTAL_ENTRIES=$(wc -l < data/developers.txt 2>/dev/null || echo "0")
TOTAL_ORGS=$(cut -d' ' -f3 data/developers.txt 2>/dev/null | sort | uniq | wc -l || echo "0")

log "═══════════════════════════════════════════════════════"
log "✓ FETCH & VALIDATE ABGESCHLOSSEN"
log "  • Einträge: $TOTAL_ENTRIES"
log "  • Organisationen: $TOTAL_ORGS"
log "═══════════════════════════════════════════════════════"

