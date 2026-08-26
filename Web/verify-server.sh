#!/usr/bin/env bash
#
# Starts an ISOLATED Diameris server for the Verify harness and the propagation gate.
#
# Port 8081 with its own throwaway store, so `POST /api/reset` here cannot wipe the store someone
# is driving in a browser on 8080 (R29). Every agent can verify concurrently without racing.
#
#   ./verify-server.sh                 # foreground on 8081, temp store
#   DIAMERIS_PORT=8082 ./verify-server.sh
#
# Then point tooling at it:
#   python3 Docs/api-propagation-check.py --base-url http://127.0.0.1:8081
#   PLAYWRIGHT_BASE_URL=http://127.0.0.1:8081 npm test --prefix Verify

set -euo pipefail

WEB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$WEB_DIR/Server"
PORT="${DIAMERIS_PORT:-8081}"
STORE="${DIAMERIS_STORE:-${TMPDIR:-/tmp}/diameris-verify-$PORT.json}"

log() { printf '\033[1;36m▸\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$1"; }

# --- Idempotency: never start a second instance, even under a concurrent launch ---------------
#
# A duplicate start does not fail cleanly — the new process binds, logs "Diameris web server on
# ...", then dies with `bind(...): Address already in use`. During the overlap requests can land on
# the instance that is dying, which reads as an intermittently unreachable server.
#
# A bare check-then-start is NOT enough: two launches inside the ~4s boot window both see "not
# serving" and both start. (Verified — that is the actual flapping mechanism.) So take an atomic
# lock on the port first. `mkdir` is the portable atomic primitive; `flock` is not on macOS.
#
# `lsof` on the specific port is the right liveness instrument. `pgrep -f DiamerisServer` is NOT:
# it matches ANY instance, so it reports "running" for the Verify server on 8081 while $PORT has no
# listener at all.
LOCK_DIR="${TMPDIR:-/tmp}/diameris-start-$PORT.lock"

already_serving() {
  curl -fsS -o /dev/null --max-time 3 "http://127.0.0.1:$1/api/state" 2>/dev/null
}

port_pids() {
  lsof -ti:"$1" -sTCP:LISTEN 2>/dev/null | tr '\n' ' ' | sed 's/ $//'
}

# Wait up to ~60s for whoever holds the lock to finish booting.
wait_for_serving() {
  for _ in $(seq 1 60); do
    already_serving "$PORT" && return 0
    sleep 1
  done
  return 1
}

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  # Another launch is mid-start. Stale locks are cleared by the trap below; if one survives a
  # SIGKILL, it is older than an hour and safe to reclaim.
  if [[ -n "$(find "$LOCK_DIR" -maxdepth 0 -mmin +60 2>/dev/null)" ]]; then
    warn "Clearing a stale start lock ($LOCK_DIR)"
    rmdir "$LOCK_DIR" 2>/dev/null || true
    mkdir "$LOCK_DIR" 2>/dev/null || true
  else
    log "Another launch is starting port $PORT — waiting for it…"
    if wait_for_serving; then
      log "Already serving on http://127.0.0.1:$PORT (pid $(port_pids "$PORT")) — nothing to do."
      exit 0
    fi
    # The holder never came up. If nothing is on the port it was killed before it could release
    # the lock (SIGKILL skips the trap), so reclaim rather than leaving the next launch wedged.
    if [[ -z "$(port_pids "$PORT")" ]]; then
      warn "The other launch never bound $PORT — reclaiming its lock."
      rmdir "$LOCK_DIR" 2>/dev/null || true
      mkdir "$LOCK_DIR" 2>/dev/null || true
    else
      warn "Port $PORT is bound by pid $(port_pids "$PORT") but never served /api/state."
      warn "Stop it and retry:  kill $(port_pids "$PORT")"
      exit 1
    fi
  fi
fi
# Release the lock however we leave, so a failed start never wedges the next one.
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

if already_serving "$PORT"; then
  log "Already serving on http://127.0.0.1:$PORT (pid $(port_pids "$PORT")) — nothing to do."
  exit 0
fi

if [[ -n "$(port_pids "$PORT")" ]]; then
  warn "Port $PORT is bound by pid $(port_pids "$PORT") but not serving /api/state."
  warn "Stop it and retry:  kill $(port_pids "$PORT")"
  exit 1
fi

# Fresh store every launch, so a run never inherits a previous run's state. Only reached when we
# are actually starting one — an already-serving instance keeps its store.
rm -f "$STORE"

log "Building server…"
(cd "$SERVER_DIR" && swift build)

log "Verify server on http://127.0.0.1:$PORT"
log "Store (disposable): $STORE"
cd "$SERVER_DIR"
exec env DIAMERIS_PORT="$PORT" DIAMERIS_STORE="$STORE" \
  swift run DiamerisServer serve --hostname 127.0.0.1 --port "$PORT"
