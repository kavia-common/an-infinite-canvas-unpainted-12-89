#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/an-infinite-canvas-unpainted-12-89/ObjectStorage"
cd "$WS"
# Ensure npx exists
command -v npx >/dev/null 2>&1 || { echo "ERROR: npx required" >&2; exit 2; }
# If package.json exists, validate CRA-like
if [ -f package.json ]; then
  node -e 'try{const p=require("./package.json"); const ok=(p.dependencies&&p.dependencies["react-scripts"])||(p.devDependencies&&p.devDependencies["react-scripts"])|| (p.scripts && (p.scripts.start||p.scripts.build)); if(!ok){console.error("package.json present but not CRA-like"); process.exit(2);} }catch(e){console.error("invalid package.json"); process.exit(3);}'
  if [ -d node_modules/react-scripts ]; then echo "Existing CRA project detected"; exit 0; fi
  echo "package.json indicates CRA but node_modules/react-scripts missing; installing dependencies via npm ci..." >&2
  # If package-lock exists prefer CI
  if [ -f package-lock.json ]; then npm ci --prefer-offline --no-audit --no-fund || { echo "npm ci failed" >&2; exit 4; }; else npm install --no-audit --no-fund || { echo "npm install failed" >&2; exit 5; }; fi
  exit 0
fi
# Determine if directory is empty (ignore . and ..)
non_empty=$(find . -mindepth 1 -maxdepth 1 | wc -l || true)
TS_OPT=""; [ "${TYPESCRIPT:-0}" = "1" ] && TS_OPT="--template typescript"
if [ "$non_empty" -eq 0 ]; then
  # empty workspace: scaffold in-place with small retry
  n=0; until n=$((n+1)) && npx create-react-app . --use-npm $TS_OPT >/dev/null 2>&1 && break || [ $n -lt 3 ]; do sleep 1; done
  if [ $n -ge 3 ]; then echo "create-react-app failed after retries" >&2; exit 6; fi
else
  # non-empty: scaffold into temp and merge safely (preserve existing files)
  TMPDIR=$(mktemp -d)
  trap 'rm -rf "$TMPDIR"' EXIT
  n=0; until n=$((n+1)) && npx create-react-app "$TMPDIR" --use-npm $TS_OPT >/dev/null 2>&1 && break || [ $n -lt 3 ]; do sleep 1; done
  if [ $n -ge 3 ]; then echo "create-react-app failed after retries" >&2; exit 7; fi
  # Use rsync to copy including dotfiles and avoid overwriting existing files
  command -v rsync >/dev/null 2>&1 || { echo "ERROR: rsync required" >&2; exit 8; }
  rsync -a --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r --ignore-existing "$TMPDIR/" "$WS/" || true
  rm -rf "$TMPDIR"
fi
# Create project .env for headless development (preserve if exists)
if [ ! -f "$WS/.env" ]; then
  cat > "$WS/.env" <<'EOF'
# Headless development env vars - no secrets
HOST=127.0.0.1
PORT=3000
REACT_APP_HEADLESS=true
EOF
fi
mkdir -p "$WS/local-storage" && chmod 755 "$WS/local-storage"
