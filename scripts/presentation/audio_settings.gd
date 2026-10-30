class_name GameAudioSettings
extends Resource
## Root audio policy. Categories inherit this owner's routing and shared limits.

const CATEGORIES := ["Music", "Atmosphere", "Details", "Combat", "UI"]
@export var cues: Array[GameAudioCue] = []
## Maximum simultaneous one-shots across every category; excess requests are dropped.
@export_range(1, 64, 1) var voice_budget := 16
## Seconds for continuous beds to fade in/out when their context changes.
@export_range(0.0, 5.0, 0.05) var fade_seconds := 0.8
## Camera distance in world cells at which the close-detail mix is fully present.
@export_range(1.0, 100.0, 0.5) var close_distance := 8.0
## Camera distance at which the wide-atmosphere mix is fully present.
@export_range(2.0, 200.0, 0.5) var wide_distance := 35.0
## Retain some broad atmosphere when zoomed in.
@export_range(0.0, 1.0, 0.05) var close_atmosphere_gain := 0.35
## Retain some detail when zoomed out; positional attenuation still applies.
@export_range(0.0, 1.0, 0.05) var wide_detail_gain := 0.15
## Volume defaults in percent. Local Options preferences override on startup.
@export_range(0.0, 100.0, 1.0) var master_volume := 80.0
@export_range(0.0, 100.0, 1.0) var music_volume := 70.0
@export_range(0.0, 100.0, 1.0) var atmosphere_volume := 80.0
@export_range(0.0, 100.0, 1.0) var details_volume := 80.0
@export_range(0.0, 100.0, 1.0) var combat_volume := 80.0
@export_range(0.0, 100.0, 1.0) var ui_volume := 70.0

func valid() -> bool:
	if voice_budget < 1 or voice_budget > 64 or not is_finite(fade_seconds) or fade_seconds < 0 or fade_seconds > 5:
		return false
	if not is_finite(close_distance) or not is_finite(wide_distance) or close_distance < 1 or close_distance > 100 or wide_distance <= close_distance or wide_distance > 200:
		return false
	for gain in [close_atmosphere_gain, wide_detail_gain]:
		if not is_finite(gain) or gain < 0 or gain > 1:
			return false
	for value in [master_volume, music_volume, atmosphere_volume, details_volume, combat_volume, ui_volume]:
		if not is_finite(value) or value < 0 or value > 100:
			return false
	var keys := {}
	for cue in cues:
		if cue == null or not cue.valid() or cue.category not in CATEGORIES or keys.has(cue.key):
			return false
		keys[cue.key] = true
	return true
