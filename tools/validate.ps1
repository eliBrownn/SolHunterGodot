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
    Write-Host "Validating with Godot $version"

    & $engine --headless --path $projectRoot --editor --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }

    foreach ($suite in @('tests/smoke.gd', 'tests/world_generation.gd', 'tests/solid_geometry.gd', 'tests/building_collision.gd')) {
        Write-Host "Running $suite"
        & $engine --headless --path $projectRoot --script $suite
        if ($LASTEXITCODE -ne 0) { throw "Validation failed: $suite" }
    }
    Write-Host 'Running smoke journey against solid 3D scene'
    & $engine --headless --path $projectRoot --script tests/smoke.gd -- --scene=res://scenes/world_3d.tscn
    if ($LASTEXITCODE -ne 0) { throw 'Solid 3D journey validation failed.' }
    Write-Host 'Import, geometry, generation and both scene journeys passed.'
    exit 0
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
