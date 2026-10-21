<#
  Runs INSIDE Windows Sandbox at logon (started by
  scripts\test_in_windows_sandbox.ps1). Extracts the release ZIP, records
  what a clean PC provides, smoke-tests the MCP server and the app, then
  keeps copying the app logs to the mapped results folder so they can be
  read on the host.

  Keep this file ASCII-only (Windows PowerShell 5.1 reads it as ANSI).
#>
param(
  [Parameter(Mandatory = $true)][string]$ZipPath,
  [Parameter(Mandatory = $true)][string]$ResultsDir,
  [int]$LogCopyMinutes = 20
)

$ErrorActionPreference = 'Continue'
$report = Join-Path $ResultsDir 'smoke.txt'
$LogCopyIntervalSeconds = 15
$AppSettleSeconds = 20

function Write-Report([string]$Message) {
  "$(Get-Date -Format 'HH:mm:ss') $Message" | Add-Content -Path $report -Encoding Ascii
}

Set-Content -Path $report -Value "Azdroid sandbox smoke test: $(Split-Path -Leaf $ZipPath)" -Encoding Ascii

# 1. What a clean PC provides.
Write-Report "Windows: $((Get-CimInstance Win32_OperatingSystem).Caption) $([Environment]::OSVersion.Version)"
Write-Report "adb on PATH: $([bool](Get-Command adb -ErrorAction SilentlyContinue))"
Write-Report "dart on PATH: $([bool](Get-Command dart -ErrorAction SilentlyContinue))"
Write-Report "VC++ runtime in System32: $(Test-Path "$env:SystemRoot\System32\vcruntime140.dll")"
Write-Report "Media Foundation (mfplat.dll): $(Test-Path "$env:SystemRoot\System32\mfplat.dll")"

# 2. Extract like a user would.
$desktop = Join-Path $env:USERPROFILE 'Desktop'
Expand-Archive -Path $ZipPath -DestinationPath $desktop -Force
$app = Join-Path $desktop 'Azdroid'
Write-Report "Extracted to $app"

# 3. MCP server: one tools/list request.
$request = '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
$mcpExe = if (Test-Path (Join-Path $app 'azdroid-mcp.exe')) { 'azdroid-mcp.exe' } else { 'deskdroid-mcp.exe' }
$reply = $request | & (Join-Path $app $mcpExe) 2>$null | Select-Object -First 1
try {
  Write-Report "MCP tools/list: $((($reply | ConvertFrom-Json).result.tools).Count) tools"
} catch {
  Write-Report "MCP tools/list FAILED: $reply"
}

# 4. The app.
$process = Start-Process (Join-Path $app 'desk_droid.exe') -PassThru
Start-Sleep -Seconds $AppSettleSeconds
$alive = -not $process.HasExited
Write-Report "App running after $AppSettleSeconds s: $alive"
if ($alive) {
  $runtime = (Get-Process -Id $process.Id).Modules |
    Where-Object { $_.ModuleName -match '^(vcruntime140|msvcp140)' }
  foreach ($module in $runtime) { Write-Report "Loaded $($module.ModuleName) from $($module.FileName)" }
  Write-Report "mfplat.dll loaded at startup: $([bool]((Get-Process -Id $process.Id).Modules | Where-Object ModuleName -eq 'mfplat.dll'))"
} else {
  Write-Report "App exited with code $($process.ExitCode)"
}
$adbProcess = Get-CimInstance Win32_Process -Filter "Name='adb.exe'" | Select-Object -First 1
Write-Report "adb server: $(if ($adbProcess) { $adbProcess.ExecutablePath } else { 'not running' })"
Write-Report 'Ready: connect the phone over Wi-Fi in the app (Direct IP, port 5555).'

# 5. Keep the logs visible on the host while the tester uses the app.
$logs = @('azdroid_dart.log', 'deskdroid_dart.log', 'scrcpy_stream.log') | ForEach-Object { Join-Path $env:TEMP $_ }
$rounds = [int]($LogCopyMinutes * 60 / $LogCopyIntervalSeconds)
for ($i = 0; $i -lt $rounds; $i++) {
  foreach ($log in $logs) {
    if (Test-Path $log) { Copy-Item $log -Destination $ResultsDir -Force }
  }
  Start-Sleep -Seconds $LogCopyIntervalSeconds
}
Write-Report 'Stopped copying logs.'
