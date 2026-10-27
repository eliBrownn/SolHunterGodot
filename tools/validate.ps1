param(
    [string]$Godot = 'godot'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

try {
    $engine = (Get-Command $Godot -CommandType Application -ErrorAction Stop).Source
    $version = (& $engine --version | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $version -notmatch '^4\.7\.2\.stable\.') {
        throw "Expected Godot 4.7.2 stable; received '$version'."
    }
    function Invoke-CheckedGodot([string[]] $EngineArguments) {
        $savedPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $engineOutput = @(& $engine @EngineArguments 2>&1)
            $engineExit = $LASTEXITCODE
        } finally { $ErrorActionPreference = $savedPreference }
        foreach ($line in $engineOutput) { Write-Host $line }
        if ($engineExit -ne 0 -or ($engineOutput | Where-Object { $_.ToString() -match '^(SCRIPT ERROR|ERROR):' })) {
            throw 'Godot reported an engine/script error or a nonzero exit code.'
        }
    }
    Write-Host "Validating with Godot $version"

    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--editor', '--import', '--quit')
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }

    foreach ($suite in @('tests/smoke.gd', 'tests/world_generation.gd', 'tests/solid_geometry.gd', 'tests/building_collision.gd', 'tests/presentation.gd', 'tests/persistent_foundation.gd', 'tests/human_vastra_activity.gd', 'tests/vastra_natural.gd', 'tests/population_summary.gd', 'tests/inspector_tuning.gd', 'tests/authored_sightings.gd', 'tests/sol_observation.gd', 'tests/local_sol_reactions.gd', 'tests/encounter_initiation.gd', 'tests/first_playable_battle.gd', 'tests/sol_orbs.gd', 'tests/affinity_moves.gd', 'tests/battle_feedback.gd')) {
        Write-Host "Running $suite"
        Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', $suite)
        if ($LASTEXITCODE -ne 0) { throw "Validation failed: $suite" }
    }
    Write-Host 'Running smoke journey against solid 3D scene'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/smoke.gd', '--', '--scene=res://scenes/world_3d.tscn')
    if ($LASTEXITCODE -ne 0) { throw 'Solid 3D journey validation failed.' }
    Write-Host 'Import, geometry, generation and both scene journeys passed.'
    exit 0
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
