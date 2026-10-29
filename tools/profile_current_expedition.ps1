param(
    [string]$Godot = 'godot',
    [int]$Repeats = 3,
    [string]$RunLabel = (Get-Date -Format 'yyyyMMdd-HHmmss'),
    [switch]$ContactStudy
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$git = 'C:/Program Files/Git/cmd/git.exe'
$engine = (Get-Command $Godot -CommandType Application -ErrorAction Stop).Source
$version = (& $engine --version | Out-String).Trim()
if ($version -notmatch '^4\.7\.2\.stable\.') { throw "Expected pinned Godot 4.7.2; got $version" }
# The console executable is a launcher. Sample the actual rendered process.
if ($engine.EndsWith('_console.exe')) {
    $renderEngine = $engine.Replace('_console.exe', '.exe')
    if (-not (Test-Path -LiteralPath $renderEngine)) { throw 'Cannot locate the rendered Godot executable' }
} else { $renderEngine = $engine }
if ($Repeats -lt 1 -or $Repeats -gt 10 -or $RunLabel -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Invalid repeat count or label' }
$destination = Join-Path $projectRoot "artifacts/current_expedition/$RunLabel"
New-Item -ItemType Directory -Path $destination -Force | Out-Null
function Get-SourceManifest {
    $paths = @(& $git -C $projectRoot ls-files --cached --others --exclude-standard) | Sort-Object -Unique
    $hashes = [ordered]@{}
    foreach ($path in $paths) {
        $absolute = Join-Path $projectRoot $path
        if (Test-Path -LiteralPath $absolute -PathType Leaf) {
            $hashes[$path] = (Get-FileHash -LiteralPath $absolute -Algorithm SHA256).Hash
        } else { $hashes[$path] = 'DELETED' }
    }
    return $hashes
}
$manifest = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString('o')
    commit = (& $git -C $projectRoot rev-parse HEAD | Out-String).Trim()
    branch = (& $git -C $projectRoot branch --show-current | Out-String).Trim()
    status = @(& $git -C $projectRoot status --porcelain)
    engine = $version
    command = "tools/profile_current_expedition.ps1 -Godot <pinned engine> -Repeats $Repeats -RunLabel $RunLabel" + $(if ($ContactStudy) { ' -ContactStudy' } else { '' })
    cache_policy = 'Separate fresh processes. OS/driver caches retained; each run includes in-process warmup and post-load windows. No claim of physically cold disk/shader caches.'
    cpu = (Get-CimInstance Win32_Processor | Select-Object -ExpandProperty Name)
    system_memory_bytes = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
    gpu = @(Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion)
    os = (Get-CimInstance Win32_OperatingSystem).Caption
    source_before = Get-SourceManifest
    runs = @()
}
$manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath "$destination/manifest.json" -Encoding utf8
$caps = if ($ContactStudy) { @(60) } else { @(60, 0) }
$script = if ($ContactStudy) { 'tools/profile_expedition_contact.gd' } else { 'tools/profile_current_expedition.gd' }
foreach ($cap in $caps) {
    foreach ($iteration in 1..$Repeats) {
        $name = "cap$cap-run$iteration"
        $runDirectory = Join-Path $destination $name
        New-Item -ItemType Directory -Path $runDirectory -Force | Out-Null
        $runSource = Get-SourceManifest
        $runSource | ConvertTo-Json -Depth 5 | Set-Content "$runDirectory/source_before.json" -Encoding utf8
        $arguments = @('--path', ('"' + $projectRoot + '"'), '--rendering-driver', 'd3d12', '--script', $script, '--', "--cap=$cap", "--output=res://artifacts/current_expedition/$RunLabel/$name")
        $started = Get-Date
        $process = Start-Process -FilePath $renderEngine -ArgumentList $arguments -WorkingDirectory $projectRoot -WindowStyle Hidden -RedirectStandardOutput "$runDirectory/stdout.log" -RedirectStandardError "$runDirectory/stderr.log" -PassThru
        # Cache the native handle before exit; redirected Start-Process can otherwise lose ExitCode on Windows.
        # https://github.com/PowerShell/PowerShell/issues/5421
        $null = $process.Handle
        $peakWorkingSet = 0L
        while (-not $process.HasExited) {
            $process.Refresh()
            $peakWorkingSet = [Math]::Max($peakWorkingSet, $process.PeakWorkingSet64)
            Start-Sleep -Milliseconds 200
        }
        $process.WaitForExit()
        $exitCode = $process.ExitCode
        if ($null -eq $exitCode) { throw "Cannot determine process exit status: $runDirectory" }
        $errors = @(Get-Content "$runDirectory/stderr.log" | Where-Object { $_ -match '^(SCRIPT ERROR|ERROR):' })
        $runSourceAfter = Get-SourceManifest
        $runSourceAfter | ConvertTo-Json -Depth 5 | Set-Content "$runDirectory/source_after.json" -Encoding utf8
        $entry = [ordered]@{name=$name; executable=$renderEngine; arguments=$arguments; started_utc=$started.ToUniversalTime().ToString('o'); elapsed_seconds=((Get-Date)-$started).TotalSeconds; exit_code=$exitCode; sampled_peak_working_set_bytes=$peakWorkingSet; engine_errors=$errors; source_changed=((ConvertTo-Json $runSource -Compress) -cne (ConvertTo-Json $runSourceAfter -Compress))}
        $manifest.runs += $entry
        $manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath "$destination/manifest.json" -Encoding utf8
        Write-Output "$name completed: exit $exitCode, memory $peakWorkingSet"
        if ($exitCode -ne 0 -or $errors.Count -gt 0 -or -not (Test-Path "$runDirectory/profile.json")) { throw "Profile failed: $runDirectory" }
        $process.Dispose()
    }
}
$manifest.source_after = Get-SourceManifest
$manifest.source_changed_during_runs = (ConvertTo-Json $manifest.source_before -Compress) -cne (ConvertTo-Json $manifest.source_after -Compress)
$manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath "$destination/manifest.json" -Encoding utf8
Write-Output "Evidence: $destination"
