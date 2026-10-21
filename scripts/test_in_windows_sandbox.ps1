<#
.SYNOPSIS
  Opens a Azdroid Windows release ZIP in Windows Sandbox and smoke-tests it.

.DESCRIPTION
  Windows Sandbox is a clean, disposable Windows: no Visual C++ runtime,
  adb, Flutter, Dart, or Android SDK. It is the closest local check that a
  release ZIP runs on a normal user's PC.

  The sandbox gets three mapped folders: the ZIP's folder and scripts\sandbox
  (read-only), and a results folder (writable). At logon,
  scripts\sandbox\sandbox_smoke.ps1 extracts the ZIP to the sandbox desktop,
  records what the clean PC provides, smoke-tests azdroid-mcp.exe and
  desk_droid.exe, and keeps copying the app logs to the results folder.
  Read <ResultsDir>\smoke.txt on the host.

  In the sandbox, connect a phone over Wi-Fi (USB is not passed through):
  use Direct IP with the phone's address and port 5555 (enable it once with
  "adb tcpip 5555"). The phone asks to allow the new computer.

  Requires Windows 10/11 Pro or Enterprise with the Windows Sandbox feature.
  Keep this file ASCII-only (Windows PowerShell 5.1 reads it as ANSI).

.PARAMETER Zip
  Release ZIP to test. Default: the newest RELEASE\Azdroid-v*-Windows-x64.zip.

.PARAMETER ResultsDir
  Host folder for smoke.txt and the copied logs. Default: build\sandbox-results.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\test_in_windows_sandbox.ps1
#>
[CmdletBinding()]
param(
  [string]$Zip,
  [string]$ResultsDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RootDir = Split-Path -Parent $PSScriptRoot
$SandboxExe = Join-Path $env:SystemRoot 'System32\WindowsSandbox.exe'
$SandboxReleaseDir = 'C:\AzdroidRelease'
$SandboxScriptsDir = 'C:\AzdroidScripts'
$SandboxResultsDir = 'C:\AzdroidResults'

if (-not (Test-Path $SandboxExe)) {
  Write-Host 'Windows Sandbox is not enabled. In an elevated PowerShell run:' -ForegroundColor Yellow
  Write-Host '  Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All'
  Write-Host 'then restart Windows and run this script again.'
  exit 1
}

if (-not $Zip) {
  $latest = Get-ChildItem (Join-Path $RootDir 'RELEASE') -Filter 'Azdroid-v*-Windows-x64.zip' |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $latest) { throw 'No RELEASE\Azdroid-v*-Windows-x64.zip found. Run scripts\build_release.ps1 first.' }
  $Zip = $latest.FullName
}
$Zip = (Resolve-Path $Zip).Path
$zipName = Split-Path -Leaf $Zip

if (-not $ResultsDir) { $ResultsDir = Join-Path $RootDir 'build\sandbox-results' }
if (Test-Path $ResultsDir) { Remove-Item $ResultsDir -Recurse -Force }
New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
$ResultsDir = (Resolve-Path $ResultsDir).Path

function New-MappedFolder([string]$HostFolder, [string]$SandboxFolder, [bool]$ReadOnly) {
  return @"
    <MappedFolder>
      <HostFolder>$HostFolder</HostFolder>
      <SandboxFolder>$SandboxFolder</SandboxFolder>
      <ReadOnly>$($ReadOnly.ToString().ToLowerInvariant())</ReadOnly>
    </MappedFolder>
"@
}

$smokeArgs = "-File $SandboxScriptsDir\sandbox_smoke.ps1 " +
  "-ZipPath $SandboxReleaseDir\$zipName -ResultsDir $SandboxResultsDir"

$config = @"
<Configuration>
  <Networking>Enable</Networking>
  <MappedFolders>
$(New-MappedFolder (Split-Path -Parent $Zip) $SandboxReleaseDir $true)
$(New-MappedFolder (Join-Path $PSScriptRoot 'sandbox') $SandboxScriptsDir $true)
$(New-MappedFolder $ResultsDir $SandboxResultsDir $false)
  </MappedFolders>
  <LogonCommand>
    <Command>powershell.exe -NoProfile -ExecutionPolicy Bypass $smokeArgs</Command>
  </LogonCommand>
</Configuration>
"@

# Fails early on a malformed configuration instead of inside the sandbox.
[xml]$config | Out-Null
$wsbPath = Join-Path $env:TEMP 'AzdroidSandbox.wsb'
Set-Content -Path $wsbPath -Value $config -Encoding UTF8
Write-Host "Testing $zipName in Windows Sandbox."
Write-Host "Results: $(Join-Path $ResultsDir 'smoke.txt')"
Start-Process $wsbPath
