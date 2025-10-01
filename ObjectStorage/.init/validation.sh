#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/an-infinite-canvas-unpainted-12-89/ObjectStorage"
cd "$WS"
export CI=true
export BROWSER=none
# build using local binary when available
if [ -x ./node_modules/.bin/react-scripts ]; then
  ./node_modules/.bin/react-scripts build || { echo 'build failed' >&2; exit 7; }
else
  npm run build --silent || { echo 'build failed' >&2; exit 7; }
fi
BUILD_DIR="$WS/build"
[ -d "$BUILD_DIR" ] || { echo 'build directory missing' >&2; exit 8; }
# pick port: prefer 3000 if free, otherwise ask python to bind to 0 and print port
PREFERRED=3000
is_port_free_py() {
  python3 - <<PY 2>/dev/null || true
import socket,sys
s=socket.socket();
try:
 s.bind(('127.0.0.1', $1));
 s.close();
 print('free')
except Exception as e:
 print('busy')
PY
}
if [ "$(is_port_free_py)" = "free" ]; then PORT=$PREFERRED; else
  PORT=$(python3 - <<PY
import socket
s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1]);s.close()
PY
)
fi
pushd "$BUILD_DIR" >/dev/null
python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
SVC_PID=$!
# ensure server is cleaned up on exit
cleanup(){ kill -TERM "$SVC_PID" 2>/dev/null || true; for i in {1..10}; do if kill -0 "$SVC_PID" 2>/dev/null; then sleep 1; else break; fi; done; kill -KILL "$SVC_PID" 2>/dev/null || true; }
trap cleanup EXIT
# wait for server up to 20s
TRIES=0
until curl -sS -o /dev/null "http://127.0.0.1:${PORT}/" || [ $TRIES -ge 20 ]; do sleep 1; TRIES=$((TRIES+1)); done
if [ $TRIES -ge 20 ]; then
  echo 'static server did not respond in time' >&2
  exit 9
fi
STATUS=$(curl -sS -I "http://127.0.0.1:${PORT}/" | head -n1 || true)
SNIPPET=$(curl -sS "http://127.0.0.1:${PORT}/" | head -c 200 || true)
echo "$STATUS"
echo "$SNIPPET"
# cleanup will run via trap
popd >/dev/null
