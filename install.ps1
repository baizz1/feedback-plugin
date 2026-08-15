# learning-stage-feedback plugin pack: one-shot installer (Windows PowerShell)
# Does: 1) install @playwright/mcp; 2) write DSH profile MCP config; 3) install the skill
# Usage: right-click -> Run with PowerShell, or in pwsh run ./install.ps1
$ErrorActionPreference = 'Stop'
Write-Host '=== learning-stage-feedback plugin installer ==='

function Fail($msg) { Write-Host ('[FAIL] ' + $msg) -ForegroundColor Red; exit 1 }

# 1. Node.js
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCmd) { Fail 'node not found: install Node.js 18+ and add it to PATH' }
$nodePath = $nodeCmd.Source
Write-Host ('[OK] node: ' + $nodePath)

# 2. Global npm prefix and @playwright/mcp
$prefixRaw = (npm prefix -g 2>$null | Select-Object -Last 1)
if (-not $prefixRaw) { Fail 'npm unavailable' }
$prefix = $prefixRaw.ToString().Trim()
$cli = Join-Path $prefix 'node_modules\@playwright\mcp\cli.js'
if (-not (Test-Path $cli)) {
  Write-Host '[..] installing @playwright/mcp globally'
  npm install -g @playwright/mcp
  if (-not (Test-Path $cli)) { Fail '@playwright/mcp install failed' }
}
Write-Host ('[OK] @playwright/mcp: ' + $cli)

# 3. Browser: prefer system Chrome, else download Chromium (~150MB)
$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$chrome86 = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
$browser = 'chrome'
if (Test-Path $chrome) { Write-Host '[OK] using system Chrome' }
elseif (Test-Path $chrome86) { Write-Host '[OK] using system Chrome (x86)' }
else {
  Write-Host '[..] Chrome not found, downloading Chromium (please wait)'
  node $cli install chromium
  if ($LASTEXITCODE -ne 0) { Fail 'Chromium download failed' }
  $browser = 'chromium'
  Write-Host '[OK] Chromium ready'
}

# 4. DSH profile config: merge mcp-playwright (idempotent)
$dshHome = Join-Path $env:USERPROFILE '.dsh'
$patchPath = Join-Path $dshHome 'profiles\web\cordis.patch.yml'
if (-not (Test-Path $patchPath)) { $patchPath = Join-Path $dshHome 'cordis.patch.yml' }
if (-not (Test-Path $patchPath)) {
  $dir = Split-Path $patchPath -Parent
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  New-Item -ItemType File -Path $patchPath -Force | Out-Null
}
$patch = Get-Content $patchPath -Raw -ErrorAction SilentlyContinue
$nodeUnix = $nodePath.Replace('\','/')
$cliUnix = $cli.Replace('\','/')
if ($patch -notmatch 'mcp-playwright') {
  $snippet = @"

# Playwright MCP: browser automation tools (mcp__playwright__browser_*).
# Installed by the learning-stage-feedback plugin pack.
- insert:
    - id: mcp-playwright
      name: '@deepseek-ai/dsh-mcp-client'
      config:
        serverName: playwright
        transport: stdio
        command: '$nodeUnix'
        args:
          - '$cliUnix'
          - '--browser'
          - '$browser'
"@
  Add-Content -Path $patchPath -Value $snippet -Encoding UTF8
  Write-Host ('[OK] profile config written: ' + $patchPath)
} else {
  Write-Host '[OK] profile already has mcp-playwright (skipped)'
}

# 5. Install the skill to user-level skills dir
$src = Join-Path $PSScriptRoot 'skills\learning-stage-feedback'
$dst = Join-Path $dshHome 'skills\learning-stage-feedback'
if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
Copy-Item $src $dst -Recurse
Write-Host ('[OK] skill installed: ' + $dst)

# 6. Done
Write-Host ''
Write-Host '=== install complete ==='
Write-Host 'Next steps:'
Write-Host '1. Restart the DSH GUI (unless hot reload picked it up).'
Write-Host '2. Open a new session and send this test message:'
Write-Host '   Check whether browser tools are available; open https://follow-class-reminder.pages.dev/learning-stage-feedback and report the page title.'
Write-Host '3. Then just describe the template task; the skill loads automatically.'
