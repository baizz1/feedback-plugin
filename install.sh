#!/bin/sh
# learning-stage-feedback plugin pack: installer for macOS / Linux / WSL / Git Bash.
# It only copies the skill into the DeepSeek Harness (DSH) user-level skills directory.
# No Node.js, no browser, no Playwright required.
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
src="$script_dir/skills/learning-stage-feedback"
dsh_home="${DSH_HOME:-$HOME/.dsh}"
dst="$dsh_home/skills/learning-stage-feedback"

echo '=== learning-stage-feedback plugin installer ==='

if [ ! -f "$src/SKILL.md" ]; then
  echo "[FAIL] skill source not found: $src" >&2
  echo "       Run this script from the feedback-plugin folder." >&2
  exit 1
fi
echo "[OK] skill source: $src"

if [ -e "$dst" ]; then
  rm -rf "$dst"
fi
mkdir -p "$(dirname "$dst")"
cp -R "$src" "$dst"
echo "[OK] skill installed: $dst"

required="SKILL.md resources/api-reference.md resources/copywriting-guide.md resources/sql-templates.md resources/site-manual.md"
missing=""
for file in $required; do
  if [ ! -f "$dst/$file" ]; then
    missing="$missing $file"
  fi
done
if [ -n "$missing" ]; then
  echo "[FAIL] missing installed files:$missing" >&2
  exit 1
fi
echo '[OK] all skill files present'

echo ''
echo '=== install complete ==='
echo 'No browser or Playwright is needed.'
echo 'Next steps:'
echo '1. Restart the DSH GUI (unless hot reload picked it up).'
echo '2. Run verify.sh to check the skill and the online template API.'
echo '3. Open a new session and send a request like:'
echo '   Help me create a parent feedback template for attendance and exit tests.'
echo '   The skill loads automatically.'
