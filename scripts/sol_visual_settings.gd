class_name SolVisualSettings
extends Resource
## Cosmetic orb presentation only. Palette assignments are provisional, not affinity mechanics.

## Orb diameter in world cells. Applies to wild and deployed Sols after view reconstruction.
@export_range(0.3, 1.2, 0.05) var diameter := 0.75
## Orb center height above its ground anchor, in world cells.
@export_range(0.35, 1.5, 0.05) var hover_height := 0.7
## Translucent pixel halo strength. Zero removes the halo.
@export_range(0.0, 0.6, 0.05) var aura_opacity := 0.22
## Bounded decorative motes per Sol. Zero disables effects without hiding the orb.
@export_range(0, 12) var effect_count := 5
## Cosmetic effect cycles per second. Zero freezes effects.
@export_range(0.0, 3.0, 0.1) var effect_speed := 0.6
## Ground tint opacity for persistent local affinity imprints. Zero hides tint, not saved state.
@export_range(0.0, 0.5, 0.05) var imprint_opacity := 0.22
## Individual affinity ID to provisional display color. Unknown IDs use neutral white.
@export var palette: Dictionary[String, Color] = {
	"fire": Color("ff9254"), "water": Color("459fe8"), "earth": Color("ba9465"),
	"air": Color("b7eee6"), "lightning": Color("f5d65b"), "void": Color("604099"),
	"spectral": Color("9df1ca"), "quantum": Color("ed8edd")}

func valid() -> bool:
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
