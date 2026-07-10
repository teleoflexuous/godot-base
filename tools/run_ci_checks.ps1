[CmdletBinding()]
param(
	[string] $GodotBin = $env:GODOT_BIN
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($GodotBin)) {
	$command = Get-Command godot -ErrorAction Stop
	$GodotBin = $command.Source
}

$runningOnWindows = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
if ($runningOnWindows -and [System.IO.Path]::GetFileNameWithoutExtension($GodotBin) -notlike "*_console") {
	throw "GODOT_BIN must point to Godot's *_console.exe on Windows. The GUI executable can return before a headless check finishes."
}

function Invoke-GodotCheck {
	param([string[]] $Arguments)

	& $GodotBin @Arguments
	if ($LASTEXITCODE -ne 0) {
		exit $LASTEXITCODE
	}
}

$artifactsDirectory = Join-Path $PSScriptRoot "../artifacts"
New-Item -ItemType Directory -Path $artifactsDirectory -Force | Out-Null
$importLog = Join-Path $artifactsDirectory "godot-ci-import.log"
Invoke-GodotCheck @("--headless", "--log-file", $importLog, "--path", ".", "--import")
$importOutput = Get-Content -LiteralPath $importLog -Raw
if ($importOutput -match "(?m)(^SCRIPT ERROR:|Parse Error:|^ERROR: Failed to load script|^ERROR: Failed to instantiate an autoload|^ERROR: Error loading extension|^ERROR: Can't open GDExtension dynamic library)") {
	throw "Godot import reported script, autoload, or extension errors. See $importLog."
}

$preflightLog = Join-Path $artifactsDirectory "godot-ci-preflight.log"
$gutLog = Join-Path $artifactsDirectory "godot-ci-gut.log"
Invoke-GodotCheck @("--headless", "--log-file", $preflightLog, "--path", ".", "-s", "res://tools/run_gdscript_warning_preflight.gd")
Invoke-GodotCheck @("--headless", "--log-file", $gutLog, "--path", ".", "-s", "res://addons/gut/gut_cmdln.gd", "-gdir=res://tests/unit,res://tests/integration", "-ginclude_subdirs", "-gexit")

$webBuildDirectory = Join-Path $artifactsDirectory "web-ci"
$webExportLog = Join-Path $artifactsDirectory "godot-ci-web-export.log"
if (Test-Path -LiteralPath $webBuildDirectory) {
	Remove-Item -LiteralPath $webBuildDirectory -Recurse -Force
}
New-Item -ItemType Directory -Path $webBuildDirectory -Force | Out-Null

Invoke-GodotCheck @("--headless", "--log-file", $webExportLog, "--path", ".", "--export-release", "Web", (Join-Path $webBuildDirectory "index.html"))
$webExportOutput = Get-Content -LiteralPath $webExportLog -Raw
if ($webExportOutput -match "(?m)(^SCRIPT ERROR:|Parse Error:|^ERROR: Failed to load script|^ERROR: Error loading extension|^ERROR: Can.t open GDExtension dynamic library)") {
	throw "Godot web export reported script or extension errors. See $webExportLog."
}

foreach ($requiredFile in @("index.html", "index.js", "index.pck", "index.wasm", "GameAnalytics.js", "libGodotGameAnalytics.wasm")) {
	$requiredPath = Join-Path $webBuildDirectory $requiredFile
	if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
		throw "Missing exported web file: $requiredPath"
	}
}
