# learning-stage-feedback plugin pack: self-check (Windows PowerShell)
# Checks: node, @playwright/mcp, browser, profile config, skill, MCP server process
Write-Host '=== learning-stage-feedback plugin self-check ==='
$script:ok = $true
function Check($name, $cond, $detail) {
  if ($cond) { Write-Host ('[PASS] ' + $name + '  ' + $detail) }
  else { Write-Host ('[FAIL] ' + $name) -ForegroundColor Red; $script:ok = $false }
}

# 1. node
$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) { Check 'node.js' $true $node.Source } else { Check 'node.js' $false '' }

# 2. @playwright/mcp
$prefix = ''
if ($node) {
  $raw = (npm prefix -g 2>$null | Select-Object -Last 1)
  if ($raw) { $prefix = $raw.ToString().Trim() }
}
$cli = ''
if ($prefix) { $cli = Join-Path $prefix 'node_modules\@playwright\mcp\cli.js' }
Check '@playwright/mcp' ($cli -ne '' -and (Test-Path $cli)) $cli

# 3. browser
$hasChrome = (Test-Path 'C:\Program Files\Google\Chrome\Application\chrome.exe') -or (Test-Path 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe')
$hasChromium = Test-Path (Join-Path $env:LOCALAPPDATA 'ms-playwright')
Check 'browser (Chrome/Chromium)' ($hasChrome -or $hasChromium) ''

# 4. profile config
$candidates = @()
$candidates += Join-Path $env:USERPROFILE '.dsh\profiles\web\cordis.patch.yml'
$candidates += Join-Path $env:USERPROFILE '.dsh\cordis.patch.yml'
$hit = $null
foreach ($p in $candidates) {
  if (Test-Path $p) {
    $c = Get-Content $p -Raw -ErrorAction SilentlyContinue
    if ($c -match 'mcp-playwright') { $hit = $p; break }
  }
}
Check 'profile configured (mcp-playwright)' ($hit -ne $null) $hit

# 5. skill
$skill = Join-Path $env:USERPROFILE '.dsh\skills\learning-stage-feedback\SKILL.md'
Check 'skill installed' (Test-Path $skill) $skill

# 6. MCP server process
$procs = Get-CimInstance Win32_Process -Filter "Name = 'node.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like '*@playwright/mcp/cli.js*' }
if ($procs) {
  $ids = ($procs | ForEach-Object { $_.ProcessId }) -join ','
  Check 'MCP server process running' $true ('PID ' + $ids)
} else {
  Check 'MCP server process running' $false '(restart GUI to spawn it, or check profile config)'
}

Write-Host ''
if ($script:ok) { Write-Host 'All checks passed: open a new session and use it.' }
else { Write-Host 'Some checks failed: run install.ps1 then re-run this check.' }
