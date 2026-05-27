param(
    [switch]$Repair,
    [switch]$RestartAppServer
)

$ErrorActionPreference = "Continue"

function Write-Section {
    param([string]$Name)
    Write-Host ""
    Write-Host "== $Name =="
}

function Test-PathStatus {
    param([string]$Label, [string]$Path)
    $exists = Test-Path -LiteralPath $Path
    Write-Host ("{0}: {1} {2}" -f $Label, $(if ($exists) { "OK" } else { "MISSING" }), $Path)
    return $exists
}

function Get-ChromePluginRoot {
    $base = Join-Path $env:USERPROFILE ".codex\plugins\cache\openai-bundled\chrome"
    if (!(Test-Path -LiteralPath $base)) { return $null }

    $latest = Join-Path $base "latest"
    if (Test-Path -LiteralPath (Join-Path $latest "scripts\browser-client.mjs")) { return $latest }

    Get-ChildItem -LiteralPath $base -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "scripts\browser-client.mjs") } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}

function Invoke-NodeScript {
    param([string]$Node, [string]$Script, [string[]]$Args = @("--json"))
    if ((Test-Path -LiteralPath $Node) -and (Test-Path -LiteralPath $Script)) {
        & $Node $Script @Args
        Write-Host ("exit={0}" -f $LASTEXITCODE)
    } else {
        Write-Host "SKIP $Script"
    }
}

$codex = Join-Path $env:LOCALAPPDATA "OpenAI\Codex\bin\codex.exe"
$node = Join-Path $env:LOCALAPPDATA "OpenAI\Codex\bin\node.exe"
$nodeRepl = Join-Path $env:LOCALAPPDATA "OpenAI\Codex\bin\node_repl.exe"
$pluginRoot = Get-ChromePluginRoot
$browserClient = if ($pluginRoot) { Join-Path $pluginRoot "scripts\browser-client.mjs" } else { $null }

Write-Section "Core files"
$codexOk = Test-PathStatus "codex.exe" $codex
$nodeOk = Test-PathStatus "node.exe" $node
$nodeReplOk = Test-PathStatus "node_repl.exe" $nodeRepl
if ($pluginRoot) {
    Write-Host "Chrome plugin root: OK $pluginRoot"
    Test-PathStatus "browser-client.mjs" $browserClient | Out-Null
} else {
    Write-Host "Chrome plugin root: MISSING"
}

Write-Section "Chrome checks"
if ($pluginRoot -and $nodeOk) {
    Invoke-NodeScript $node (Join-Path $pluginRoot "scripts\installed-browsers.js")
    Invoke-NodeScript $node (Join-Path $pluginRoot "scripts\chrome-is-running.js")
    Invoke-NodeScript $node (Join-Path $pluginRoot "scripts\check-extension-installed.js")
    Invoke-NodeScript $node (Join-Path $pluginRoot "scripts\check-native-host-manifest.js")
} else {
    Write-Host "Chrome checks skipped because node.exe or Chrome plugin root is missing."
}

Write-Section "Codex MCP"
if ($codexOk) {
    & $codex mcp get node_repl
    $mcpExit = $LASTEXITCODE
    Write-Host ("mcp_get_exit={0}" -f $mcpExit)
} else {
    $mcpExit = 1
    Write-Host "Codex MCP check skipped because codex.exe is missing."
}

if ($Repair) {
    Write-Section "Repair"
    if (!($codexOk -and $nodeOk -and $nodeReplOk -and $browserClient -and (Test-Path -LiteralPath $browserClient))) {
        Write-Error "Cannot repair because one or more required Codex-side files are missing."
        exit 2
    }

    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $browserClient).Hash.ToLowerInvariant()
    & $codex mcp remove node_repl 2>$null | Out-Null
    & $codex mcp add node_repl --env "NODE_REPL_NODE_PATH=$node" --env "NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S=$hash" -- $nodeRepl
    & $codex mcp get node_repl

    if ($RestartAppServer) {
        Write-Section "Restart app-server"
        $servers = Get-CimInstance Win32_Process -Filter "name='codex.exe'" |
            Where-Object { $_.CommandLine -like "*app-server*" }
        foreach ($server in $servers) {
            Write-Host ("Stopping app-server pid {0}" -f $server.ProcessId)
            Stop-Process -Id $server.ProcessId -Force
        }
        Write-Host "Start a new Codex turn after the app-server restarts."
    }
}

Write-Section "Result"
if ($Repair) {
    Write-Host "Repair command completed. Verify from a fresh Codex turn by listing Chrome tabs through browser-client."
} else {
    Write-Host "Health check completed. Re-run with -Repair if node_repl is missing or browser-client trust is absent."
}
