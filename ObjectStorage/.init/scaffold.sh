#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/an-infinite-canvas-unpainted-12-89/ObjectStorage"
export CI=true
export BROWSER=none
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
# preserve existing project
[ -f package.json ] && { printf "package.json exists - skipping scaffold\n"; exit 0; }
# detect package manager
PKG_MGR=npm
[ -f yarn.lock ] && PKG_MGR=yarn
# Only run CRA into empty dir
if [ -z "$(ls -A .)" ]; then
  CRA_OPTS=()
  if [ "$PKG_MGR" = "yarn" ]; then CRA_OPTS+=("--use-yarn"); else CRA_OPTS+=("--use-npm"); fi
  # prefer preinstalled create-react-app, fallback to npx
  if command -v create-react-app >/dev/null 2>&1; then
    if create-react-app --version >/dev/null 2>&1; then
      if create-react-app . "${CRA_OPTS[@]}" --silent >/dev/null 2>&1; then
        printf "scaffold: CRA produced project using %s\n" "$PKG_MGR"; exit 0
      else
        printf "note: preinstalled create-react-app failed, will try npx\n" >&2
      fi
    fi
  fi
  if npx --yes create-react-app@latest . "${CRA_OPTS[@]}" --silent >/dev/null 2>&1; then
    printf "scaffold: CRA(npx) produced project using %s\n" "$PKG_MGR"; exit 0
  fi
fi
# Fallback minimal project
cat > package.json <<'EOF'
{
  "name": "objectstorage-app",
  "version": "0.0.0",
  "private": true,
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test --passWithNoTests --watchAll=false"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "^5.0.1"
  }
}
EOF
mkdir -p public src
cat > public/index.html <<'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>ObjectStorage</title>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
EOF
printf '' > public/favicon.ico
cat > src/App.js <<'EOF'
import React from 'react';
export default function App(){return <div>Hello ObjectStorage</div>}
EOF
cat > src/index.js <<'EOF'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
const el = document.getElementById('root');
createRoot(el).render(<App />);
EOF
printf "scaffold: created minimal fallback app (public/index.html + src)\n"
exit 0
