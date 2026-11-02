class_name SolStatSettings
extends Resource
## New individuals snapshot these parameters. Existing rolls and growth never reroll on tuning edits.
## Minimum natural percentage; inclusive. Applies only to new individuals.
@export_range(50, 100) var iv_min := 90
## Maximum natural percentage; inclusive. Applies only to new individuals.
@export_range(100, 150) var iv_max := 110
## Average this many independent uniform rolls, concentrating potential near the middle.
@export_range(2, 8) var iv_samples := 3
## Points required to reach the full 10% bonus in one stat.
@export_range(10, 1000) var points_per_stat := 100
## Total budget expressed in fully trained stats. Six stats remain independently allocatable.
@export_range(1, 6) var trained_stats := 3
## Maximum percentage increase in a fully trained stat, separate from natural IVs.
@export_range(0, 25) var training_percent := 10
## Full-budget fractions available in ordinary forms one and two; final forms always get 100%.
@export_range(1, 100) var first_form_percent := 50
## Second nonfinal form's fraction of both per-stat and total training capacity.
@export_range(1, 100) var second_form_percent := 75
## No training rewards when the defeated opponent is this many levels below the participant.
@export_range(1, 54) var weak_level_gap := 10
## Training reward before adding opponent-level minus participant-level; minimum one for eligible battles.
@export_range(1, 100) var training_reward := 5
## Limited retraining items supplied once per expedition. Resetting a trained Sol consumes one.
@export_range(0, 99) var retraining_items := 3

func parameters() -> Dictionary:
	return {"iv_min": iv_min, "iv_max": iv_max, "iv_samples": iv_samples,
		"points_per_stat": points_per_stat, "trained_stats": trained_stats,
		"training_percent": training_percent, "first_form_percent": first_form_percent,
		"second_form_percent": second_form_percent, "weak_level_gap": weak_level_gap,
		"training_reward": training_reward}

func valid() -> bool:
	return valid_parameters(parameters()) and retraining_items >= 0 and retraining_items <= 99

static func valid_parameters(p: Variant) -> bool:
	if not p is Dictionary or not RecordShape.keys_match(p, ["iv_min", "iv_max", "iv_samples", "points_per_stat", "trained_stats", "training_percent", "first_form_percent", "second_form_percent", "weak_level_gap", "training_reward"]):
		return false
	for key in p:
		if not SolSpeciesDefinition.whole(p[key], 0, 1000):
			return false
	return p.iv_min >= 50 and p.iv_min <= 100 and p.iv_max >= 100 and p.iv_max <= 150 and p.iv_samples >= 2 and p.iv_samples <= 8 and p.points_per_stat >= 10 and p.trained_stats >= 1 and p.trained_stats <= 6 and p.training_percent <= 25 and p.first_form_percent >= 1 and p.first_form_percent <= p.second_form_percent and p.second_form_percent <= 100 and p.weak_level_gap >= 1 and p.weak_level_gap <= 54 and p.training_reward >= 1 and p.training_reward <= 100
