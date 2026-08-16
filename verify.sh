#!/bin/sh
# learning-stage-feedback plugin pack: self-check for macOS / Linux / WSL / Git Bash.
# Checks: skill files, HTTPS capability, online template API (read-only GET).
#
# Usage:
#   bash verify.sh              # auto-detect host (DSH or WorkBuddy)
#   bash verify.sh --dsh        # check DeepSeek Harness   -> ~/.dsh/skills
#   bash verify.sh --workbuddy  # check WorkBuddy          -> ~/.workbuddy/skills
set -u

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
  *) echo "Usage: bash verify.sh [--dsh|--workbuddy]" >&2; exit 2 ;;
esac

case "$host" in
  dsh)       root="${DSH_HOME:-$HOME/.dsh}" ;;
  workbuddy) root="${WORKBUDDY_HOME:-$HOME/.workbuddy}" ;;
esac
skill_dir="$root/skills/learning-stage-feedback"
ok=1

pass() { echo "[PASS] $1  $2"; }
fail() { echo "[FAIL] $1" >&2; ok=0; }

echo "=== learning-stage-feedback plugin self-check ($host) ==="

# 1. Skill files
if [ -f "$skill_dir/SKILL.md" ]; then
  pass 'skill SKILL.md' "$skill_dir"
else
  fail "skill SKILL.md (missing: $skill_dir/SKILL.md)"
fi

missing=""
for file in resources/api-reference.md resources/copywriting-guide.md resources/sql-templates.md resources/site-manual.md; do
  if [ ! -f "$skill_dir/$file" ]; then
    missing="$missing $file"
  fi
done
if [ -z "$missing" ]; then
  pass 'skill resources' "$skill_dir/resources"
else
  fail "skill resources (missing:$missing)"
fi

# 2. HTTPS capability
client=''
if command -v curl >/dev/null 2>&1; then
  client='curl'
elif command -v wget >/dev/null 2>&1; then
  client='wget'
elif command -v python3 >/dev/null 2>&1; then
  client='python3'
elif command -v python >/dev/null 2>&1; then
  client='python'
fi
if [ -n "$client" ]; then
  pass 'HTTPS client' "$client"
else
  fail 'HTTPS client (install curl, wget, or Python)'
fi

# 3. Online template API (read-only GET)
api='https://follow-class-reminder.pages.dev/api/learning-feedback/templates'
response=''
case "$client" in
  curl)
    response="$(curl -fsS -m 30 "$api" 2>/dev/null || true)"
    ;;
  wget)
    response="$(wget -qO- -T 30 "$api" 2>/dev/null || true)"
    ;;
  python3|python)
    response="$($client - "$api" <<'PY' 2>/dev/null || true
import sys, urllib.request
with urllib.request.urlopen(sys.argv[1], timeout=30) as resp:
    print(resp.read().decode('utf-8'))
PY
    )"
    ;;
esac

if printf '%s' "$response" | grep -q '"ok":true'; then
  pass 'online template API (GET)' 'ok=true'
else
  fail "online template API (GET) ($api)"
fi

echo ''
if [ "$ok" -eq 1 ]; then
  if [ "$host" = 'workbuddy' ]; then
    echo 'All checks passed: restart WorkBuddy, open a new session, and describe the template you want.'
  else
    echo 'All checks passed: restart DSH, open a new session, and describe the template you want.'
  fi
  echo 'Example: Help me create a parent feedback template for attendance and exit tests.'
else
  echo "Some checks failed: run install.sh --$host, check the network, then re-run this check."
  exit 1
fi
