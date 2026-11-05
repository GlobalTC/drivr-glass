#!/usr/bin/env bash
# Clear all traces on your drivr-glass Worker. Reads GLASS_URL.local + PUSH_TOKEN.local; never echoes the token.
set -euo pipefail
source "$(dirname "$0")/glass-config.sh"
glass_load clear-glass "${1:-}" || exit $?
out="$(mktemp)"
# POST body required — an empty POST with no body can 404 at the Durable Object stub.
code="$(curl -sS -o "$out" -w '%{http_code}' -X POST "$SESSION_BASE/clear" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{}')"
echo "POST <session>/clear -> HTTP $code $(cat "$out")"
rm -f "$out"
[[ "$code" == "200" ]] || { echo "clear failed" >&2; exit 1; }
echo "CLEAR OK"
