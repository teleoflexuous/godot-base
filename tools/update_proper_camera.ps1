param(
    [Parameter(Mandatory)]
    [string]$SourceRoot
)

$ErrorActionPreference = "Stop"
$baseRoot = Split-Path -Parent $PSScriptRoot
$sourceRootPath = (Resolve-Path -LiteralPath $SourceRoot).Path
$sourceAddon = Join-Path $sourceRootPath "addons\proper_camera"
$destination = Join-Path $baseRoot "addons\proper_camera"

if (-not (Test-Path -LiteralPath $sourceAddon -PathType Container)) {
    throw "SourceRoot must contain addons/proper_camera: $sourceRootPath"
}
if ((Split-Path -Leaf $destination) -ne "proper_camera") {
    throw "Refusing to replace an unexpected destination: $destination"
}

$commit = (& git -C $sourceRootPath rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $commit -notmatch "^[0-9a-f]{40}$") {
    throw "Could not resolve the canonical ProperCamera commit."
}

if (Test-Path -LiteralPath $destination) {
    Remove-Item -LiteralPath $destination -Recurse -Force
}
Copy-Item -LiteralPath $sourceAddon -Destination (Join-Path $baseRoot "addons") -Recurse -Force

$manifest = Get-Content -LiteralPath (Join-Path $destination "proper_camera_manifest.json") -Raw | ConvertFrom-Json
@(
    "repository=https://github.com/teleoflexuous/GodotCamera.git"
    "commit=$commit"
    "addon_path=addons/proper_camera"
    "version=$($manifest.version)"
    "license=MIT"
) | Set-Content -LiteralPath (Join-Path $baseRoot "third_party\proper_camera.lock")

Write-Output "Vendored ProperCamera $commit into $destination"
