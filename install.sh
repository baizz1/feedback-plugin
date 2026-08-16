#!/bin/sh
# learning-stage-feedback plugin pack: installer for macOS / Linux / WSL / Git Bash.
# It only copies the skill into the host's user-level skills directory.
# No Node.js, no browser, no Playwright required.
#
# Usage:
#   bash install.sh              # auto-detect host (DSH or WorkBuddy)
#   bash install.sh --dsh        # force DeepSeek Harness   -> ~/.dsh/skills
#   bash install.sh --workbuddy  # force WorkBuddy          -> ~/.workbuddy/skills
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
src="$script_dir/skills/learning-stage-feedback"

host=''
case "${1:-}" in
  '')
    if [ -n "${WORKBUDDY_HOME:-}" ] || { [ ! -d "${DSH_HOME:-$HOME/.dsh}" ] && [ -d "$HOME/.workbuddy" ]; }; then
      host='workbuddy'
    else
      host='dsh'
    fi
    ;;
  --dsh|dsh) host='dsh' ;;
  --workbuddy|workbuddy) host='workbuddy' ;;
  *) echo "Usage: bash install.sh [--dsh|--workbuddy]" >&2; exit 2 ;;
esac

case "$host" in
  dsh)       root="${DSH_HOME:-$HOME/.dsh}" ;;
  workbuddy) root="${WORKBUDDY_HOME:-$HOME/.workbuddy}" ;;
esac
dst="$root/skills/learning-stage-feedback"

echo "=== learning-stage-feedback plugin installer ($host) ==="

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

required="SKILL.md resources/api-reference.md resources/copywriting-guide.md resources/preview-manifest.md resources/sql-templates.md resources/site-manual.md"
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
if [ "$host" = 'workbuddy' ]; then
  echo 'Next steps:'
  echo '1. Restart WorkBuddy or open a new session so it scans the new skill.'
  echo '2. Run verify.sh --workbuddy to check the skill and the online template API.'
else
  echo 'Next steps:'
  echo '1. Restart the DSH GUI (unless hot reload picked it up).'
  echo '2. Run verify.sh to check the skill and the online template API.'
fi
echo '3. Then just say:'
echo '   Help me create a parent feedback template for attendance and exit tests.'
