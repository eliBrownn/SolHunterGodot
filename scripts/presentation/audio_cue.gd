class_name GameAudioCue
extends Resource
## A child of the game mix: owns an asset and local playback, never routing or budgets.

@export var key: StringName
## Leave empty until an approved audio asset is supplied. Missing streams are silent.
@export var stream: AudioStream
## Inherits the selected mix category, including its volume and zoom policy.
@export_enum("Music", "Atmosphere", "Details", "Combat", "UI") var category := "Details"
## Local trim in decibels; cannot amplify above the parent category.
@export_range(-60.0, 0.0, 0.5) var volume_db := 0.0
## Repeats on completion. For seamless loops enable looping in the supplied stream import.
@export var looping := false
## Positional one-shots use the camera listener. Continuous beds are non-positional.
@export var spatial := false
## Audible radius in world cells; applies only to positional one-shots.
@export_range(1.0, 200.0, 1.0) var max_distance := 50.0
## Minimum interval in seconds for this cue, shared by its emitters.
@export_range(0.0, 5.0, 0.01) var cooldown_seconds := 0.0

func valid() -> bool:
	return not key.is_empty() and is_finite(volume_db) and volume_db >= -60 and volume_db <= 0 and is_finite(max_distance) and max_distance >= 1 and max_distance <= 200 and is_finite(cooldown_seconds) and cooldown_seconds >= 0 and cooldown_seconds <= 5 and not (looping and spatial)
