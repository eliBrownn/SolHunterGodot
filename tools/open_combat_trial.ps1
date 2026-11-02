param([string]$Godot = 'godot')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$command = Get-Command $Godot -CommandType Application -ErrorAction SilentlyContinue
if ($command) {
    $engine = $command.Source
} else {
    $engine = Join-Path $env:USERPROFILE 'Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
    if (-not (Test-Path -LiteralPath $engine)) { throw 'Pass -Godot with the path to Godot 4.7.2.' }
}
& $engine --path $projectRoot --rendering-driver d3d12 res://scenes/realtime_combat_trial.tscn
exit $LASTEXITCODE
