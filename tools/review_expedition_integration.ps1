param(
    [string]$Godot = 'godot',
    [ValidateSet('Rendered', 'Journey', 'Cost', 'Validate')][string]$Phase = 'Rendered',
    [string]$RunLabel = (Get-Date -Format 'yyyyMMdd-HHmmss'),
    [string]$Only = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$git = 'C:/Program Files/Git/cmd/git.exe'
$engine = (Get-Command $Godot -CommandType Application -ErrorAction Stop).Source
$version = (& $engine --version | Out-String).Trim()
if ($version -notmatch '^4\.7\.2\.stable\.') { throw "Expected Godot 4.7.2; got $version" }
if ($RunLabel -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Invalid run label' }
$renderEngine = $engine.Replace('_console.exe', '.exe')
if (-not (Test-Path -LiteralPath $renderEngine)) { throw 'Rendered executable missing' }
$destination = Join-Path $projectRoot "artifacts/integration_readiness/$RunLabel/$Phase"
if (Test-Path -LiteralPath "$destination/manifest.json") { throw 'Use a fresh run label; prior evidence is preserved' }
New-Item -ItemType Directory -Path $destination -Force | Out-Null
function Get-SourceFingerprint {
    $paths = @(& $git -C $projectRoot ls-files --cached --others --exclude-standard) | Sort-Object -Unique
    if ($LASTEXITCODE -ne 0) { throw 'Cannot enumerate source files' }
    $hashes = [ordered]@{}
    foreach ($path in $paths) {
        if ($path -notmatch '^(assets|scripts|resources|scenes|shaders|tests|tools)/|^project\.godot$') { continue }
        $absolute = Join-Path $projectRoot $path
        $hashes[$path] = if (Test-Path -LiteralPath $absolute -PathType Leaf) { (Get-FileHash -LiteralPath $absolute -Algorithm SHA256).Hash } else { 'DELETED' }
    }
    return $hashes
}
$cases = @(
    @{name='presentation'; script='tests/presentation.gd'; flags=@()},
    @{name='controller'; script='tests/controller_expedition.gd'; flags=@('--capture-controller')},
    @{name='inspection'; script='tests/inspection_card.gd'; flags=@('--capture-inspection')},
    @{name='large_text'; script='tests/ui_playtest_blockers.gd'; flags=@('--capture-blockers')},
    @{name='fog'; script='tests/fog_horizon.gd'; flags=@('--capture-fog')},
    @{name='view'; script='tests/view_3d.gd'; flags=@('--capture-view')},
    @{name='outcomes'; script='tests/combat_consequences.gd'; flags=@('--capture-consequences')},
    @{name='catalog'; script='tests/sol_species_catalog.gd'; flags=@('--capture')},
    @{name='following'; script='tests/owned_companion.gd'; flags=@('--companion-capture')},
    @{name='air_water'; script='tests/sol_air_water.gd'; flags=@('--capture')},
    @{name='terrain'; script='tests/terrain_integration.gd'; flags=@()},
    @{name='pacing'; script='tests/combat_pacing.gd'; flags=@()}
)
if ($Phase -eq 'Journey') { $cases = @(@{name='connected'; script='tools/review_connected_expedition.gd'; flags=@("--output=res://artifacts/integration_readiness/$RunLabel/Journey/connected", '--cap=60')}) }
if ($Phase -eq 'Cost') { $cases = @(@{name='connected_cost'; script='tools/review_reformat_cost.gd'; flags=@("--output=res://artifacts/integration_readiness/$RunLabel/Cost/connected_cost", '--cap=60')}) }
if ($Phase -eq 'Validate') { $cases = @(@{name='shared_validator'; script='tools/validate.ps1'; flags=@()}) }
if ($Only) { $cases = @($cases | Where-Object { $_.name -eq $Only }); if ($cases.Count -eq 0) { throw "Unknown case $Only" } }
$manifest = [ordered]@{
    started_utc = (Get-Date).ToUniversalTime().ToString('o')
    phase = $Phase
    engine = $version
    branch = (& $git -C $projectRoot branch --show-current | Out-String).Trim()
    base_commit = (& $git -C $projectRoot rev-parse HEAD | Out-String).Trim()
    status = @(& $git -C $projectRoot status --porcelain)
    cpu = (Get-CimInstance Win32_Processor | Select-Object -ExpandProperty Name)
    gpu = @(Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion)
    system_memory_bytes = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
    background_editor_processes = @(Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" | Where-Object { $_.CommandLine -match '(^|\s)--editor(\s|$)' } | Select-Object ProcessId,Name,CommandLine)
    method = 'Sequential automated desktop checks. Normal journey and controlled fixtures are labelled separately. No owner, physical controller, export or Thor acceptance.'
    source_before = Get-SourceFingerprint
    cases = @()
}
$manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath "$destination/manifest.json" -Encoding utf8
foreach ($case in $cases) {
    $otherRuns = @(Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" | Where-Object { $_.CommandLine -notmatch '(^|\s)--editor(\s|$)' })
    if ($otherRuns.Count) { throw 'A non-editor Godot process is already running; avoid competing tests/profiling' }
    $caseDirectory = Join-Path $destination $case.name
    New-Item -ItemType Directory -Path $caseDirectory -Force | Out-Null
    $before = Get-SourceFingerprint
    $before | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath "$caseDirectory/source_before.json" -Encoding utf8
    $arguments = @('--path', ('"' + $projectRoot + '"'), '--rendering-driver', 'd3d12', '--log-file', ('"' + "$caseDirectory/engine.log" + '"'), '--script', $case.script)
    if ($case.flags.Count) { $arguments += @('--') + $case.flags }
    $executable = $renderEngine
    if ($Phase -eq 'Validate') {
        $executable = (Get-Process -Id $PID).Path
        $arguments = @('-NoProfile', '-File', ('"' + "$projectRoot/tools/validate.ps1" + '"'), '-Godot', ('"' + $engine + '"'))
    }
    $started = Get-Date
    $process = Start-Process -FilePath $executable -ArgumentList $arguments -WorkingDirectory $projectRoot -WindowStyle Hidden -RedirectStandardOutput "$caseDirectory/stdout.log" -RedirectStandardError "$caseDirectory/stderr.log" -PassThru
    $null = $process.Handle
    $peak = 0L
    $timedOut = $false
    while (-not $process.HasExited) {
        $process.Refresh()
        $peak = [Math]::Max($peak, $process.PeakWorkingSet64)
        if (((Get-Date) - $started).TotalSeconds -gt 600) { $timedOut = $true; $process.Kill($true); break }
        Start-Sleep -Milliseconds 200
    }
    $process.WaitForExit()
    $exitCode = $process.ExitCode
    if ($null -eq $exitCode) { throw 'Cannot determine process exit status' }
    $after = Get-SourceFingerprint
    $after | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath "$caseDirectory/source_after.json" -Encoding utf8
    $lines = @(Get-Content "$caseDirectory/stdout.log") + @(Get-Content "$caseDirectory/stderr.log")
    $errors = @($lines | Where-Object { $_ -match '^(SCRIPT ERROR|ERROR):' })
    $summaries = @($lines | Where-Object { $_ -match 'checks, \d+ failures|CURRENT EXPEDITION:|CONNECTED EXPEDITION:|Import, geometry' })
    $entry = [ordered]@{name=$case.name; script=$case.script; executable=$executable; arguments=$arguments; started_utc=$started.ToUniversalTime().ToString('o'); elapsed_seconds=((Get-Date)-$started).TotalSeconds; exit_code=$exitCode; timed_out=$timedOut; engine_errors=$errors; summary=$summaries; sampled_process_peak_working_set_bytes=$peak; source_changed=((ConvertTo-Json $before -Compress) -cne (ConvertTo-Json $after -Compress))}
    $manifest.cases += $entry
    $manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath "$destination/manifest.json" -Encoding utf8
    Write-Output "$($case.name): exit $exitCode; errors $($errors.Count); source changed $($entry.source_changed)"
    $summaries | Write-Output
    $process.Dispose()
}
$manifest.source_after = Get-SourceFingerprint
$manifest.source_changed = (ConvertTo-Json $manifest.source_before -Compress) -cne (ConvertTo-Json $manifest.source_after -Compress)
$manifest.completed_utc = (Get-Date).ToUniversalTime().ToString('o')
$manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath "$destination/manifest.json" -Encoding utf8
Write-Output "Evidence: $destination"
if (@($manifest.cases | Where-Object { $_.exit_code -ne 0 -or $_.timed_out -or $_.engine_errors.Count -or $_.source_changed }).Count -or $manifest.source_changed) { exit 1 }
exit 0
