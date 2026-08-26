#!/usr/bin/env bash
#
# Diameris web client — development mode.
#
# Runs the Vapor server on :8080 and the Vite dev server on :5173 with HMR. Vite proxies /api to
# the Vapor server (see Client/vite.config.ts), so you open **http://127.0.0.1:5173** and get
# live reload on the frontend while the API stays on one origin's worth of config.
#
# Ctrl-C stops both.

set -euo pipefail

WEB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$WEB_DIR/Client"
SERVER_DIR="$WEB_DIR/Server"
API_PORT=8080
VITE_PORT=5173

log() { printf '\033[1;35m▸\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$1"; }

already_serving() {
  curl -fsS -o /dev/null --max-time 3 "http://127.0.0.1:$1/api/state" 2>/dev/null
}

# The API side is idempotent-by-deference: if something is already serving 8080, reuse it rather
# than starting a doomed second instance (see the long note in run.sh).
REUSE_API=false
if already_serving "$API_PORT"; then
  log "Reusing the server already on http://127.0.0.1:$API_PORT"
  REUSE_API=true
elif [[ -n "$(lsof -ti:"$API_PORT" -sTCP:LISTEN 2>/dev/null)" ]]; then
  warn "Port $API_PORT is bound but not serving /api/state — stop that pid first:"
  lsof -nP -iTCP:"$API_PORT" -sTCP:LISTEN | sed 's/^/    /'
  exit 1
fi

if [[ -n "$(lsof -ti:"$VITE_PORT" -sTCP:LISTEN 2>/dev/null)" ]]; then
  warn "Port $VITE_PORT (Vite) is already in use:"
  lsof -nP -iTCP:"$VITE_PORT" -sTCP:LISTEN | sed 's/^/    /'
  warn "Stop it and retry:  kill \$(lsof -ti:$VITE_PORT -sTCP:LISTEN)"
  exit 1
fi

pids=()
cleanup() {
  log "Shutting down…"
  for pid in "${pids[@]:-}"; do
    [[ -n "$pid" ]] && kill "$pid" 2>/dev/null || true
  done
  wait 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Build first so a compile error surfaces here rather than in a backgrounded process.
if [[ "$REUSE_API" == false ]]; then
  log "Building server…"
  (cd "$SERVER_DIR" && swift build)

  log "Starting API on http://127.0.0.1:$API_PORT"
  (cd "$SERVER_DIR" && swift run DiamerisServer serve \
    --hostname 127.0.0.1 --port "$API_PORT") &
  pids+=($!)
fi

if [[ -f "$CLIENT_DIR/package.json" ]] && command -v npm >/dev/null 2>&1; then
  if [[ ! -d "$CLIENT_DIR/node_modules" ]]; then
    log "Installing client dependencies…"
    (cd "$CLIENT_DIR" && npm install)
  fi
  log "Starting Vite on http://127.0.0.1:$VITE_PORT  ← open this one"
  (cd "$CLIENT_DIR" && npm run dev) &
  pids+=($!)
else
  warn "No client (or no npm) — API only, on http://127.0.0.1:$API_PORT"
fi

wait
