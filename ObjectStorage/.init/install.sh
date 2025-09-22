#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/an-infinite-canvas-unpainted-12-89/ObjectStorage"
cd "$WS"
# helper to check package.json safely
has_pkg_field() { node -e "try{const p=require('./package.json'); console.log(!!(p$1));}catch(e){console.log('false');}" 2>/dev/null || echo false; }
# If node_modules missing and package-lock exists, use npm ci (single action)
if [ ! -d node_modules ] && [ -f package-lock.json ]; then
  npm ci --prefer-offline --no-audit --no-fund || { echo "npm ci failed" >&2; exit 6; }
else
  # Determine missing runtime deps: react, react-dom
  missing=( )
  if ! node -e "try{const p=require('./package.json'); if(!(p.dependencies&&p.dependencies.react)) process.exit(1);}catch(e){process.exit(1)}" >/dev/null 2>&1; then missing+=(react); fi
  if ! node -e "try{const p=require('./package.json'); if(!(p.dependencies&&p.dependencies['react-dom'])) process.exit(1);}catch(e){process.exit(1)}" >/dev/null 2>&1; then missing+=(react-dom); fi
  if [ ${#missing[@]} -ne 0 ]; then npm install --no-audit --no-fund "${missing[@]}" || { echo "install runtime deps failed" >&2; exit 7; }; fi
fi
# Detect if project uses react-scripts
uses_cra=false
if node -e 'try{const p=require("./package.json"); if((p.dependencies&&p.dependencies["react-scripts"])||(p.devDependencies&&p.devDependencies["react-scripts"])) process.exit(0); process.exit(1);}catch(e){process.exit(1)}' >/dev/null 2>&1; then uses_cra=true; fi
# Testing libs and ESLint handling
if [ "$uses_cra" = true ]; then
  # Prefer CRA built-in ESLint and test; add testing-library only
  npm install -D --no-audit --no-fund @testing-library/react @testing-library/jest-dom || { echo "install testing libs failed" >&2; exit 8; }
  # Ensure test script exists and keep other scripts
  node -e 'const fs=require("fs");const p=fs.existsSync("package.json")?require("./package.json"):{};p.scripts=p.scripts||{}; if(!p.scripts.test) p.scripts.test="react-scripts test --env=jsdom --runInBand"; fs.writeFileSync("package.json",JSON.stringify(p,null,2))'
else
  # Non-CRA: install jest and testing libs
  npm install -D --no-audit --no-fund jest @testing-library/react @testing-library/jest-dom || { echo "install jest/testing libs failed" >&2; exit 9; }
  # add minimal ESLint react parser/plugins to avoid JSX parse errors
  npm install -D --no-audit --no-fund eslint-plugin-react @babel/eslint-parser || { echo "install eslint plugins failed" >&2; exit 10; }
  node -e 'const fs=require("fs");const p=fs.existsSync("package.json")?require("./package.json"):{};p.scripts=p.scripts||{}; if(!p.scripts.test) p.scripts.test="jest --runInBand"; fs.writeFileSync("package.json",JSON.stringify(p,null,2))'
fi
# TypeScript typings when requested
if [ "${TYPESCRIPT:-0}" = "1" ]; then
  npm install -D --no-audit --no-fund @types/react @types/react-dom || { echo "install TS types failed" >&2; exit 11; }
  [ -f tsconfig.json ] || npx tsc --init >/dev/null 2>&1 || true
fi
# ESLint config: prefer extending CRA if available, else minimal react-capable config
if [ "$uses_cra" = true ]; then
  # create minimal file that extends react-scripts if not present
  if [ ! -f .eslintrc.json ]; then
    cat > .eslintrc.json <<'EOF'
{ "extends": ["react-app", "react-app/jest"] }
EOF
  fi
else
  cat > .eslintrc.json <<'EOF'
{ "env": { "browser": true, "es2021": true }, "extends": ["eslint:recommended"], "parser": "@babel/eslint-parser", "parserOptions": {"requireConfigFile": false, "ecmaVersion": 2021, "sourceType": "module", "ecmaFeatures": {"jsx": true}}, "plugins": ["react"], "rules": {} }
EOF
fi
cat > .eslintignore <<'EOF'
node_modules
build
public
EOF
# Add smoke test (preserve if exists)
EXT=js
if [ -f src/App.tsx ] || [ -f src/index.tsx ]; then EXT=tsx; fi
mkdir -p src/__tests__
if [ ! -f "src/__tests__/smoke.test.${EXT}" ]; then
  cat > "src/__tests__/smoke.test.${EXT}" <<'EOF'
import React from 'react';
import { render } from '@testing-library/react';
import App from '../App';
 test('renders without crashing', () => { render(<App />); });
EOF
fi
