<#
.SYNOPSIS
  Builds and packages the Azdroid Windows release as a portable ZIP.

.DESCRIPTION
  Windows counterpart of scripts/build_release.sh (macOS):
    1. Reads the version from pubspec.yaml.
    2. Runs flutter analyze and flutter test (skip with -SkipTests).
    3. Fetches the bundled adb (Android Platform-Tools, checksum-verified)
       and builds the x64 release with flutter build windows --release,
       which also compiles the MCP server (azdroid-mcp.exe).
    4. Stages the bundle, checks the files it needs at runtime, and
       smoke-tests the bundled adb.exe and azdroid-mcp.exe, so the ZIP
       runs on a PC without adb, Flutter, or Dart.
    5. Adds the Visual C++ runtime DLLs when the redistributable folder is
       installed with Visual Studio (warns otherwise).
    6. Writes RELEASE\Azdroid-v<version>-Windows-x64.zip and a "latest" copy.
    7. Writes SHA-256 checksums to RELEASE\SHA256SUMS-windows.txt.
    8. Optional (-Publish): uploads the ZIP to a GitHub Release with gh.

  The script never commits or pushes. It does not touch RELEASE\README.md
  or RELEASE\SHA256SUMS.txt, which the macOS script regenerates.

  Keep this file ASCII-only: Windows PowerShell 5.1 reads scripts without a
  BOM in the ANSI code page.

.PARAMETER SkipTests
  Skip flutter analyze and flutter test.

.PARAMETER Publish
  Upload the ZIP to the GitHub Release v<version> (creates it if missing).
  Requires the GitHub CLI (gh) and an authenticated session.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\build_release.ps1

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\build_release.ps1 -SkipTests
#>
[CmdletBinding()]
param(
  [switch]$SkipTests,
  [switch]$Publish
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Layout -------------------------------------------------------------------
$RootDir = Split-Path -Parent $PSScriptRoot
$ReleaseDir = Join-Path $RootDir 'RELEASE'
$PubspecPath = Join-Path $RootDir 'pubspec.yaml'
$BuildDir = Join-Path $RootDir 'build\windows\x64\runner\Release'
$StagingRoot = Join-Path $RootDir 'build\windows\package'
$PackageFolderName = 'Azdroid'
$ExeName = 'desk_droid.exe'
$ChecksumFileName = 'SHA256SUMS-windows.txt'
$RepoUrl = 'https://github.com/az-coder-123/azdroid'

# Files the app cannot start or stream without.
$RequiredFiles = @(
  $ExeName,
  'flutter_windows.dll',
  'data\icudtl.dat',
  'data\app.so',
  'data\flutter_assets\assets\scrcpy-server.jar',
  'adb.exe',
  'AdbWinApi.dll',
  'AdbWinUsbApi.dll',
  'platform-tools-NOTICE.txt',
  'azdroid-mcp.exe'
)

# The bundled MCP server must answer tools/list within this time.
$McpSmokeTimeoutMs = 20000
$McpSmokeRequest = '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'

# Visual C++ runtime DLLs used by Flutter and the native video plugin.
$VcRuntimePatterns = @('vcruntime140*.dll', 'msvcp140*.dll')

# --- Helpers ------------------------------------------------------------------
function Write-Step([string]$Message) {
  Write-Host ''
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
  Write-Host "    [ok] $Message" -ForegroundColor Green
}

function Write-Warn([string]$Message) {
  Write-Host "    [warning] $Message" -ForegroundColor Yellow
}

# Runs a native command and stops the script when it fails.
function Invoke-Checked([string]$Command, [string[]]$Arguments) {
  & $Command @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "'$Command $($Arguments -join ' ')' failed with exit code $LASTEXITCODE."
  }
}

function Get-AppVersion([string]$Path) {
  $line = Select-String -Path $Path -Pattern '^version:\s*(\S+)' | Select-Object -First 1
  if (-not $line) { throw "No 'version:' line found in $Path." }
  $raw = $line.Matches[0].Groups[1].Value
  $parts = $raw.Split('+')
  $build = if ($parts.Count -gt 1) { $parts[1] } else { '0' }
  return [pscustomobject]@{ Name = $parts[0]; Build = $build }
}

# Release (not debug) CRT folder shipped with Visual Studio, or $null.
function Find-VcRuntimeFolder {
  $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
  if (-not (Test-Path $vswhere)) { return $null }
  $vsPath = & $vswhere -latest -property installationPath
  if (-not $vsPath) { return $null }
  $redist = Join-Path $vsPath 'VC\Redist\MSVC'
  if (-not (Test-Path $redist)) { return $null }
  # debug_nonredist and onecore folders are excluded by this exact path shape.
  return Get-ChildItem -Path "$redist\*\x64\Microsoft.VC*.CRT" -Directory -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending |
    Select-Object -First 1
}

function Get-Sha256([string]$Path) {
  return (Get-FileHash -Algorithm SHA256 -Path $Path).Hash.ToLowerInvariant()
}

function Format-Size([long]$Bytes) {
  return '{0:N1} MB' -f ($Bytes / 1MB)
}

# Sends one JSON-RPC request to the MCP server and returns its first line,
# or throws when it does not answer in time.
function Invoke-McpSmokeTest([string]$McpPath) {
  $info = New-Object System.Diagnostics.ProcessStartInfo
  $info.FileName = $McpPath
  $info.UseShellExecute = $false
  $info.RedirectStandardInput = $true
  $info.RedirectStandardOutput = $true
  $info.RedirectStandardError = $true
  $process = [System.Diagnostics.Process]::Start($info)
  try {
    $process.StandardInput.WriteLine($McpSmokeRequest)
    $process.StandardInput.Close()
    $readLine = $process.StandardOutput.ReadLineAsync()
    if (-not $readLine.Wait($McpSmokeTimeoutMs)) {
      throw "azdroid-mcp.exe did not answer tools/list within $($McpSmokeTimeoutMs / 1000) s."
    }
    return $readLine.Result
  } finally {
    if (-not $process.HasExited) { $process.Kill() }
    $process.Dispose()
  }
}

# --- 1. Version ---------------------------------------------------------------
Write-Host '======================================================================'
Write-Host ' Azdroid - Windows release packaging'
Write-Host '======================================================================'

$version = Get-AppVersion $PubspecPath
$zipName = "Azdroid-v$($version.Name)-Windows-x64.zip"
$latestZipName = 'Azdroid-Windows-x64-latest.zip'
Write-Host "Version: v$($version.Name) (build $($version.Build)), target: Windows 10/11 x64"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'flutter was not found on PATH. Install Flutter and reopen the terminal.'
}

Push-Location $RootDir
try {
  # --- 2. Quality gate --------------------------------------------------------
  if ($SkipTests) {
    Write-Step 'Skipping flutter analyze and flutter test (-SkipTests)'
  } else {
    Write-Step 'Running flutter analyze'
    Invoke-Checked 'flutter' @('analyze')
    Write-Step 'Running flutter test'
    Invoke-Checked 'flutter' @('test')
  }

  # --- 3. Build ---------------------------------------------------------------
  # Release builds fail without the bundled adb (windows/CMakeLists.txt).
  Write-Step 'Fetching the bundled adb (Android Platform-Tools, checksum-verified)'
  Invoke-Checked 'dart' @('run', 'tool/fetch_platform_tools.dart', '--os=windows')

  Write-Step 'Building the Windows release (flutter build windows --release)'
  Invoke-Checked 'flutter' @('build', 'windows', '--release')

  # --- 4. Stage and verify ----------------------------------------------------
  Write-Step 'Staging the release bundle'
  if (Test-Path $StagingRoot) { Remove-Item $StagingRoot -Recurse -Force }
  $packageDir = Join-Path $StagingRoot $PackageFolderName
  New-Item -ItemType Directory -Path $packageDir -Force | Out-Null
  Copy-Item -Path (Join-Path $BuildDir '*') -Destination $packageDir -Recurse -Force

  $missing = @($RequiredFiles | Where-Object { -not (Test-Path (Join-Path $packageDir $_)) })
  if ($missing.Count -gt 0) {
    throw "The build is missing required files: $($missing -join ', ')"
  }
  Write-Ok "All $($RequiredFiles.Count) required files are present"

  # The package must work without an installed adb, Flutter, or Dart.
  $adbVersion = & (Join-Path $packageDir 'adb.exe') version | Select-Object -First 1
  if ($LASTEXITCODE -ne 0) { throw 'The bundled adb.exe does not run.' }
  Write-Ok "Bundled adb runs: $adbVersion"

  $mcpReply = Invoke-McpSmokeTest (Join-Path $packageDir 'azdroid-mcp.exe')
  if ($mcpReply -notmatch '"tools"') {
    throw "azdroid-mcp.exe did not list its tools. Reply: $mcpReply"
  }
  Write-Ok 'Bundled MCP server answers tools/list'

  # --- 5. Visual C++ runtime --------------------------------------------------
  Write-Step 'Adding the Visual C++ runtime'
  $crtFolder = Find-VcRuntimeFolder
  if ($crtFolder) {
    $dlls = foreach ($pattern in $VcRuntimePatterns) {
      Get-ChildItem -Path $crtFolder.FullName -Filter $pattern
    }
    $dlls | Copy-Item -Destination $packageDir -Force
    Write-Ok "Bundled $(@($dlls).Count) DLLs from $($crtFolder.FullName)"
  } else {
    Write-Warn 'Visual C++ redistributable folder not found; the ZIP will not include it.'
    Write-Warn 'Users without "Microsoft Visual C++ Redistributable (x64)" must install it.'
    Write-Warn 'To bundle it, add the "C++ v14 redistributable" files in the Visual Studio Installer.'
  }

  # --- 6. Archive -------------------------------------------------------------
  Write-Step 'Creating the ZIP archive'
  New-Item -ItemType Directory -Path $ReleaseDir -Force | Out-Null
  Get-ChildItem -Path $ReleaseDir -Filter 'Azdroid-v*-Windows-x64.zip' |
    Where-Object { $_.Name -ne $zipName } |
    Remove-Item -Force
  $zipPath = Join-Path $ReleaseDir $zipName
  $latestZipPath = Join-Path $ReleaseDir $latestZipName
  foreach ($path in @($zipPath, $latestZipPath)) {
    if (Test-Path $path) { Remove-Item $path -Force }
  }

  # ZipFile writes '/' entry separators, so the archive also opens on macOS
  # and Linux (Compress-Archive in PowerShell 5.1 writes '\').
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::CreateFromDirectory(
    $packageDir, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $true)
  Copy-Item $zipPath $latestZipPath -Force
  $zipSize = Format-Size (Get-Item $zipPath).Length
  Write-Ok "$zipName ($zipSize)"

  # --- 7. Checksums -----------------------------------------------------------
  Write-Step 'Writing SHA-256 checksums'
  $zipHash = Get-Sha256 $zipPath
  $checksumPath = Join-Path $ReleaseDir $ChecksumFileName
  # Same "<hash>  <file>" format as sha256sum / shasum -a 256.
  @(
    "$zipHash  $zipName",
    "$(Get-Sha256 $latestZipPath)  $latestZipName"
  ) | Set-Content -Path $checksumPath -Encoding Ascii
  Write-Ok "$ChecksumFileName ($zipHash)"

  # --- 8. Optional GitHub Release ---------------------------------------------
  if ($Publish) {
    Write-Step 'Uploading to GitHub Releases'
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
      throw 'gh (GitHub CLI) was not found on PATH; cannot use -Publish.'
    }
    $tag = "v$($version.Name)"
    & gh release view $tag *> $null
    if ($LASTEXITCODE -eq 0) {
      Invoke-Checked 'gh' @('release', 'upload', $tag, $zipPath, $checksumPath, '--clobber')
    } else {
      Invoke-Checked 'gh' @('release', 'create', $tag, $zipPath, $checksumPath,
        '--title', "Azdroid $tag", '--notes', "Windows 10/11 x64 build of Azdroid $tag.")
    }
    Write-Ok "$RepoUrl/releases/tag/$tag"
  }
} finally {
  Pop-Location
}

Write-Host ''
Write-Host '======================================================================'
Write-Host ' Windows release package ready' -ForegroundColor Green
Write-Host '======================================================================'
Write-Host "Archive:  $zipPath"
Write-Host "SHA-256:  $zipHash"
if (-not $Publish) {
  Write-Host 'Not published. Re-run with -Publish to upload it to GitHub Releases.'
}
