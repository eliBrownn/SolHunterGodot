param(
    [string]$Godot = 'godot',
    [ValidateSet('ordinary', 'terrain', 'major_probe')][string]$Fixture = 'ordinary',
    [ValidateSet('default', 'concise')][string]$Timing = 'default',
    [switch]$Reference,
    [switch]$LegacyPolicy,
    [switch]$Session,
    [switch]$Play
)
$ErrorActionPreference = 'Stop'
if ($Session) {
    # Four owner-driven runs; this never supplies choices or feedback on their behalf.
    foreach ($step in @(@('ordinary','default'), @('ordinary','concise'), @('terrain','concise'), @('major_probe','concise'))) {
        & $PSCommandPath -Godot $Godot -Fixture $step[0] -Timing $step[1] -Play
    }
    return
}
$projectRoot = Split-Path -Parent $PSScriptRoot
$engineVersion = (& $Godot --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $engineVersion -notmatch '^4\.7\.2\.stable\.') { throw "Expected Godot 4.7.2 stable; received '$engineVersion'." }
$evidence = Join-Path $projectRoot 'artifacts/combat-pacing'
$runId = (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + "-$Fixture-$Timing"
$runRoot = Join-Path $evidence $runId
New-Item -ItemType Directory -Force -Path $runRoot | Out-Null
$gitPath = 'C:\Program Files\Git\cmd\git.exe'
$revision = (& $gitPath -C $projectRoot rev-parse HEAD | Out-String).Trim()
$status = (& $gitPath -C $projectRoot status --porcelain | Out-String)
if ($status) { $revision += '+dirty' }
# Record the actual tracked diff and new code/resource hashes beside each report.
& $gitPath -C $projectRoot diff --binary | Out-File (Join-Path $runRoot 'working-tree.patch') -Encoding utf8
$paths = & $gitPath -C $projectRoot ls-files --cached --others --exclude-standard -- scripts tests resources tools project.godot
$manifest = foreach ($path in ($paths | Sort-Object -Unique)) {
    $absolute = Join-Path $projectRoot $path
    if (Test-Path -LiteralPath $absolute -PathType Leaf) {
        [pscustomobject]@{ path = $path; sha256 = (Get-FileHash -LiteralPath $absolute -Algorithm SHA256).Hash }
    }
}
$manifest | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $runRoot 'manifest.json') -Encoding utf8
$oldAppData = $env:APPDATA
$oldLocalData = $env:LOCALAPPDATA
try {
    $env:APPDATA = Join-Path $runRoot 'appdata'
    $env:LOCALAPPDATA = Join-Path $runRoot 'localappdata'
    New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
    $engineArgs = @('--path', $projectRoot, '--script', 'tools/measure_combat_pacing.gd')
    if (-not $Play) { $engineArgs = @('--headless') + $engineArgs }
    else { $engineArgs += @('--rendering-method', 'gl_compatibility', '--resolution', '1280x800') }
    $engineArgs += @('--', "--fixture=$Fixture", "--timing=$Timing", "--revision=$revision", "--output=$runRoot/report.json")
    if ($Play) { $engineArgs += '--play' }
    if ($Reference) { $engineArgs += '--reference' }
    if ($LegacyPolicy) { $engineArgs += '--legacy-policy' }
    & $Godot @engineArgs 2>&1 | Tee-Object -FilePath (Join-Path $runRoot 'engine.log')
    if ($LASTEXITCODE -ne 0) { throw 'Pacing run failed; inspect engine.log.' }
    if (Select-String -LiteralPath (Join-Path $runRoot 'engine.log') -Pattern '^(SCRIPT ERROR|ERROR):' -Quiet) { throw 'Godot reported an error.' }
    Write-Host "Pacing evidence: $runRoot"
} finally {
    $env:APPDATA = $oldAppData
    $env:LOCALAPPDATA = $oldLocalData
}
