# learning-stage-feedback plugin pack: self-check (Windows PowerShell)
# Checks: PowerShell, skill files, HTTPS capability, online template API.
Write-Host '=== learning-stage-feedback plugin self-check ==='
$script:ok = $true
function Check($name, $cond, $detail) {
  if ($cond) { Write-Host ('[PASS] ' + $name + '  ' + $detail) }
  else { Write-Host ('[FAIL] ' + $name) -ForegroundColor Red; $script:ok = $false }
}

# 1. PowerShell
Check 'PowerShell' ($PSVersionTable.PSVersion.Major -ge 5) ('PS ' + $PSVersionTable.PSVersion.ToString())

# 2. Skill installed
$skill = Join-Path $env:USERPROFILE '.dsh\skills\learning-stage-feedback\SKILL.md'
Check 'skill SKILL.md' (Test-Path $skill) $skill

$resources = @(
  'resources\api-reference.md',
  'resources\copywriting-guide.md',
  'resources\sql-templates.md',
  'resources\site-manual.md'
)
$skillDir = Split-Path $skill -Parent
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
  Write-Host 'All checks passed: restart DSH, open a new session, and describe the template you want.'
  Write-Host 'Example: Help me create a parent feedback template for attendance and exit tests.'
} else {
  Write-Host 'Some checks failed: run install.ps1, check the network, then re-run this check.'
}
