class_name SolVisualSettings
extends Resource
## Cosmetic orb presentation only. Palette assignments are provisional, not affinity mechanics.

## Orb diameter in world cells. Applies to wild and deployed Sols after view reconstruction.
@export_range(0.3, 1.2, 0.05) var diameter := 0.75
## Orb center height above its ground anchor, in world cells.
@export_range(0.35, 1.5, 0.05) var hover_height := 0.7
## Translucent spherical halo strength. Zero removes the halo.
@export_range(0.0, 0.6, 0.05) var aura_opacity := 0.22
## Bounded decorative motes per Sol. Zero disables effects without hiding the orb.
@export_range(0, 12) var effect_count := 5
## Approved particle artwork; clear to restore the original affinity-shaped pixel motes.
@export var effect_texture: Texture2D = preload("res://assets/effects/kenney_particles/spark_01.png")
## Cosmetic effect cycles per second. Zero freezes effects.
@export_range(0.0, 3.0, 0.1) var effect_speed := 0.6
## Ground tint opacity for persistent local affinity imprints. Zero hides tint, not saved state.
@export_range(0.0, 0.5, 0.05) var imprint_opacity := 0.0
@export_group("Battle Interface")
## Animate health-bar changes over real seconds; zero snaps immediately. HP numbers remain exact.
@export_range(0.0, 1.0, 0.05) var health_bar_seconds := 0.3
## Show read-only movement-path and move-area previews while hovering or aiming.
@export var target_previews := true
## Opacity of path and target-area overlays; presentation only.
@export_range(0.1, 0.8, 0.05) var preview_opacity := 0.5
## Show exact direct-damage and remaining-HP previews for legal attacks.
@export var damage_preview := true
## Duration of a cosmetic hit/heal flash and squash, in real seconds; zero disables it.
@export_range(0.0, 0.6, 0.05) var impact_seconds := 0.3
@export_group("Battle Feedback")
## Show transient combat numbers and affinity pulses. This does not affect combat or activity counts.
@export var feedback_enabled := true
## Optional local distortion burst on confirmed damage; uses the feedback cue budget/lifetime.
@export var impact_distortion_enabled := true
## Lifetime of a floating combat cue, in real seconds.
@export_range(0.25, 2.5, 0.05) var feedback_seconds := 0.9
## Upward travel of combat text, in world cells.
@export_range(0.1, 2.0, 0.1) var feedback_rise := 0.6
## Maximum simultaneous feedback cues; oldest cues retire first.
@export_range(1, 32) var feedback_limit := 16
## Show a dismissible outcome/imprint summary without pausing exploration.
@export var result_panel_enabled := true
@export_group("Battle Pacing")
## Real seconds identifying an accepted move before revealing its effects; leaves space for move anticipation. Applies to the next step.
@export_range(0.0, 1.0, 0.05) var action_cue_seconds := 0.35
## Real seconds to read damage, healing, field changes or an outcome before continuing.
@export_range(0.0, 1.5, 0.05) var consequence_seconds := 0.6
## Real seconds per displayed legal movement waypoint; does not change movement cost.
@export_range(0.0, 0.5, 0.01) var movement_step_seconds := 0.16
## Real seconds identifying the next actor. Does not change initiative or status timing.
@export_range(0.0, 1.0, 0.05) var turn_handoff_seconds := 0.4
@export_group("Affinity Palette")
## Individual affinity ID to provisional display color. Unknown IDs use neutral white.
@export var palette: Dictionary[String, Color] = {
	"fire": Color("ff9254"), "water": Color("459fe8"), "earth": Color("ba9465"),
	"air": Color("b7eee6"), "lightning": Color("f5d65b"), "void": Color("604099"),
	"spectral": Color("9df1ca"), "quantum": Color("ed8edd")}

func valid() -> bool:
	if not is_finite(action_cue_seconds) or action_cue_seconds < 0 or action_cue_seconds > 1 or not is_finite(consequence_seconds) or consequence_seconds < 0 or consequence_seconds > 1.5:
		return false
	if not is_finite(movement_step_seconds) or movement_step_seconds < 0 or movement_step_seconds > 0.5 or not is_finite(turn_handoff_seconds) or turn_handoff_seconds < 0 or turn_handoff_seconds > 1:
		return false
	if not is_finite(health_bar_seconds) or health_bar_seconds < 0 or health_bar_seconds > 1 or not is_finite(preview_opacity) or preview_opacity < 0.1 or preview_opacity > 0.8:
		return false
	if not is_finite(impact_seconds) or impact_seconds < 0 or impact_seconds > 0.6:
		return false
	if not is_finite(feedback_seconds) or feedback_seconds < 0.25 or feedback_seconds > 2.5 or not is_finite(feedback_rise) or feedback_rise < 0.1 or feedback_rise > 2 or not SolSpeciesDefinition.whole(feedback_limit, 1, 32):
		return false
	if not is_finite(imprint_opacity) or imprint_opacity < 0 or imprint_opacity > 0.5:
		return false
	if not is_finite(diameter) or diameter < 0.3 or diameter > 1.2 or not is_finite(hover_height) or hover_height < 0.35 or hover_height > 1.5 or not is_finite(aura_opacity) or aura_opacity < 0 or aura_opacity > 0.6 or not SolSpeciesDefinition.whole(effect_count, 0, 12) or not is_finite(effect_speed) or effect_speed < 0 or effect_speed > 3 or palette.size() > 64:
		return false
	for key in palette:
		var color: Color = palette[key]
		if not SolSpeciesDefinition.text(key, 80) or not is_finite(color.r) or not is_finite(color.g) or not is_finite(color.b) or color.r < 0 or color.r > 1 or color.g < 0 or color.g > 1 or color.b < 0 or color.b > 1 or color.a != 1:
			return false
	return true

func color_for(affinity: String) -> Color:
	return palette.get(AffinityImprint.canonical(affinity), Color("e6e9ee"))
