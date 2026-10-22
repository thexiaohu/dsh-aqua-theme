# Aqua installer for DeepSeek Harness 0.2.x
#
# Registers the Aqua glass theme with a DSH profile:
#   1. resolve the package source (local folder, or a fresh download if absent)
#   2. junction it into <profile>/node_modules/@deepseek-ai/dsh-client-ui-aqua
#   3. add it to <profile>/package.json -> dependencies
#   4. add it to <profile>/package.json -> dsh.profile.bundles
#
# Steps 3-4 are what the loader actually reads (dsh-app-boot's
# loadProfileDirectory). Writing cordis.patch.yml alone does NOT work: the
# loader reads package.json first and fails when it is missing.
#
# IMPORTANT: an existing install is NEVER overwritten. If the package is already
# present locally, that copy is linked as-is, so local edits to lib/client.js
# survive re-running this script. Pass -Force to re-download on purpose.
#
# Usage (from any directory):
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
#
# Options:
#   -Source   repo URL, or a local folder path (junction link, live reload)
#   -Version  'latest' (newest GitHub Release, falls back to main), a tag, or a branch
#   -DshHome  DSH home, defaults to $env:DSH_HOME or %USERPROFILE%\.dsh
#   -Profile  profile name; defaults to 'desktop' (the Electron desktop app).
#             Use 'web' for the browser-only build.
#   -Force    re-download even when a local copy already exists
#
# Re-running is safe (idempotent).

param(
    [string]$Source = 'https://github.com/thexiaohu/dsh-aqua-theme',
    [string]$Version = 'latest',
    [string]$DshHome = $env:DSH_HOME,
    [string]$Profile = 'desktop',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (-not $DshHome) { $DshHome = Join-Path $env:USERPROFILE '.dsh' }
if (-not (Test-Path $DshHome)) { throw "DSH home not found: $DshHome (override with -DshHome)" }

$pluginName  = 'dsh-aqua-theme'
$profilesDir = Join-Path $DshHome 'profiles'
$profileDir  = Join-Path $profilesDir $Profile
$nodeModules = Join-Path $profileDir 'node_modules'
$linkPath    = Join-Path $nodeModules $pluginName
$pluginsDir  = Join-Path $DshHome 'plugins'
$installDir  = Join-Path $pluginsDir $pluginName
$manifestPath = Join-Path $profileDir 'package.json'

# ---------- 0. sanity ----------
if (-not (Test-Path $profileDir)) {
    $available = @()
    if (Test-Path $profilesDir) {
        $available = Get-ChildItem $profilesDir -Directory | Select-Object -ExpandProperty Name
    }
    throw "Profile '$Profile' not found at $profileDir. Available profiles: $($available -join ', '). Pass -Profile <name>."
}

# ---------- 1. source ----------
Write-Host '[1/4] Resolving plugin source...' -ForegroundColor Cyan
$isRemote = $Source -match '^(https?://|git@|ssh://|github:)'

$localCopyOk = (Test-Path (Join-Path $installDir 'lib\client.js')) -and
               (Test-Path (Join-Path $installDir 'package.json'))

if ($localCopyOk -and -not $Force) {
    # Existing install wins -- never clobber the user's edits.
    Write-Host "  using the existing copy at $installDir (no download, edits preserved)"
    $src = $installDir
} elseif ($isRemote) {
    $repoUrl = $Source.TrimEnd('/') -replace '\.git$', ''

    # Resolve the ref: 'latest' -> newest release tag, else tag/branch as given.
    $ref = $Version
    $isTag = $ref -match '^v\d+\.\d+'
    if ($ref -eq 'latest' -and $repoUrl -match '^https?://github\.com/([^/]+/[^/]+)') {
        $slug = $Matches[1]
        try {
            $latest = Invoke-RestMethod -Uri "https://api.github.com/repos/$slug/releases/latest" -Headers @{ 'User-Agent' = 'dsh-aqua-installer' } -TimeoutSec 15
            if ($latest.tag_name) {
                $ref = $latest.tag_name
                $isTag = $true
                Write-Host "  latest release: $ref"
            }
        } catch {
            Write-Host '  (no release found, using the main branch)'
            $ref = 'main'
            $isTag = $false
        }
    }

    # Zip first (plain HTTP is more reliable than the git protocol), git as fallback.
    $refKind    = if ($isTag) { 'tags' } else { 'heads' }
    $zipUrl     = "$repoUrl/archive/refs/$refKind/$ref.zip"
    $zipFile    = Join-Path $pluginsDir 'aqua-plugin.zip'
    $extractDir = Join-Path $pluginsDir 'aqua-plugin-extract'
    New-Item -ItemType Directory -Force -Path $pluginsDir | Out-Null

    $gotSource = $false
    try {
        Write-Host "  downloading $zipUrl"
        Invoke-WebRequest $zipUrl -OutFile $zipFile -UseBasicParsing
        if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
        Expand-Archive $zipFile -DestinationPath $extractDir -Force
        $inner = Get-ChildItem $extractDir -Directory | Select-Object -First 1
        if (-not $inner) { throw "zip contains no package directory: $zipUrl" }
        # Only reached when there was no local copy, or -Force was passed.
        if (Test-Path $installDir) { Remove-Item $installDir -Recurse -Force }
        New-Item -ItemType Directory -Force -Path (Split-Path $installDir -Parent) | Out-Null
        Move-Item $inner.FullName $installDir
        Remove-Item $zipFile -Force
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
        $gotSource = $true
    } catch {
        Write-Host '  zip download failed, trying git clone...' -ForegroundColor Yellow
    }

    if (-not $gotSource) {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            throw 'download failed: zip unavailable and git is not installed'
        }
        if (Test-Path $installDir) { Remove-Item $installDir -Recurse -Force }
        git clone --depth 1 --branch $ref $repoUrl $installDir | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "git clone failed for $repoUrl ($ref)" }
    }
    $src = $installDir
} else {
    $src = (Resolve-Path $Source).Path
}

if (-not (Test-Path (Join-Path $src 'lib\client.js'))) {
    throw "lib\client.js not found in '$src' - the package must include the pre-built bundle."
}
if (-not (Test-Path (Join-Path $src 'package.json'))) {
    throw "package.json not found in '$src'."
}

# ---------- 2. junction ----------
Write-Host "[2/4] Linking -> $linkPath" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $nodeModules | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $linkPath -Parent) | Out-Null
if (Test-Path $linkPath) {
    $item = Get-Item $linkPath -Force
    if ($item.LinkType) {
        # Delete the link itself, never its target.
        [System.IO.Directory]::Delete($linkPath)
    } else {
        Remove-Item $linkPath -Force -Recurse
    }
}
New-Item -ItemType Junction -Path $linkPath -Target $src | Out-Null
if (-not (Test-Path $linkPath)) { throw 'junction creation failed' }

# ---------- 3. package.json: dependencies + dsh.profile.bundles ----------
Write-Host "[3/4] Registering in $manifestPath" -ForegroundColor Cyan
if (-not (Test-Path $manifestPath)) {
    throw "profile manifest missing: $manifestPath (this profile was never initialised by DSH)"
}
$raw = Get-Content $manifestPath -Raw
try { $manifest = $raw | ConvertFrom-Json } catch { throw "cannot parse $manifestPath : $($_.Exception.Message)" }

# dependency spec: relative link keeps the package outside the profile
$depSpec = "link:../../plugins/$pluginName"

$deps = $manifest.dependencies
if ($null -eq $deps) {
    $manifest | Add-Member -NotePropertyName dependencies -NotePropertyValue ([pscustomobject]@{}) -Force
    $deps = $manifest.dependencies
}
$existingDep = $deps.PSObject.Properties[$pluginName]
if ($existingDep) {
    Write-Host "  dependency already present: $($existingDep.Value)"
} else {
    $deps | Add-Member -NotePropertyName $pluginName -NotePropertyValue $depSpec -Force
    Write-Host "  added dependency: $depSpec"
}

# bundles list
if ($null -eq $manifest.dsh) {
    $manifest | Add-Member -NotePropertyName dsh -NotePropertyValue ([pscustomobject]@{}) -Force
}
if ($null -eq $manifest.dsh.profile) {
    $manifest.dsh | Add-Member -NotePropertyName profile -NotePropertyValue ([pscustomobject]@{}) -Force
}
$bundles = @($manifest.dsh.profile.bundles | Where-Object { $_ })
if ($bundles -contains $pluginName) {
    Write-Host '  bundle already listed'
} else {
    $bundles = @($bundles) + $pluginName
    $manifest.dsh.profile | Add-Member -NotePropertyName bundles -NotePropertyValue $bundles -Force
    Write-Host "  added to dsh.profile.bundles (now $($bundles.Count) entries)"
}

# Write back the way DSH does it: JSON.stringify(value, null, 2).
# PowerShell's ConvertTo-Json uses its own spacing (and pads with runs of
# spaces), so the manifest is re-serialised by a tiny JS helper through node
# when available, and reformatted in-place otherwise.
function Format-Json2Space([string]$json) {
    $out = New-Object System.Text.StringBuilder
    $indent = 0
    $inString = $false
    $escaped = $false
    for ($i = 0; $i -lt $json.Length; $i++) {
        $ch = $json[$i]
        if ($inString) {
            [void]$out.Append($ch)
            if ($escaped) { $escaped = $false }
            elseif ($ch -eq '\') { $escaped = $true }
            elseif ($ch -eq '"') { $inString = $false }
            continue
        }
        switch ($ch) {
            '"' { $inString = $true; [void]$out.Append($ch) }
            '{' { [void]$out.Append("{"); $indent++; [void]$out.Append("`n" + (' ' * ($indent * 2))) }
            '[' { [void]$out.Append("["); $indent++; [void]$out.Append("`n" + (' ' * ($indent * 2))) }
            '}' {
                $indent--
                [void]$out.Append("`n" + (' ' * ($indent * 2)) + "}")
            }
            ']' {
                $indent--
                [void]$out.Append("`n" + (' ' * ($indent * 2)) + "]")
            }
            ',' { [void]$out.Append(","); [void]$out.Append("`n" + (' ' * ($indent * 2))) }
            ':' { [void]$out.Append(": ") }
            default {
                if (-not [char]::IsWhiteSpace($ch)) { [void]$out.Append($ch) }
            }
        }
    }
    return $out.ToString()
}

$json = Format-Json2Space (($manifest | ConvertTo-Json -Depth 20 -Compress))
[System.IO.File]::WriteAllText($manifestPath, $json + "`n", (New-Object System.Text.UTF8Encoding $false))

# ---------- 4. verify ----------
Write-Host '[4/4] Verifying...' -ForegroundColor Cyan
$check = Get-Content $manifestPath -Raw | ConvertFrom-Json
$okDep = $null -ne $check.dependencies.PSObject.Properties[$pluginName]
$okBundle = @($check.dsh.profile.bundles) -contains $pluginName
$okLink = Test-Path $linkPath
$okBundleFile = Test-Path (Join-Path $linkPath 'lib\client.js')

if (-not ($okDep -and $okBundle -and $okLink -and $okBundleFile)) {
    throw "verification failed: dependency=$okDep bundle=$okBundle link=$okLink client.js=$okBundleFile"
}

Write-Host ''
Write-Host 'Installed.' -ForegroundColor Green
Write-Host "  package : $src"
Write-Host "  link    : $linkPath"
Write-Host "  profile : $profileDir"
Write-Host ''
Write-Host 'Restart DSH (fully quit and relaunch), then open Settings -> General -> Appearance.' -ForegroundColor Yellow
Write-Host 'Aqua is on by default; the theme controls sit under "Theme settings".'
