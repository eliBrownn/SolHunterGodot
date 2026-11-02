class_name ReadinessSettings
extends Resource
## Provisional alpha timings. Existing damage, move costs and finite uses remain authoritative.
@export var enabled := false
## Seconds per cardinal movement event; applies to newly committed plans.
@export_range(0.05, 1.0, 0.01) var movement_seconds := 0.25
## Seconds between preparation and impact; committed aim cannot track a moving target.
@export_range(0.05, 2.0, 0.01) var preparation_seconds := 0.5
## Base recovery seconds, scaled by 10 / effective Speed.
@export_range(0.1, 5.0, 0.05) var recovery_seconds := 1.5
## Live battle seconds before commander blackout; planning never advances this clock.
@export_range(10, 600, 1) var blackout_seconds := 120.0
## Equipped alpha field kit: fraction of live turbulence exposure prevented.
@export_range(0.0, 0.9, 0.05) var gear_protection := 0.25
## Temporary live protection after deploying a healthy reserve, in seconds.
@export_range(0.0, 10.0, 0.25) var reserve_buffer_seconds := 3.0
## Warning and severe exposure fractions of the blackout threshold.
@export_range(0.1, 0.9, 0.05) var warning_fraction := 0.5
@export_range(0.1, 0.95, 0.05) var severe_fraction := 0.8

func valid() -> bool:
	return is_finite(movement_seconds) and movement_seconds >= 0.05 and movement_seconds <= 1.0 and is_finite(preparation_seconds) and preparation_seconds >= 0.05 and preparation_seconds <= 2.0 and is_finite(recovery_seconds) and recovery_seconds >= 0.1 and recovery_seconds <= 5.0 and is_finite(blackout_seconds) and blackout_seconds >= 10 and blackout_seconds <= 600 and is_finite(gear_protection) and gear_protection >= 0 and gear_protection <= 0.9 and is_finite(reserve_buffer_seconds) and reserve_buffer_seconds >= 0 and reserve_buffer_seconds <= 10 and warning_fraction >= 0.1 and warning_fraction < severe_fraction and severe_fraction <= 0.95
