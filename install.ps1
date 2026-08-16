# learning-stage-feedback plugin pack: one-shot installer (Windows PowerShell)
# Does: install the skill into the DSH user-level skills directory.
# No Node.js, no browser, no Playwright required.
$ErrorActionPreference = 'Stop'
Write-Host '=== learning-stage-feedback plugin installer ==='

function Fail($msg) { Write-Host ('[FAIL] ' + $msg) -ForegroundColor Red; exit 1 }

# 1. Source skill
$src = Join-Path $PSScriptRoot 'skills\learning-stage-feedback'
if (-not (Test-Path (Join-Path $src 'SKILL.md'))) { Fail 'skill source not found; run this script from the plugin folder' }
Write-Host ('[OK] skill source: ' + $src)

# 2. DSH home
$dshHome = Join-Path $env:USERPROFILE '.dsh'
if (-not (Test-Path $dshHome)) { New-Item -ItemType Directory -Path $dshHome -Force | Out-Null }

# 3. Install skill (overwrite old copy)
$dst = Join-Path $dshHome 'skills\learning-stage-feedback'
if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
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
Write-Host 'Next steps:'
Write-Host '1. Restart the DSH GUI (unless hot reload picked it up).'
Write-Host '2. Run verify.ps1 to check the skill and the online template API.'
Write-Host '3. Open a new session and send a request like:'
Write-Host '   Help me create a parent feedback template for attendance and exit tests.'
Write-Host '   The skill loads automatically.'
