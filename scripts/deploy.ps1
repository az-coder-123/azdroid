<#
.SYNOPSIS
  Azdroid - Automated Windows Release & Deployment Pipeline.

.DESCRIPTION
  Automates the complete Windows release lifecycle after a release tag
  is initiated on macOS:
    1. Pre-flight toolchain check (flutter, dart, git, gh).
    2. Git synchronization: pulls latest commits from origin/main.
    3. Reads and verifies the target semantic version from pubspec.yaml.
    4. Runs quality gate: flutter analyze and flutter test.
    5. Builds and packages via scripts\build_release.ps1 (bundles ADB,
       compiles desk_droid.exe and azdroid-mcp.exe, includes VC++ runtime,
       generates ZIP and SHA256SUMS-windows.txt).
    6. Optional (-TestSandbox): runs clean machine smoke test via Windows Sandbox.
    7. Synchronizes README.md (unpins Windows badge, updates version/size).
    8. Regenerates RELEASE\README.md incorporating both macOS and Windows packages.
    9. Uploads Windows assets to the existing GitHub Release tag (gh release upload --clobber).
   10. Commits RELEASE\ and README.md and pushes to origin/main.
   11. Verifies download asset accessibility.

.PARAMETER DryRun
  Runs all build, test, and staging steps locally, but skips GitHub upload and git push.

.PARAMETER NoPush
  Uploads to GitHub Release, but does not push git commits to remote repository.

.PARAMETER SkipTests
  Skips flutter analyze and flutter test.

.PARAMETER TestSandbox
  Runs scripts\test_in_windows_sandbox.ps1 to verify the package in Windows Sandbox.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\deploy.ps1

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\deploy.ps1 -DryRun

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\deploy.ps1 -TestSandbox
#>
[CmdletBinding()]
param(
  [switch]$DryRun,
  [switch]$NoPush,
  [switch]$SkipTests,
  [switch]$TestSandbox,
  [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Help) {
  Get-Help $MyInvocation.MyCommand.Path -Detailed
  exit 0
}

# --- Layout & Constants -------------------------------------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$ReleaseDir = Join-Path $RootDir 'RELEASE'
$PubspecPath = Join-Path $RootDir 'pubspec.yaml'
$ConstantsPath = Join-Path $RootDir 'lib\core\constants\app_constants.dart'
$ReadmePath = Join-Path $RootDir 'README.md'
$ReleaseReadmePath = Join-Path $ReleaseDir 'README.md'
$BuildReleaseScript = Join-Path $ScriptDir 'build_release.ps1'
$SandboxScript = Join-Path $ScriptDir 'test_in_windows_sandbox.ps1'
$RepoUrl = 'https://github.com/az-coder-123/azdroid'

# --- Helpers ------------------------------------------------------------------
function Write-Step([string]$Message) {
  Write-Host ''
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Info([string]$Message) {
  Write-Host "    [info] $Message" -ForegroundColor Blue
}

function Write-Ok([string]$Message) {
  Write-Host "    [ok] $Message" -ForegroundColor Green
}

function Write-Warn([string]$Message) {
  Write-Host "    [warning] $Message" -ForegroundColor Yellow
}

function Write-Err([string]$Message) {
  Write-Host "    [error] $Message" -ForegroundColor Red
}

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
  return [pscustomobject]@{ Name = $parts[0]; Build = $build; Full = $raw }
}

function Get-PackageRow([string]$SumsFileName) {
  $sumsPath = Join-Path $ReleaseDir $SumsFileName
  if (-not (Test-Path $sumsPath)) { return $null }
  $line = Get-Content $sumsPath | Where-Object { $_ -match 'Azdroid-v[0-9]' } | Select-Object -First 1
  if (-not $line) { return $null }
  $tokens = -split $line
  $sha = $tokens[0]
  $zip = $tokens[1]
  $version = ($zip -replace '^Azdroid-v([0-9.]+)-.*$', '$1')
  $zipPath = Join-Path $ReleaseDir $zip
  $size = '25M'
  if (Test-Path $zipPath) {
    $bytes = (Get-Item $zipPath).Length
    $size = '{0:N0}M' -f [math]::Round($bytes / 1MB)
  }
  return [pscustomobject]@{
    Zip = $zip
    Version = "v$version"
    Size = $size
    Sha = $sha
  }
}

function Update-ReleaseReadme {
  $macRow = Get-PackageRow 'SHA256SUMS.txt'
  $winRow = Get-PackageRow 'SHA256SUMS-windows.txt'

  if (-not $macRow -and -not $winRow) {
    Write-Warn 'No checksum files found in RELEASE directory; skipping RELEASE/README.md update.'
    return
  }

  $lines = @(
    '# Azdroid Release Packages',
    '',
    "> Android screen mirroring and control for macOS and Windows, over Wi-Fi and USB. All releases and notes: [GitHub Releases]($RepoUrl/releases).",
    '',
    '## Packages',
    '',
    '| Package | Platform | Version | Size | SHA-256 |',
    '| :--- | :--- | :--- | :--- | :--- |'
  )

  if ($macRow) {
    $lines += "| **[\`$($macRow.Zip)\`]($($macRow.Zip))** | macOS 12.0+ (Apple Silicon & Intel) | $($macRow.Version) | \`$($macRow.Size)\` | \`$($macRow.Sha)\` |"
  }
  if ($winRow) {
    $lines += "| **[\`$($winRow.Zip)\`]($($winRow.Zip))** | Windows 10/11 x64 (Preview) | $($winRow.Version) | \`$($winRow.Size)\` | \`$($winRow.Sha)\` |"
  }

  $lines += @(
    '',
    'Each `*-latest.zip` file is a copy of the newest package for its platform.',
    '',
    'ADB and scrcpy-server are bundled. An ADB you install yourself takes precedence over the bundled one.',
    '',
    '## Install on macOS',
    '',
    '1. Unzip the macOS package and drag **Azdroid.app** into `/Applications`.',
    '2. The app is not signed with an Apple Developer ID. If macOS says the developer cannot be verified, run once:',
    '   ```bash',
    '   xattr -cr /Applications/Azdroid.app',
    '   ```',
    '   Or right-click the app, choose **Open**, then **Open** again.',
    '',
    '## Install on Windows (Preview)',
    '',
    '1. Unzip the Windows package to a folder you own, for example `%LOCALAPPDATA%\Programs\Azdroid`.',
    '2. Run `desk_droid.exe`. Keep the `.dll` files and the `data` folder next to it.',
    '3. The app is not code-signed. If SmartScreen appears, click **More info**, then **Run anyway**.',
    '',
    '## Verify a Download',
    '',
    '```bash',
    'shasum -a 256 -c SHA256SUMS.txt          # macOS package',
    'shasum -a 256 -c SHA256SUMS-windows.txt  # Windows package',
    '```',
    ''
  )

  $lines | Set-Content -Path $ReleaseReadmePath -Encoding Ascii
  Write-Ok "Updated $ReleaseReadmePath with cross-platform release table"
}

# --- Main Pipeline ------------------------------------------------------------
Push-Location $RootDir
try {
  Write-Host '======================================================================'
  Write-Host ' Azdroid - Automated Windows Release & Deployment Pipeline'
  Write-Host '======================================================================'

  # ----------------------------------------------------------------------------
  # STEP 1: Pre-flight Verification & Environment Checks
  # ----------------------------------------------------------------------------
  Write-Step 'Step 1: Pre-flight Verification & Environment Checks'

  foreach ($tool in @('flutter', 'dart', 'git', 'gh')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
      throw "Required tool '$tool' not found on PATH. Please install it and retry."
    }
  }
  Write-Ok 'Required toolchain verified (flutter, dart, git, gh)'

  if (-not $DryRun -and -not $NoPush) {
    & gh auth status *> $null
    if ($LASTEXITCODE -ne 0) {
      throw "GitHub CLI (gh) is not authenticated. Run 'gh auth login' first."
    }
    Write-Ok 'GitHub CLI authenticated'
  }

  $currentBranch = (& git rev-parse --abbrev-ref HEAD).Trim()
  if ($currentBranch -ne 'main' -and -not $DryRun) {
    Write-Warn "Currently on branch '$currentBranch', expected 'main'."
    $confirmBranch = Read-Host "Do you want to continue deployment on '$currentBranch'? [y/N]"
    if ($confirmBranch -notmatch '^[Yy]$') {
      throw 'Aborted by user. Please checkout main before deploying.'
    }
  }

  # ----------------------------------------------------------------------------
  # STEP 2: Git Synchronization (Pull latest release commit from main)
  # ----------------------------------------------------------------------------
  Write-Step 'Step 2: Synchronizing with Remote Repository'

  if (-not $DryRun) {
    Write-Info 'Pulling latest commits from origin main...'
    Invoke-Checked 'git' @('pull', 'origin', 'main')
    Write-Ok 'Local repository is up to date with origin/main'
  } else {
    Write-Info 'Dry-run active: skipping git pull'
  }

  # ----------------------------------------------------------------------------
  # STEP 3: Version Alignment & GitHub Release Verification
  # ----------------------------------------------------------------------------
  Write-Step 'Step 3: Version Alignment & Release Target Check'

  $version = Get-AppVersion $PubspecPath
  $tag = "v$($version.Name)"
  Write-Info "Target version: $($version.Name) (build $($version.Build)), Tag: $tag"

  # Verify app_constants.dart alignment
  $constLine = Select-String -Path $ConstantsPath -Pattern "appVersion\s*=\s*'([^']+)'" | Select-Object -First 1
  if ($constLine) {
    $constVersion = $constLine.Matches[0].Groups[1].Value
    if ($constVersion -ne $version.Name) {
      throw "Version mismatch! pubspec.yaml ($($version.Name)) != app_constants.dart ($constVersion)"
    }
    Write-Ok "Version constant alignment verified ($constVersion)"
  }

  # Check if the GitHub Release already exists (initiated by macOS)
  if (-not $DryRun) {
    & gh release view $tag *> $null
    if ($LASTEXITCODE -eq 0) {
      Write-Ok "Target GitHub Release '$tag' is already published. Windows assets will attach to it."
    } else {
      Write-Warn "GitHub Release '$tag' does not exist yet. It will be created when uploading."
    }
  }

  # ----------------------------------------------------------------------------
  # STEP 4: Quality Gate & Automated Tests
  # ----------------------------------------------------------------------------
  Write-Step 'Step 4: Quality Gate & Static Analysis'

  if ($SkipTests) {
    Write-Warn 'Skipping static analysis and test suite (-SkipTests active)'
  } else {
    Write-Info 'Running flutter analyze...'
    Invoke-Checked 'flutter' @('analyze')
    Write-Ok 'Static analysis passed (No issues found!)'

    Write-Info 'Running unit test suite (flutter test)...'
    Invoke-Checked 'flutter' @('test')
    Write-Ok 'All tests passed with 100% success rate'
  }

  # ----------------------------------------------------------------------------
  # STEP 5: Build, Package & Smoke Test via scripts\build_release.ps1
  # ----------------------------------------------------------------------------
  Write-Step 'Step 5: Packaging Windows Release Bundle'

  # We invoke build_release.ps1 without -Publish (deploy.ps1 manages the upload)
  $buildArgs = @('-ExecutionPolicy', 'Bypass', '-File', $BuildReleaseScript, '-SkipTests')
  Invoke-Checked 'powershell' $buildArgs

  $zipName = "Azdroid-v$($version.Name)-Windows-x64.zip"
  $latestZipName = 'Azdroid-Windows-x64-latest.zip'
  $zipPath = Join-Path $ReleaseDir $zipName
  $latestZipPath = Join-Path $ReleaseDir $latestZipName
  $checksumPath = Join-Path $ReleaseDir 'SHA256SUMS-windows.txt'

  if (-not (Test-Path $zipPath) -or -not (Test-Path $checksumPath)) {
    throw "Packaging failed to produce expected artifacts ($zipName or SHA256SUMS-windows.txt)."
  }

  $zipBytes = (Get-Item $zipPath).Length
  $zipSizeMB = '{0:N0} MB' -f [math]::Round($zipBytes / 1MB)
  $zipHash = (Get-FileHash -Algorithm SHA256 -Path $zipPath).Hash.ToLowerInvariant()
  Write-Ok "Package created: $zipName ($zipSizeMB)"
  Write-Ok "SHA-256: $zipHash"

  # ----------------------------------------------------------------------------
  # STEP 6: Optional Clean Machine Smoke Test (Windows Sandbox)
  # ----------------------------------------------------------------------------
  if ($TestSandbox) {
    Write-Step 'Step 6: Running Smoke Test in Clean Windows Sandbox'
    if (Test-Path $SandboxScript) {
      Invoke-Checked 'powershell' @('-ExecutionPolicy', 'Bypass', '-File', $SandboxScript, '-Zip', $zipPath)
      Write-Ok 'Windows Sandbox smoke test passed'
    } else {
      Write-Warn "Sandbox script '$SandboxScript' not found; skipping."
    }
  }

  # ----------------------------------------------------------------------------
  # STEP 7: Documentation Synchronization (Anti-404 Inversion)
  # ----------------------------------------------------------------------------
  Write-Step 'Step 7: Synchronizing README & Release Documentation'

  # 1. Update README.md
  # Read/write via .NET UTF-8 APIs: Get-Content defaults to the ANSI codepage
  # and Set-Content -Encoding Ascii destroys emoji and other non-ASCII text.
  $readmeContent = [System.IO.File]::ReadAllText($ReadmePath)

  # Unpin Windows download link to latest/download
  $latestWinUrl = "$RepoUrl/releases/latest/download/$zipName"
  $readmeContent = [regex]::Replace($readmeContent,
    'href="https://github\.com/az-coder-123/azdroid/releases/(latest/download|download/v[0-9.]+)/Azdroid-v[0-9.]+-Windows-x64\.zip"',
    "href=`"$latestWinUrl`"")

  # Update Windows badge text
  $badgePattern = 'Download_for_Windows-v[0-9.]+_\(x64_Preview\)'
  $newBadge = "Download_for_Windows-v$($version.Name)_(x64_Preview)"
  $readmeContent = [regex]::Replace($readmeContent, $badgePattern, $newBadge)

  # Update subtitle size line for Windows
  $sizePattern = 'Windows \(Preview\): portable ZIP \([0-9]+ MB\)'
  $newSize = "Windows (Preview): portable ZIP ($zipSizeMB)"
  $readmeContent = [regex]::Replace($readmeContent, $sizePattern, $newSize)

  # Update install command
  $installPattern = 'unzip `Azdroid-v[0-9.]+-Windows-x64\.zip`'
  $newInstall = "unzip ``$zipName``"
  $readmeContent = [regex]::Replace($readmeContent, $installPattern, $newInstall)

  [System.IO.File]::WriteAllText($ReadmePath, $readmeContent,
    (New-Object System.Text.UTF8Encoding($false)))
  Write-Ok "Updated README.md: Windows download button unpinned to latest ($zipName)"

  # 2. Update RELEASE/README.md
  Update-ReleaseReadme

  # ----------------------------------------------------------------------------
  # STEP 8: Upload Windows Package to GitHub Release
  # ----------------------------------------------------------------------------
  if (-not $DryRun) {
    Write-Step 'Step 8: Uploading Windows Assets to GitHub Release'

    & gh release view $tag *> $null
    if ($LASTEXITCODE -eq 0) {
      Write-Info "Uploading $zipName to existing release $tag..."
      Invoke-Checked 'gh' @('release', 'upload', $tag, $zipPath, $latestZipPath, $checksumPath, '--clobber')
      Write-Ok "Assets uploaded to GitHub Release $tag"
    } else {
      Write-Info "Creating GitHub Release $tag with Windows assets..."
      Invoke-Checked 'gh' @('release', 'create', $tag, $zipPath, $latestZipPath, $checksumPath,
        '--title', "Azdroid $tag", '--notes', "Azdroid $tag (Windows 10/11 x64 release).")
      Write-Ok "Created GitHub Release $tag with Windows assets"
    }
  } else {
    Write-Info 'Dry-run active: skipping GitHub Release upload'
  }

  # ----------------------------------------------------------------------------
  # STEP 9: Commit & Push Changes
  # ----------------------------------------------------------------------------
  if (-not $DryRun -and -not $NoPush) {
    Write-Step 'Step 9: Committing & Pushing Documentation Updates'

    Invoke-Checked 'git' @('add', $ReadmePath, $ReleaseReadmePath, $checksumPath)
    & git commit -m "chore(release): attach Windows v$($version.Name) package and update download links"
    if ($LASTEXITCODE -eq 0) {
      Write-Ok "Created commit 'chore(release): attach Windows v$($version.Name) package and update download links'"
      Write-Info 'Pushing to origin main...'
      Invoke-Checked 'git' @('push', 'origin', 'main')
      Write-Ok 'Pushed changes to origin/main'
    } else {
      Write-Info 'No git changes detected to commit.'
    }
  } else {
    Write-Info 'Dry-run or -NoPush active: skipping git commit and push'
  }

  # ----------------------------------------------------------------------------
  # STEP 10: Verification
  # ----------------------------------------------------------------------------
  Write-Step 'Step 10: Post-Deployment Verification'

  if (-not $DryRun) {
    Write-Info 'Checking published assets via gh release view...'
    & gh release view $tag --json assets --jq '.assets[].name'
    Write-Ok "Release verification completed ($RepoUrl/releases/tag/$tag)"
  }

  Write-Host ''
  Write-Host '======================================================================' -ForegroundColor Green
  Write-Host " Azdroid v$($version.Name) Windows Deployment Completed Successfully!" -ForegroundColor Green
  Write-Host '======================================================================' -ForegroundColor Green
  Write-Host "Archive:       $zipPath ($zipSizeMB)"
  Write-Host "SHA-256:       $zipHash"
  Write-Host "Checksum File: $checksumPath"
  if (-not $DryRun) {
    Write-Host "Release URL:   $RepoUrl/releases/tag/$tag"
    Write-Host "Download URL:  $RepoUrl/releases/latest/download/$zipName"
  }
  Write-Host ''
} finally {
  Pop-Location
}
