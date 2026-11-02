class_name VastraParticleSettings
extends Resource
## Branch experiment: optical rendering only; never changes conserved transfers.
@export var enabled := true
## Shared visibility multiplier. Zero discards all particle optics, including refraction.
@export_range(0.0,1.0,0.05) var visibility := 0.3
## Independent finite packet share; zero leaves only the legacy comparison when disabled.
@export_range(0.0,1.0,0.05) var transfer_visibility := 1.0
## Maximum simultaneously rendered authoritative transfers, distributed across visible source regions. Does not change simulation supply or arrival.
@export_range(1,16,1) var transfer_limit := 12
## Rendering heads per transfer, not ecological energy.
@export_range(1,16,1) var heads := 8
@export_range(4,16,1) var history_samples := 10
## Owner baseline, in terrain cells.
@export_range(0.02,0.2,0.005) var thickness := 0.2
@export_range(0.15,3.0,0.05) var filament_length := 2.0
@export_range(0.05,2.0,0.05) var trail_seconds := 1.5
@export_range(0.0,0.02,0.0005) var refraction := 0.01
@export_range(0.0,3.0,0.1) var send_pulse_strength := 1.0
@export_range(0.1,2.0,0.1) var send_pulse_seconds := 0.6
## Soft fade at terrain/body intersections, in cells. Live; no collision or energy effect.
@export_range(0.01,0.5,0.01) var intersection_softness := 0.12
## Traveling variations over actual finite transfers. Zero retains steady packet optics.
@export_range(0.0,0.5,0.05) var breathing_strength := 0.18
## Active seconds per local fluctuation. Sources retain independent phases; pause freezes it.
@export_range(2.0,20.0,0.5) var breathing_seconds := 6.0

func valid() -> bool:
	if not is_finite(intersection_softness) or intersection_softness<0.01 or intersection_softness>0.5: return false
	if not is_finite(breathing_strength) or breathing_strength<0 or breathing_strength>0.5: return false
	if not is_finite(breathing_seconds) or breathing_seconds<2 or breathing_seconds>20: return false
	for value in [visibility,transfer_visibility,thickness,filament_length,trail_seconds,refraction,send_pulse_strength,send_pulse_seconds]:
		if not is_finite(value): return false
	return visibility>=0 and visibility<=1 and transfer_visibility>=0 and transfer_visibility<=1 and transfer_limit>=1 and transfer_limit<=16 and heads>=1 and heads<=16 and history_samples>=4 and history_samples<=16 and thickness>=0.02 and thickness<=0.2 and filament_length>=0.15 and filament_length<=3 and trail_seconds>=0.05 and trail_seconds<=2 and refraction>=0 and refraction<=0.02 and send_pulse_strength>=0 and send_pulse_strength<=3 and send_pulse_seconds>=0.1 and send_pulse_seconds<=2
