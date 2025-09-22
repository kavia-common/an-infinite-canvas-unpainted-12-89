#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/an-infinite-canvas-unpainted-12-89/ObjectStorage"
cd "$WORKSPACE"
export CI=true
export BROWSER=none
export HOST=${HOST:-0.0.0.0}
PORT=${PORT:-3000}
WAIT_TIMEOUT=${WAIT_TIMEOUT:-60}
# optional build if public/index.html exists
if [ -f public/index.html ]; then
  LOG_BUILD="${WORKSPACE}/build_log_$(date -u +%s).log"
  if ! npm run build >"$LOG_BUILD" 2>&1; then echo "build failed - see $LOG_BUILD" >&2; exit 5; fi
fi
# Start dev server in its own process group using setsid
LOG_RUN="${WORKSPACE}/run_log_$(date -u +%s).log"
setsid bash -lc "HOST=$HOST PORT=$PORT npm start --silent" >"$LOG_RUN" 2>&1 &
SERVER_PID=$!
# get PGID of the started process (should be same as PID when setsid used)
PGID=$(ps -o pgid= ${SERVER_PID} 2>/dev/null | tr -d ' ' || true)
[ -z "$PGID" ] && PGID=$SERVER_PID
# ensure cleanup of process group
trap 'kill -TERM -$PGID 2>/dev/null || kill -TERM $SERVER_PID 2>/dev/null; sleep 2; kill -KILL -$PGID 2>/dev/null || kill -KILL $SERVER_PID 2>/dev/null' EXIT INT TERM
# readiness probe: check localhost and container IP
START_TS=$(date +%s)
END_TS=$((START_TS + WAIT_TIMEOUT))
OK=1
while [ $(date +%s) -lt $END_TS ]; do
  sleep 1
  # try localhost addresses
  if curl -sSf --max-time 1 "http://127.0.0.1:$PORT/" >/dev/null 2>&1 || curl -sSf --max-time 1 "http://localhost:$PORT/" >/dev/null 2>&1; then OK=0; break; fi
  # try container IP
  CONN_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
  if [ -n "$CONN_IP" ] && curl -sSf --max-time 1 "http://$CONN_IP:$PORT/" >/dev/null 2>&1; then OK=0; break; fi
  # heuristic: check run log for known success messages
  if grep -Eqi "You can now view|Compiled successfully|Local:|Project is running" "$LOG_RUN" 2>/dev/null; then OK=0; break; fi
done
if [ $OK -ne 0 ]; then echo "server did not respond in time; see run log: $LOG_RUN" >&2; exit 6; fi
printf "validation: server responded on port %s; run log: %s\n" "$PORT" "$LOG_RUN"
# normal exit will trigger trap to clean server
exit 0
