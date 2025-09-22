#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/an-infinite-canvas-unpainted-12-89/ObjectStorage"
cd "$WORKSPACE"
export CI=true
export BROWSER=none
# backup package.json
[ -f package.json ] && cp package.json package.json.bak.$(date -u +%s)
# choose package manager
PKG_MGR=npm
[ -f yarn.lock ] && PKG_MGR=yarn
# detect TS need
TS=false
[ -f tsconfig.json ] && TS=true
# prepare list of additional dev deps to ensure before install
DEV_ADD=()
if [ "$TS" = true ]; then DEV_ADD+=("typescript"); fi
# check for @testing-library/react in deps or devDeps
if ! node -e "const p=require('./package.json');const deps=Object.assign({},p.dependencies||{},p.devDependencies||{});process.exit(deps['@testing-library/react']?0:1)" >/dev/null 2>&1; then
  DEV_ADD+=("@testing-library/react" "@testing-library/jest-dom")
fi
# Install additional dev deps using chosen package manager (idempotent if no DEV_ADD)
if [ ${#DEV_ADD[@]} -ne 0 ]; then
  if [ "$PKG_MGR" = "yarn" ]; then
    yarn add --dev --silent "${DEV_ADD[@]}" >/dev/null 2>&1 || { echo "yarn add dev deps failed" >&2; exit 4; }
  else
    npm i --save-dev --no-audit --no-fund --no-progress "${DEV_ADD[@]}" >/dev/null 2>&1 || { echo "npm add dev deps failed" >&2; exit 4; }
  fi
fi
# Run primary install: prefer yarn install, otherwise npm ci if lockfile exists, else npm i
LOG="${WORKSPACE}/install_log_$(date -u +%s).log"
if [ "$PKG_MGR" = "yarn" ]; then
  if ! yarn install --silent >"$LOG" 2>&1; then echo "yarn install failed - see $LOG" >&2; exit 5; fi
else
  if [ -f package-lock.json ]; then
    if ! npm ci --no-audit --no-fund --no-progress >"$LOG" 2>&1; then echo "npm ci failed - see $LOG" >&2; exit 5; fi
  else
    if ! npm i --no-audit --no-fund --no-progress >"$LOG" 2>&1; then echo "npm install failed - see $LOG" >&2; exit 5; fi
  fi
fi
# Verify react-scripts presence (node_modules layout assumed classic)
if [ ! -x node_modules/.bin/react-scripts ] && [ ! -f node_modules/.bin/react-scripts ]; then
  echo 'react-scripts not present after install' >&2
  exit 6
fi
exit 0
