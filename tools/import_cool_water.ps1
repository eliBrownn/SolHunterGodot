param(
    [Parameter(Mandatory)]
    [string] $Archive
)

$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$assetRoot = Join-Path $project 'assets/local/emace_cool_water'
$resourceRoot = 'res://assets/local/emace_cool_water'
$entries = @(
    'LICENSE.txt',
    'Shaders/EA_CoolWater.gdshader',
    'Materials/EA_Water_DeepBlue.tres',
    'Textures/EA_Water_Normal.tres',
    'Textures/EA_Foam_Voronoi.tres'
)

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archivePath = (Resolve-Path -LiteralPath $Archive).Path
$zip = [IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    $files = @{}
    foreach ($name in $entries) {
        $entry = $zip.GetEntry("EmacEArtCoolWater/$name")
        if ($null -eq $entry) { throw "Missing Cool Water entry $name" }
        $reader = [IO.StreamReader]::new($entry.Open())
        try { $files[$name] = $reader.ReadToEnd() }
        finally { $reader.Dispose() }
    }
} finally {
    $zip.Dispose()
}

$shaderPath = 'Shaders/EA_CoolWater.gdshader'
$shader = $files[$shaderPath]
if (!$shader.Contains('void fragment() {') -or !$shader.Contains('ALPHA = alpha;') -or
    !$shader.Contains('sin(VERTEX.x * 2.0 + t)')) {
    throw 'Unexpected Cool Water shader version. The atlas adapter could not be applied.'
}
$include = '#include "res://shaders/map_water_mask.gdshaderinc"'
$fragment = @'
void fragment() {
	float atlas_fade = atlas_water_detail(distance(v_world_pos, CAMERA_POSITION_WORLD));
	if (atlas_fade <= 0.001) {
		discard;
	}
	atlas_fade *= atlas_water_coverage(v_world_pos.xz);
	if (atlas_fade <= 0.001) {
		discard;
	}
'@
$shader = $shader.Replace('void fragment() {', "$include`n`n$fragment")
$shader = $shader.Replace('ALPHA = alpha;', 'ALPHA = alpha * atlas_fade;')
$shader = $shader.Replace('sin(VERTEX.x * 2.0 + t)', 'sin((MODEL_MATRIX * vec4(VERTEX, 1.0)).x * 2.0 + t)')
$shader = $shader.Replace('sin(VERTEX.z * 1.7 + t * 0.8)', 'sin((MODEL_MATRIX * vec4(VERTEX, 1.0)).z * 1.7 + t * 0.8)')
$files[$shaderPath] = $shader

foreach ($name in $entries) {
    $contents = $files[$name]
    if ($name.EndsWith('.tres')) {
        $contents = $contents.Replace('res://Shaders/', "$resourceRoot/Shaders/")
        $contents = $contents.Replace('res://Textures/', "$resourceRoot/Textures/")
        $contents = $contents -replace ' uid="uid://[^"]+"', ''
    }
    $target = Join-Path $assetRoot $name
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    [IO.File]::WriteAllText($target, $contents)
}
Write-Host "Installed EmacEArt Cool Water in $assetRoot"
