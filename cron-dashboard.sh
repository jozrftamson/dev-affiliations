#!/bin/bash
# cron-dashboard.sh
# Grafisches Dashboard für CRON-Überwachung

set -euo pipefail

LOG_DIR="/var/log/dev-aff"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     DEV-AFFILIATIONS CRON MONITORING DASHBOARD             ║${NC}"
echo -e "${BLUE}║     $TIMESTAMP                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Funktion: Job-Status prüfen
check_job() {
    local job_name=$1
    local log_file=$2
    local schedule=$3
    
    if [ -f "$log_file" ]; then
        local last_run=$(stat -c %y "$log_file" | cut -d' ' -f1-2)
        local size=$(du -h "$log_file" | cut -f1)
        
        if grep -q "ABGESCHLOSSEN" "$log_file" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} $job_name"
            echo "  └─ Letzte Ausführung: $last_run | Größe: $size"
        else
            echo -e "${YELLOW}⚠${NC} $job_name"
            echo "  └─ Warnung: Logs prüfen erforderlich"
        fi
    else
        echo -e "${RED}✗${NC} $job_name"
        echo "  └─ Noch nicht ausgeführt"
    fi
}

echo -e "${CYAN}📋 TÄGLICHE JOBS${NC}"
echo "─────────────────────────────────────────────────────────"
check_job "Fetch & Validate (00:00)" "$LOG_DIR/fetch.log" "00:00"
echo ""
check_job "Cleanup Duplicates (04:00)" "$LOG_DIR/cleanup.log" "04:00"
echo ""
check_job "Generate Stats (08:00)" "$LOG_DIR/stats.log" "08:00"
echo ""
check_job "Sync Tools (12:00)" "$LOG_DIR/sync.log" "12:00"
echo ""
check_job "Quality Check (16:00)" "$LOG_DIR/quality.log" "16:00"
echo ""
check_job "Archive & Cleanup (20:00)" "$LOG_DIR/archive.log" "20:00"
echo ""

# Fehlerübersicht
echo -e "${CYAN}🚨 FEHLERÜBERSICHT${NC}"
echo "─────────────────────────────────────────────────────────"
if [ -f "$LOG_DIR/errors.log" ]; then
    ERROR_COUNT=$(wc -l < "$LOG_DIR/errors.log")
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo -e "${RED}✗ Fehler gefunden: $ERROR_COUNT${NC}"
        echo ""
        echo "Letzte 5 Fehler:"
        tail -5 "$LOG_DIR/errors.log" | while read line; do
            echo -e "${RED}  • $line${NC}"
        done
    else
        echo -e "${GREEN}✓ Keine Fehler${NC}"
    fi
else
    echo -e "${GREEN}✓ Keine Fehler${NC}"
fi
echo ""

# Speichernutzung
echo -e "${CYAN}💾 SPEICHERNUTZUNG${NC}"
echo "─────────────────────────────────────────────────────────"
TOTAL_SIZE=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
echo "Logs Gesamtgröße: $TOTAL_SIZE"
echo ""

# Statistiken
echo -e "${CYAN}📊 AKTUELLE STATISTIKEN${NC}"
echo "─────────────────────────────────────────────────────────"
if [ -f "/opt/dev-affiliations/data/developers.txt" ]; then
    DEVS=$(wc -l < /opt/dev-affiliations/data/developers.txt)
    ORGS=$(cut -d' ' -f3 /opt/dev-affiliations/data/developers.txt | sort | uniq | wc -l)
    echo "Entwickler: $DEVS"
    echo "Organisationen: $ORGS"
else
    echo "Daten nicht verfügbar"
fi
echo ""

# Nächste geplante Jobs
echo -e "${CYAN}⏰ NÄCHSTE JOBS${NC}"
echo "─────────────────────────────────────────────────────────"
HOUR=$(date +%H)
if [ "$HOUR" -lt "4" ]; then
    echo "▶ 04:00 - Cleanup Duplicates"
elif [ "$HOUR" -lt "8" ]; then
    echo "▶ 08:00 - Generate Stats"
elif [ "$HOUR" -lt "12" ]; then
    echo "▶ 12:00 - Sync Tools"
elif [ "$HOUR" -lt "16" ]; then
    echo "▶ 16:00 - Quality Check"
elif [ "$HOUR" -lt "20" ]; then
    echo "▶ 20:00 - Archive & Cleanup"
else
    echo "▶ 00:00 - Fetch & Validate (morgen)"
fi
echo ""

echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""