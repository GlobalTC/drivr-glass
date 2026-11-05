#!/usr/bin/env bash
# Resolve the glass session URL and token for helper scripts. Sourced, not run.
# Config lives ONLY in local files next to the Worker (mode 600, gitignored):
#   GLASS_URL.local   one line: https://<worker>.<subdomain>.workers.dev/s/<GLASS_SESSION_ID>
#   PUSH_TOKEN.local  the push token (same value as the PUSH_TOKEN secret)
# A URL passed on the command line is accepted only if it equals GLASS_URL.local.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
URL_FILE="$ROOT/GLASS_URL.local"
TOKEN_FILE="$ROOT/PUSH_TOKEN.local"
glass_load() {
  local who="$1" arg="${2:-}"
  [[ -f "$URL_FILE" ]] || { echo "$who: missing GLASS_URL.local (glass not configured); refusing" >&2; return 4; }
  SESSION_BASE="$(tr -d '[:space:]' < "$URL_FILE")"; SESSION_BASE="${SESSION_BASE%/}"
  [[ "$SESSION_BASE" =~ ^https://[^/]+/s/[A-Za-z0-9_-]+$ ]] || { echo "$who: GLASS_URL.local must be https://<host>/s/<id>; refusing" >&2; return 4; }
  [[ "$SESSION_BASE" != *REPLACE_ME* ]] || { echo "$who: GLASS_URL.local still has the placeholder id; refusing" >&2; return 4; }
  HOST_BASE="${SESSION_BASE%%/s/*}"
  if [[ -n "$arg" && "${arg%/}" != "$SESSION_BASE" && "${arg%/}" != "$HOST_BASE" ]]; then
    echo "$who: refusing URL that does not match GLASS_URL.local" >&2; return 4
  fi
  [[ -f "$TOKEN_FILE" ]] || { echo "$who: missing PUSH_TOKEN.local" >&2; return 2; }
  TOKEN="$(cat "$TOKEN_FILE")"
}
