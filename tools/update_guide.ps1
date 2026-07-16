param(
  [Parameter(Mandatory = $true)] [string]$Version
)

$ErrorActionPreference = 'Stop'
$normalizedVersion = $Version.TrimStart('v')
$archive = Join-Path $env:TEMP "guide-$normalizedVersion.zip"
$extractRoot = Join-Path $env:TEMP "guide-$normalizedVersion"
if (Test-Path $archive) { Remove-Item -LiteralPath $archive -Force }
if (Test-Path $extractRoot) { Remove-Item -LiteralPath $extractRoot -Recurse -Force }
Invoke-WebRequest "https://github.com/godotneers/G.U.I.D.E/archive/refs/tags/v$normalizedVersion.zip" -OutFile $archive
Expand-Archive -LiteralPath $archive -DestinationPath $extractRoot
$source = Get-ChildItem -LiteralPath $extractRoot -Directory | Select-Object -First 1
if ($null -eq $source -or -not (Test-Path (Join-Path $source.FullName 'addons/guide'))) { throw 'G.U.I.D.E archive did not contain addons/guide.' }
if (Test-Path 'addons/guide') { Remove-Item -LiteralPath 'addons/guide' -Recurse -Force }
Copy-Item -LiteralPath (Join-Path $source.FullName 'addons/guide') -Destination 'addons/guide' -Recurse
$commit = (git ls-remote --tags https://github.com/godotneers/G.U.I.D.E.git "v$normalizedVersion" | Select-Object -First 1).Split("`t")[0]
@("version=v$normalizedVersion", "commit=$commit", 'source=https://github.com/godotneers/G.U.I.D.E') | Set-Content -LiteralPath 'third_party/guide.lock'
