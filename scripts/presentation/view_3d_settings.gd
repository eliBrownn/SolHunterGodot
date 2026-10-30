class_name View3DSettings
extends Resource
## Camera, scenery visibility and streaming are presentation policy, never saved world data.

## Vertical perspective field of view in degrees. Restart/reapply view settings to use edits.
@export_range(35.0, 75.0, 1.0) var field_of_view := 50.0
## Starting orbit distance to the trainer in world cells. Home restores this distance.
@export_range(8.0, 40.0, 1.0) var starting_distance := 22.0
## Minimum/maximum wheel dolly distance in world cells. Must enclose Starting Distance.
@export_range(5.0, 20.0, 1.0) var minimum_distance := 8.0
## Minimum camera height above terrain, in cells. Reapply after editing; prevents low orbits entering hills. Does not clear intervening scenery.
@export_range(0.1, 3.0, 0.1) var ground_clearance := 0.6
## Seconds to soften vertical camera motion over terrain seams. Zero follows exactly; Home/rebuild snaps.
@export_range(0.0, 0.4, 0.01) var height_smoothing_seconds := 0.12
@export_range(20.0, 48.0, 1.0) var maximum_distance := 40.0
## Far clipping depth from the camera in world cells. Also controls the streamed frustum and fog.
@export_range(48.0, 128.0, 8.0) var render_distance := 72.0
## Extra ground margin around the visible frustum, in cells, to absorb camera motion and tree crowns.
@export_range(4.0, 16.0, 1.0) var stream_margin := 8.0
## Maximum new terrain/scenery chunks built per active frame after initialization.
@export_range(1, 4, 1) var chunks_per_frame := 1
## Main-thread preparation budget in milliseconds per frame. One cell group or GPU upload may finish after the deadline. Reapply to use edits; initial visible coverage stays synchronous.
@export_range(1.0, 8.0, 0.5) var chunk_work_ms := 4.0
## Temporary ground sample spacing in cells while detailed chunks are queued. Coarser samples reduce turn-time work.
@export_enum("1 cell:1", "2 cells:2", "4 cells:4", "8 cells:8") var stream_ground_step: int = 4
## Recently hidden temporary-ground chunks retained for quick camera reversals. Zero disables this bounded visual cache; reapply to change it.
@export_range(0, 256, 16) var stream_ground_cache_chunks := 64
## Hidden detailed chunks retained for camera reversals. Presentation only; cleared on world rebuild. Reapply to change capacity.
@export_range(0, 128, 8) var stream_detail_cache_chunks := 32
## Small decoration draw distance from the camera in cells, with a 12-cell fade band. Zero follows trees to the terrain horizon.
@export_range(0.0, 128.0, 4.0) var detail_distance := 48.0
## Directional shadow distance from the camera, in cells. Clamped to the terrain render distance.
@export_range(16.0, 80.0, 4.0) var shadow_distance := 48.0
## Begin clear-weather fog at this fraction of the fixed horizon depth. Camera turns do not change it.
@export_range(0.4, 0.98, 0.01) var fog_start_fraction := 0.95
@export_group("Image Quality")
## Pixel sampling of the world only; UI and picking stay full resolution. Applies immediately via Options.
@export_enum("Off", "Very light 1.25x", "Light 1.5x", "Medium 1.75x", "Strong 2x", "Deep 3x") var pixel_effect_level := 0
## Contact shading around terrain, trees and characters. Restart/reapply to use edits.
@export var ambient_occlusion := true
## Ambient occlusion radius in world cells.
@export_range(0.1, 4.0, 0.1) var occlusion_radius := 1.2
## Strength of ambient contact shading.
@export_range(0.0, 4.0, 0.1) var occlusion_intensity := 1.4
## Multisample anti-aliasing on the main 3D viewport. Restart/reapply to use edits.
@export_enum("Disabled:0", "2x:1", "4x:2", "8x:3") var multisample_antialiasing: int = 1
@export_group("Sky")
## Owner-supplied procedural sky shader; its uniform parameters remain editable on the generated material.
@export var sky_shader: Shader = preload("res://shaders/daylight_sky.gdshader")
@export var cloud_primary: Texture2D = preload("res://resources/cloud_noise_1.tres")
@export var cloud_secondary: Texture2D = preload("res://resources/cloud_noise_2.tres")
## Horizon and depth-fog color, kept identical to hide the streaming horizon.
@export var horizon_color := Color("b7d4ed")
@export var sky_color := Color("4387c8")
## Visible cloud amount; zero is a clear sky. Restart/reapply to use edits.
@export_range(0.0, 1.0, 0.05) var cloud_density := 0.65
## Procedural sky wind vector (-2 to 2 per component); zero freezes cloud translation. Cosmetic only.
@export var cloud_wind := Vector2(0.1, 0.035)

func valid() -> bool:
	if not is_finite(height_smoothing_seconds) or height_smoothing_seconds < 0.0 or height_smoothing_seconds > 0.4:
		return false
	if pixel_effect_level < 0 or pixel_effect_level > 5:
		return false
	if not is_finite(ground_clearance) or ground_clearance < 0.1 or ground_clearance > 3.0:
		return false
	if stream_detail_cache_chunks < 0 or stream_detail_cache_chunks > 128:
		return false
	if stream_ground_cache_chunks < 0 or stream_ground_cache_chunks > 256:
		return false
	if not is_finite(chunk_work_ms) or chunk_work_ms < 1.0 or chunk_work_ms > 8.0:
		return false
	var values := [occlusion_radius, occlusion_intensity,field_of_view, starting_distance, minimum_distance, maximum_distance, render_distance, stream_margin, detail_distance, shadow_distance, fog_start_fraction, cloud_density, cloud_wind.x, cloud_wind.y]
	for value in values:
		if not is_finite(value):
			return false
	for color in [horizon_color, sky_color]:
		if not is_finite(color.r) or not is_finite(color.g) or not is_finite(color.b) or color.r < 0 or color.r > 1 or color.g < 0 or color.g > 1 or color.b < 0 or color.b > 1 or color.a != 1:
			return false
	if absf(cloud_wind.x) > 2 or absf(cloud_wind.y) > 2:
		return false
	if stream_ground_step not in [1, 2, 4, 8]:
		return false
	return multisample_antialiasing in [0, 1, 2, 3] and occlusion_radius >= 0.1 and occlusion_radius <= 4 and occlusion_intensity >= 0 and occlusion_intensity <= 4 and field_of_view >= 35 and field_of_view <= 75 and minimum_distance >= 5 and minimum_distance <= 20 and maximum_distance >= 20 and maximum_distance <= 48 and starting_distance >= minimum_distance and starting_distance <= maximum_distance and render_distance >= 48 and render_distance <= 128 and render_distance > maximum_distance + 4 and stream_margin >= 4 and stream_margin <= 16 and chunks_per_frame >= 1 and chunks_per_frame <= 4 and detail_distance >= 0 and detail_distance <= 128 and shadow_distance >= 16 and shadow_distance <= 80 and fog_start_fraction >= 0.4 and fog_start_fraction <= 0.98 and cloud_density >= 0 and cloud_density <= 1 and sky_shader != null and cloud_primary != null and cloud_secondary != null
