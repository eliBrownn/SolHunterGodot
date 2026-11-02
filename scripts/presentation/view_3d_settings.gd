class_name View3DSettings
extends Resource
## Camera, scenery visibility and streaming are presentation policy, never saved world data.

## Vertical perspective field of view in degrees. Restart/reapply view settings to use edits.
@export_range(35.0, 75.0, 1.0) var field_of_view := 50.0
## Starting orbit distance to the trainer in world cells. Home restores this distance.
@export_range(8.0, 40.0, 1.0) var starting_distance := 18.0
## Minimum/maximum wheel dolly distance in world cells. Must enclose Starting Distance.
@export_range(2.0, 20.0, 0.5) var minimum_distance := 2.5
## Close zoom tilt at the neutral 35-degree orbit input; vertical orbit retains its full range. Blends out at Starting Distance. Read live.
@export_range(5.0, 35.0, 1.0) var close_elevation := 12.0
## Close zoom focus above the feet in player heights. Read live.
@export_range(0.3, 1.0, 0.05) var close_focus_height := 0.75
## Minimum camera height above terrain, in cells. Reapply after editing; prevents low orbits entering hills. Does not clear intervening scenery.
@export_range(0.1, 3.0, 0.1) var ground_clearance := 0.6
## Seconds to soften vertical camera motion over terrain seams. Zero follows exactly; Home/rebuild snaps.
@export_range(0.0, 0.4, 0.01) var height_smoothing_seconds := 0.12
@export_range(20.0, 48.0, 1.0) var maximum_distance := 26.0
## Allow wheel/controller dolly; disabling holds the current distance. Read live.
@export var zoom_enabled := true
## Far clipping depth from the camera in world cells. Also controls the streamed frustum and fog.
@export_range(48.0, 128.0, 8.0) var render_distance := 72.0
## Extra ground margin around the visible frustum, in cells, to absorb camera motion and tree crowns.
@export_range(4.0, 16.0, 1.0) var stream_margin := 8.0
## Hard player-centered square generation radius, in 16-cell chunks. Once nearby requests finish, generation waits until movement/view changes bring missing chunks into range. Reapply/restart; presentation only.
@export_range(3, 16, 1) var active_chunk_radius := 3
## Extra chunk rings retained on departure to avoid boundary churn. Does not request generation. Reapply/restart.
@export_range(0, 2, 1) var chunk_unload_buffer := 1
## Total detailed chunk nodes, including hidden cache, retirement and preparation. Reapply/restart; never deletes saved contents.
@export_range(64, 512, 16) var max_resident_chunks := 128
## Maximum new terrain/scenery chunks built per active frame after initialization.
@export_range(1, 4, 1) var chunks_per_frame := 1
## Background terrain, placement, grass and mesh-data preparation. Main-thread uploads remain bounded. Reapply/restart.
@export var threaded_chunk_preparation := true
## Test policy: finish one detailed chunk through publication before starting another, in a player-centered spiral. Keeps frame budgets and background preparation. Reapply/restart.
@export var spiral_chunk_loading := true
## Fraction of the desired spiral given the normal preparation budget. The remaining outer chunks use Distant Chunk Work Ms. Reapply/restart; presentation only.
@export_range(0.25, 1.0, 0.05) var nearby_chunk_fraction := 0.5
## Main-thread detail budget for outer chunks, in milliseconds per frame, capped by Chunk Work Ms. Background jobs remain finite and one-at-a-time. Reapply/restart.
@export_range(0.25, 3.0, 0.25) var distant_chunk_work_ms := 0.75
## Maximum exclusive chunk contexts, including completed results. Reapply/restart.
@export_range(1, 2, 1) var chunk_preparation_jobs := 1
## Maximum predictive travel lookahead in cells, within the existing active/resident limits. Reapply/restart.
@export_range(0.0, 32.0, 1.0) var chunk_lookahead_cells := 16.0
## Minimum prediction horizon in seconds; observed readiness latency can extend it up to four seconds. Reapply/restart.
@export_range(0.25, 2.0, 0.25) var chunk_lookahead_seconds := 1.0
## Main-thread preparation budget in milliseconds per frame. One cell group or GPU upload may finish after the deadline. Reapply to use edits; initial visible coverage stays synchronous.
@export_range(1.0, 8.0, 0.5) var chunk_work_ms := 3.0
## Maximum detail preparation operations per active frame, including generation/cells. Reapply/restart.
@export_range(16, 256, 16) var chunk_operations_per_frame := 128
## Maximum detailed mesh/material-batch uploads per active frame. CPU buffer assembly shares the operation/time budget. Reapply/restart.
@export_range(1, 8, 1) var chunk_upload_steps_per_frame := 2
## Maximum temporary-ground tile/skirt/geography operations per active frame. Reapply/restart.
@export_range(8, 128, 8) var ground_operations_per_frame := 32
## Maximum temporary-ground mesh uploads per active frame. Reapply/restart.
@export_range(1, 2, 1) var ground_uploads_per_frame := 1
## Cleanup steps per active frame. One step releases at most 32 owned records or one child/root node. Reapply/restart.
@export_range(1, 32, 1) var retirement_steps_per_frame := 8
## Main-thread cleanup allowance in milliseconds per frame. An indivisible resource release can overrun it. Reapply/restart.
@export_range(0.1, 2.0, 0.1) var retirement_work_ms := 0.5
@export_group("Chunk Concurrency (Experimental)")
## One bounded data-only instance-buffer worker. Reapply/restart; disabled until matched performance qualification.
@export var threaded_chunk_buffers := false
## Engine background loading of baked plant dependencies for the next cell. Reapply/restart; never changes plant selection.
@export var threaded_chunk_assets := false
## Small batches remain inline to avoid dispatch overhead. Reapply/restart.
@export_range(128, 4096, 128) var chunk_worker_min_instances := 512
@export_group("Visibility")
## Player-centered Vastra effects radius in cells. Presentation only; does not change transfer simulation. Read live.
@export_range(8.0, 48.0, 2.0) var vastra_distance := 38.0
## Fade width inside the Vastra effect radius, in cells. Read live.
@export_range(2.0, 12.0, 1.0) var vastra_fade_cells := 6.0
## Temporary ground sample spacing in cells while detailed chunks are queued. Coarser samples reduce turn-time work.
@export_enum("1 cell:1", "2 cells:2", "4 cells:4", "8 cells:8") var stream_ground_step: int = 4
## Recently hidden temporary-ground chunks retained for quick camera reversals. Zero disables this bounded visual cache; reapply to change it.
@export_range(0, 256, 16) var stream_ground_cache_chunks := 64
## Hidden detailed chunks retained for camera reversals. Presentation only; cleared on world rebuild. Reapply to change capacity.
@export_range(0, 128, 8) var stream_detail_cache_chunks := 16
## Tree batch draw distance from the camera in cells, with a 12-cell fade band. Fog completes four cells before the shorter tree/terrain horizon. Reapply/restart.
@export_range(48.0, 128.0, 4.0) var tree_distance := 72.0
## Small decoration draw distance from the camera in cells, with a 12-cell fade band. Zero follows the fog horizon. Reapply/restart.
@export_range(0.0, 128.0, 4.0) var detail_distance := 32.0
## Individual leaf-grass clump distance from the camera in cells. Restart/reapply; never changes simulation supply.
@export_range(8.0, 64.0, 2.0) var grass_distance := 26.0
## Gradual per-clump fade width in cells, ending at Grass Distance. Reapply/restart.
@export_range(4.0, 24.0, 1.0) var grass_fade_cells := 12.0
## Native scenery mesh LOD bias. Higher retains more detail; applies on restart/reapply. Full-resolution picking is independent.
@export_range(0.25, 4.0, 0.25) var scenery_lod_bias := 1.0
## Directional shadow distance from the camera, in cells. Clamped to the terrain render distance.
@export_range(16.0, 80.0, 4.0) var shadow_distance := 32.0
## Begin clear-weather fog at this fraction of the fixed horizon depth. Camera turns do not change it.
@export_range(0.4, 0.98, 0.01) var fog_start_fraction := 0.85
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
## Original project sky; its uniform parameters remain editable on the generated material.
@export var sky_shader: Shader = preload("res://shaders/project_sky.gdshader")
@export var cloud_primary: Texture2D = preload("res://resources/sky/cloud_primary.tres")
@export var cloud_secondary: Texture2D = preload("res://resources/sky/cloud_secondary.tres")
## Horizon and depth-fog color, kept identical to hide the streaming horizon.
@export var horizon_color := Color("b7d4ed")
@export var sky_color := Color("4387c8")
## Visible cloud amount; zero is a clear sky. Restart/reapply to use edits.
@export_range(0.0, 1.0, 0.05) var cloud_density := 0.65
## Procedural sky wind vector (-2 to 2 per component); zero freezes cloud translation. Cosmetic only.
@export var cloud_wind := Vector2(0.1, 0.035)

func valid() -> bool:
	if not is_finite(nearby_chunk_fraction) or nearby_chunk_fraction < 0.25 or nearby_chunk_fraction > 1.0: return false
	if not is_finite(distant_chunk_work_ms) or distant_chunk_work_ms < 0.25 or distant_chunk_work_ms > 3.0: return false
	if chunk_preparation_jobs < 1 or chunk_preparation_jobs > 2: return false
	if not is_finite(chunk_lookahead_cells) or chunk_lookahead_cells < 0.0 or chunk_lookahead_cells > 32.0: return false
	if not is_finite(chunk_lookahead_seconds) or chunk_lookahead_seconds < 0.25 or chunk_lookahead_seconds > 2.0: return false
	if chunk_worker_min_instances < 128 or chunk_worker_min_instances > 4096: return false
	if chunk_operations_per_frame < 16 or chunk_operations_per_frame > 256 or chunk_upload_steps_per_frame < 1 or chunk_upload_steps_per_frame > 8: return false
	if ground_operations_per_frame < 8 or ground_operations_per_frame > 128 or ground_uploads_per_frame < 1 or ground_uploads_per_frame > 2: return false
	if retirement_steps_per_frame < 1 or retirement_steps_per_frame > 32: return false
	if not is_finite(retirement_work_ms) or retirement_work_ms < 0.1 or retirement_work_ms > 2.0: return false
	if not is_finite(vastra_distance) or vastra_distance < 8 or vastra_distance > 48 or not is_finite(vastra_fade_cells) or vastra_fade_cells < 2 or vastra_fade_cells > 12 or vastra_fade_cells >= vastra_distance: return false
	if not is_finite(grass_fade_cells) or grass_fade_cells < 4.0 or grass_fade_cells > 24.0 or grass_fade_cells >= grass_distance: return false
	if not is_finite(tree_distance) or tree_distance < 48.0 or tree_distance > 128.0 or tree_distance <= maximum_distance + 4.0:
		return false
	if active_chunk_radius < 3 or active_chunk_radius > 16 or chunk_unload_buffer < 0 or chunk_unload_buffer > 2:
		return false
	if max_resident_chunks < 64 or max_resident_chunks > 512 or max_resident_chunks - stream_detail_cache_chunks < 26:
		return false
	if not is_finite(scenery_lod_bias) or scenery_lod_bias < 0.25 or scenery_lod_bias > 4.0: return false
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
	if not is_finite(close_elevation) or close_elevation<5.0 or close_elevation>35.0 or not is_finite(close_focus_height) or close_focus_height<0.3 or close_focus_height>1.0: return false
	var values := [occlusion_radius, occlusion_intensity,field_of_view, starting_distance, minimum_distance, maximum_distance, render_distance, stream_margin, detail_distance, grass_distance, shadow_distance, fog_start_fraction, cloud_density, cloud_wind.x, cloud_wind.y]
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
	return multisample_antialiasing in [0, 1, 2, 3] and occlusion_radius >= 0.1 and occlusion_radius <= 4 and occlusion_intensity >= 0 and occlusion_intensity <= 4 and field_of_view >= 35 and field_of_view <= 75 and minimum_distance >= 2 and minimum_distance <= 20 and maximum_distance >= 20 and maximum_distance <= 48 and starting_distance >= minimum_distance and starting_distance <= maximum_distance and render_distance >= 48 and render_distance <= 128 and render_distance > maximum_distance + 4 and stream_margin >= 4 and stream_margin <= 16 and chunks_per_frame >= 1 and chunks_per_frame <= 4 and detail_distance >= 0 and detail_distance <= 128 and grass_distance >= 8 and grass_distance <= 64 and shadow_distance >= 16 and shadow_distance <= 80 and fog_start_fraction >= 0.4 and fog_start_fraction <= 0.98 and cloud_density >= 0 and cloud_density <= 1 and sky_shader != null and cloud_primary != null and cloud_secondary != null

func fog_distance() -> float:
	return minf(render_distance, tree_distance) - 4.0

func visibility_distance(group: String) -> float:
	var horizon := minf(render_distance, tree_distance)
	match group:
		"tree": return horizon
		"grass": return minf(grass_distance, horizon)
		"detail": return minf(detail_distance, horizon) if detail_distance > 0.0 else horizon
	return 0.0
