# learning-stage-feedback plugin pack: self-check (Windows PowerShell)
# Checks: PowerShell, skill files, HTTPS capability, online template API.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\verify.ps1
#   powershell -ExecutionPolicy Bypass -File .\verify.ps1 -Target DSH
#   powershell -ExecutionPolicy Bypass -File .\verify.ps1 -Target WorkBuddy
param(
  [ValidateSet('Auto', 'DSH', 'WorkBuddy')]
  [string]$Target = 'Auto'
)

Write-Host "=== learning-stage-feedback plugin self-check ($Target) ==="
$script:ok = $true
function Check($name, $cond, $detail) {
  if ($cond) { Write-Host ('[PASS] ' + $name + '  ' + $detail) }
  else { Write-Host ('[FAIL] ' + $name) -ForegroundColor Red; $script:ok = $false }
}

# 0. Choose host
if ($Target -eq 'Auto') {
  $dshExists = Test-Path (Join-Path $HOME '.dsh')
  $wbExists = Test-Path (Join-Path $HOME '.workbuddy')
  if ((-not $dshExists) -and $wbExists) { $Target = 'WorkBuddy' } else { $Target = 'DSH' }
  Write-Host "[OK] host detected: $Target"
}

# 1. PowerShell
Check 'PowerShell' ($PSVersionTable.PSVersion.Major -ge 5) ('PS ' + $PSVersionTable.PSVersion.ToString())

# 2. Skill installed
if ($Target -eq 'WorkBuddy') {
  $skillDir = Join-Path $HOME '.workbuddy\skills\learning-stage-feedback'
} else {
  $skillDir = Join-Path $HOME '.dsh\skills\learning-stage-feedback'
}
$skill = Join-Path $skillDir 'SKILL.md'
Check 'skill SKILL.md' (Test-Path $skill) $skill

$resources = @(
  'resources\api-reference.md',
  'resources\copywriting-guide.md',
  'resources\sql-templates.md',
  'resources\site-manual.md'
)
$missing = $resources | Where-Object { -not (Test-Path (Join-Path $skillDir $_)) }
Check 'skill resources' ($missing.Count -eq 0) ('missing: ' + ($missing -join ', '))

# 3. HTTPS capability
$hasCurl = $null -ne (Get-Command curl.exe -ErrorAction SilentlyContinue)
$canIwr = $null -ne (Get-Command Invoke-WebRequest -ErrorAction SilentlyContinue)
Check 'HTTPS client (curl.exe or Invoke-WebRequest)' ($hasCurl -or $canIwr) ('curl.exe=' + $hasCurl + ', Invoke-WebRequest=' + $canIwr)

# 4. Online template API (read-only GET)
$api = 'https://follow-class-reminder.pages.dev/api/learning-feedback/templates'
$apiOk = $false
$detail = ''
try {
  if ($hasCurl) {
    $raw = & curl.exe -s -m 30 $api
  } else {
    $raw = (Invoke-WebRequest -Uri $api -UseBasicParsing -TimeoutSec 30).Content
  }
  $json = $raw | ConvertFrom-Json
  $apiOk = [bool]($json.ok -and ($json.templates -is [System.Array]))
  $detail = ('templates=' + $json.templates.Count)
} catch {
  $detail = $_.Exception.Message
}
Check 'online template API (GET)' $apiOk $detail

Write-Host ''
if ($script:ok) {
  if ($Target -eq 'WorkBuddy') {
    Write-Host 'All checks passed: restart WorkBuddy, open a new session, and describe the template you want.'
  } else {
    Write-Host 'All checks passed: restart DSH, open a new session, and describe the template you want.'
  }
  Write-Host 'Example: Help me create a parent feedback template for attendance and exit tests.'
} else {
  Write-Host ("Some checks failed: run install.ps1 -Target $Target, check the network, then re-run this check.")
}
