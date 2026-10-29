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

    Write-Host 'Running tests/combat_action_budget.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/combat_action_budget.gd')
    Write-Host 'Running tests/early_combat_moves.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/early_combat_moves.gd')

    foreach ($suite in @('tests/smoke.gd', 'tests/world_generation.gd', 'tests/solid_geometry.gd', 'tests/building_collision.gd', 'tests/presentation.gd', 'tests/persistent_foundation.gd', 'tests/human_vastra_activity.gd', 'tests/vastra_natural.gd', 'tests/vastra_integration.gd', 'tests/vastra_currents.gd', 'tests/population_summary.gd', 'tests/inspector_tuning.gd', 'tests/authored_sightings.gd', 'tests/sol_observation.gd', 'tests/local_sol_reactions.gd', 'tests/encounter_initiation.gd', 'tests/first_playable_battle.gd', 'tests/sol_orbs.gd', 'tests/affinity_moves.gd', 'tests/battle_feedback.gd', 'tests/wild_population_recovery.gd')) {
        Write-Host "Running $suite"
        Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', $suite)
        if ($LASTEXITCODE -ne 0) { throw "Validation failed: $suite" }
    }
    Write-Host 'Running tests/sol_wandering.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_wandering.gd')
    Write-Host 'Running tests/sol_player_reactions.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_player_reactions.gd')
    Write-Host 'Running tests/sol_species_catalog.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_species_catalog.gd')
    Write-Host 'Running tests/sol_creature_models.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_creature_models.gd')
    Write-Host 'Running tests/sol_creature_fallback.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_creature_fallback.gd')
    Write-Host 'Running tests/sol_anatomy_batch.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_anatomy_batch.gd')
    Write-Host 'Running tests/sol_anatomy_integration.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_anatomy_integration.gd', '--', '--species=sol_species_0008,sol_species_0011,sol_species_0012,sol_species_0013')
    Write-Host 'Running tests/sol_class_coverage.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_class_coverage.gd')
    Write-Host 'Running tests/sol_procedural_ground.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_procedural_ground.gd')
    Write-Host 'Running tests/sol_air_water.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_air_water.gd')
    Write-Host 'Running tests/sol_ecology.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_ecology.gd')
    Write-Host 'Running tests/sol_behavior_hierarchy.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_behavior_hierarchy.gd')
    Write-Host 'Running tests/owned_companion.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/owned_companion.gd')
    Write-Host 'Running tests/owned_companion_traversal.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/owned_companion_traversal.gd')
    Write-Host 'Running tests/sol_game_rollout.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_game_rollout.gd')
    Write-Host 'Running tests/sol_natural_movement.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_natural_movement.gd')
    Write-Host 'Running tests/sol_activity.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_activity.gd')
    Write-Host 'Running tests/ai_seals_progression.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/ai_seals_progression.gd')
    Write-Host 'Running tests/sol_stats_and_classes.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_stats_and_classes.gd')
    Write-Host 'Running tests/combat_polish.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/combat_polish.gd')
    Write-Host 'Running tests/combat_sequencing.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/combat_sequencing.gd')
    Write-Host 'Running tests/combat_consequences.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/combat_consequences.gd')
    Write-Host 'Running tests/combat_pacing.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/combat_pacing.gd')
    Write-Host 'Running tests/inspection_card.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/inspection_card.gd')
    Write-Host 'Running tests/ui_playtest_blockers.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/ui_playtest_blockers.gd')
    Write-Host 'Running tests/controller_expedition.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/controller_expedition.gd')
    Write-Host 'Running tests/connected_polish.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/connected_polish.gd')
    Write-Host 'Running tests/world_interactions.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/world_interactions.gd')
    Write-Host 'Running tests/mouse_first_ui.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/mouse_first_ui.gd')
    Write-Host 'Running tests/mouse_controls.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/mouse_controls.gd')
    Write-Host 'Running tests/running.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/running.gd')
    Write-Host 'Running tests/full_3d.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/full_3d.gd')
    Write-Host 'Running tests/wilderness_presentation.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/wilderness_presentation.gd')
    Write-Host 'Running tests/view_3d.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/view_3d.gd')
    Write-Host 'Running tests/runtime_optimization.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/runtime_optimization.gd')
    Write-Host 'Running tests/runtime_hot_paths.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/runtime_hot_paths.gd')
    Write-Host 'Running tests/stutter_regressions.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/stutter_regressions.gd')
    Write-Host 'Running tests/fog_horizon.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/fog_horizon.gd')
    Write-Host 'Running tests/atmosphere.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/atmosphere.gd')
    Write-Host 'Running tests/live_menu_window.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/live_menu_window.gd')
    Write-Host 'Running tests/sol_menu.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/sol_menu.gd')
    Write-Host 'Running tests/field_menu.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/field_menu.gd')
    Write-Host 'Running tests/nature_composition.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/nature_composition.gd')
    Write-Host 'Running tests/scenery_sites.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/scenery_sites.gd')
    Write-Host 'Running tests/terrain_heightfield.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/terrain_heightfield.gd')
    Write-Host 'Running tests/terrain_integration.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/terrain_integration.gd')
    Write-Host 'Running tests/terrain_geography.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/terrain_geography.gd')
    Write-Host 'Running tests/water_shoreline.gd'
    Invoke-CheckedGodot @('--headless', '--path', $projectRoot, '--script', 'tests/water_shoreline.gd')
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
