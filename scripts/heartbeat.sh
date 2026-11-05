#!/usr/bin/env bash
# Optional heartbeat: posts every 2 min while .mode-on exists in the Worker folder. Token never printed.
# Set TZ to your own zone (e.g. TZ=America/New_York ./scripts/heartbeat.sh).
source "$(dirname "$0")/glass-config.sh"
glass_load heartbeat "${1:-}" || exit $?
FLAG="$ROOT/.mode-on"
while [[ -f "$FLAG" ]]; do
  TOKEN="$(cat "$TOKEN_FILE")"
  NOW="$(date '+%b %-d %-I:%M %p %Z')"
  curl -sS -o /dev/null -X POST "$SESSION_BASE/push" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d "{\"bot\":\"Drivr\",\"summary\":\"Cabin glass on\",\"detail\":\"Heartbeat at $NOW. Glass mode on.\"}" || true
  sleep 120
done
