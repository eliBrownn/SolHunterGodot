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
## Individual affinity ID to provisional display color. Unknown IDs use neutral white.
@export var palette: Dictionary[String, Color] = {
	"ember": Color("ff9254"), "tide": Color("459fe8"), "stone": Color("ba9465"),
	"gale": Color("b7eee6"), "grove": Color("83cd66"), "frost": Color("b1dcff"),
	"storm": Color("f5d65b"), "umbra": Color("9572c9"),
	"radiance": Color("ffe8a1"), "aether": Color("e08bdc")}

func valid() -> bool:
	if not is_finite(diameter) or diameter < 0.3 or diameter > 1.2 or not is_finite(hover_height) or hover_height < 0.35 or hover_height > 1.5 or not is_finite(aura_opacity) or aura_opacity < 0 or aura_opacity > 0.6 or not SolSpeciesDefinition.whole(effect_count, 0, 12) or not is_finite(effect_speed) or effect_speed < 0 or effect_speed > 3 or palette.size() > 64:
		return false
	for key in palette:
		var color: Color = palette[key]
		if not SolSpeciesDefinition.text(key, 80) or not is_finite(color.r) or not is_finite(color.g) or not is_finite(color.b) or color.r < 0 or color.r > 1 or color.g < 0 or color.g > 1 or color.b < 0 or color.b > 1 or color.a != 1:
			return false
	return true

func color_for(affinity: String) -> Color:
	return palette.get(affinity, Color("e6e9ee"))
