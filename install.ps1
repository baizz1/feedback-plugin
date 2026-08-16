# learning-stage-feedback plugin pack: one-shot installer (Windows PowerShell)
# Does: install the skill into the host's user-level skills directory.
# No Node.js, no browser, no Playwright required.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target DSH
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target WorkBuddy
param(
  [ValidateSet('Auto', 'DSH', 'WorkBuddy')]
  [string]$Target = 'Auto'
)

$ErrorActionPreference = 'Stop'
Write-Host "=== learning-stage-feedback plugin installer ($Target) ==="

function Fail($msg) { Write-Host ('[FAIL] ' + $msg) -ForegroundColor Red; exit 1 }

# 1. Choose host
if ($Target -eq 'Auto') {
  $dshExists = Test-Path (Join-Path $HOME '.dsh')
  $wbExists = Test-Path (Join-Path $HOME '.workbuddy')
  if ((-not $dshExists) -and $wbExists) { $Target = 'WorkBuddy' } else { $Target = 'DSH' }
  Write-Host "[OK] host detected: $Target"
}

if ($Target -eq 'WorkBuddy') {
  $root = Join-Path $HOME '.workbuddy'
} else {
  $root = Join-Path $HOME '.dsh'
}
$dst = Join-Path $root 'skills\learning-stage-feedback'

# 2. Source skill
$src = Join-Path $PSScriptRoot 'skills\learning-stage-feedback'
if (-not (Test-Path (Join-Path $src 'SKILL.md'))) { Fail 'skill source not found; run this script from the plugin folder' }
Write-Host ('[OK] skill source: ' + $src)

# 3. Install skill (overwrite old copy)
if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
Copy-Item $src $dst -Recurse
Write-Host ('[OK] skill installed: ' + $dst)

# 4. Verify copied files
$required = @(
  (Join-Path $dst 'SKILL.md'),
  (Join-Path $dst 'resources\api-reference.md'),
  (Join-Path $dst 'resources\copywriting-guide.md'),
  (Join-Path $dst 'resources\sql-templates.md'),
  (Join-Path $dst 'resources\site-manual.md')
)
$missing = $required | Where-Object { -not (Test-Path $_) }
if ($missing) { Fail ('missing installed files: ' + ($missing -join ', ')) }
Write-Host '[OK] all skill files present'

# 5. Done
Write-Host ''
Write-Host '=== install complete ==='
Write-Host 'No browser or Playwright is needed.'
if ($Target -eq 'WorkBuddy') {
  Write-Host 'Next steps:'
  Write-Host '1. Restart WorkBuddy or open a new session so it scans the new skill.'
  Write-Host '2. Run verify.ps1 -Target WorkBuddy to check the skill and the online template API.'
} else {
  Write-Host 'Next steps:'
  Write-Host '1. Restart the DSH GUI (unless hot reload picked it up).'
  Write-Host '2. Run verify.ps1 to check the skill and the online template API.'
}
Write-Host '3. Then just say:'
Write-Host '   Help me create a parent feedback template for attendance and exit tests.'
