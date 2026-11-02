param(
    [string]$Godot = 'godot',
    [ValidateRange(1,3)][int]$Repeats = 3,
    [ValidatePattern('^[a-zA-Z0-9_-]+$')][string]$RunLabel = (Get-Date -Format 'yyyyMMdd-HHmmss')
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$git = 'C:/Program Files/Git/cmd/git.exe'
$engine = (Get-Command $Godot -CommandType Application).Source
$version = (& $engine --version | Out-String).Trim()
if ($version -notmatch '^4\.7\.2\.stable\.') { throw "Expected Godot 4.7.2, got $version" }
if ($engine.EndsWith('_console.exe')) { $engine = $engine.Replace('_console.exe','.exe') }
$outputRoot = Join-Path $root "artifacts/cohesive_sample/$RunLabel"
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
function Fingerprint {
    $result = [ordered]@{}
    foreach ($path in @(& $git -C $root ls-files --cached --others --exclude-standard | Sort-Object -Unique)) {
        $absolute = Join-Path $root $path
        $result[$path] = if (Test-Path -LiteralPath $absolute -PathType Leaf) { (Get-FileHash -LiteralPath $absolute -Algorithm SHA256).Hash } else { 'DELETED' }
    }
    return $result
}
$manifest = [ordered]@{timestamp_utc=(Get-Date).ToUniversalTime().ToString('o'); engine=$version; commit=(& $git -C $root rev-parse HEAD | Out-String).Trim(); status=@(& $git -C $root status --porcelain); cpu=(Get-CimInstance Win32_Processor).Name; gpu=@(Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion); system_memory_bytes=(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory; cache_policy='Fresh processes; OS/driver caches retained. Matched 60 FPS normal-AI camera/weather fixtures. No budget acceptance implied.'; runs=@()}
foreach ($iteration in 1..$Repeats) {
    foreach ($kind in @('baseline','composed')) {
        $name = "$kind$iteration"
        $destination = Join-Path $outputRoot $name
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        $before = Fingerprint
        $before | ConvertTo-Json -Depth 4 | Set-Content "$destination/source_before.json" -Encoding utf8
        $arguments = @('--path',('"'+$root+'"'),'--rendering-driver','d3d12','--script','tools/review_cohesive_sample.gd','--','--cost-only',"--output=res://artifacts/cohesive_sample/$RunLabel/$name")
        if ($kind -eq 'baseline') { $arguments += '--baseline' }
        $process = Start-Process -FilePath $engine -ArgumentList $arguments -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput "$destination/stdout.log" -RedirectStandardError "$destination/stderr.log" -PassThru
        $peak = 0L
        while (-not $process.HasExited) { $process.Refresh(); $peak=[Math]::Max($peak,$process.PeakWorkingSet64); Start-Sleep -Milliseconds 200 }
        $process.WaitForExit()
        $after = Fingerprint
        $after | ConvertTo-Json -Depth 4 | Set-Content "$destination/source_after.json" -Encoding utf8
        $errors = @(Get-Content "$destination/stderr.log" | Where-Object { $_ -match '^(SCRIPT ERROR|ERROR):' })
        $manifest.runs += [ordered]@{name=$name; command=$arguments; timestamp_utc=(Get-Date).ToUniversalTime().ToString('o'); exit_code=$process.ExitCode; process_peak_working_set_bytes=$peak; errors=$errors; source_changed=((ConvertTo-Json $before -Compress) -cne (ConvertTo-Json $after -Compress))}
        $manifest | ConvertTo-Json -Depth 8 | Set-Content "$outputRoot/manifest.json" -Encoding utf8
        Write-Output "$name exit $($process.ExitCode), errors $($errors.Count), memory $peak"
        if ($process.ExitCode -ne 0 -or $errors.Count -gt 0 -or -not (Test-Path "$destination/review.json")) { throw "Review failed: $destination" }
    }
}
Write-Output "Evidence: $outputRoot"
