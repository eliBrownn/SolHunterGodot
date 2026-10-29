extends SceneTree
const Runner = preload("res://tools/measure_combat_pacing.gd")
const Policy = preload("res://tools/combat_pacing_policy.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func drain(playback: BattlePlayback, metrics: BattlePacingMeasurement) -> void:
	for frame in range(10000):
		if not playback.busy: return
		metrics.sample(1.0 / 60.0)
		playback.advance(1.0 / 60.0)
	check(false, "Bounded presentation finishes")

func run() -> void:
	for name in ["ordinary", "terrain", "major_probe"]:
		var fixture: CombatPacingFixture = load("res://resources/combat_pacing/%s.tres" % name)
		check(fixture.valid() and fixture.build() != null, "Development fixture is valid and has an outside release route")
		check(fixture.build().capture_chance() == 0 and fixture.build().passable(fixture.trainer_offset), "Synthetic capture is disabled and trainer starts on legal probe ground")
		var before := var_to_str(fixture)
		for interaction in [false, true]:
			var report := Runner.simulate(fixture, SolVisualSettings.new(), "test", interaction)
			check(report.complete and not report.limit_reached, "Both scripted policies terminate on the representative fixture")
			check(report == Runner.simulate(fixture, SolVisualSettings.new(), "test", interaction), "Recipe, policy and fixed-step timing reproduce identical traces")
			check(report.voluntary_choice_seconds == null and report.seconds.choice == 0, "Scripted runs never invent human thinking time")
			check(report.seconds.presentation >= report.configured_hold_seconds and report.total_sampled_seconds == report.seconds.presentation, "Realized fixed-step waits and configured minimum holds are separate")
			check(report.repeated_state_visits == 0 and not report.trace_truncated, "Representative traces retain all results and expose cycles")
			var concise := Runner.simulate(fixture, preload("res://resources/combat_pacing/concise.tres"), "test", interaction)
			var standard_trace: Array = report.trace.duplicate(true)
			var concise_trace: Array = concise.trace.duplicate(true)
			for events in [standard_trace, concise_trace]:
				for event: Dictionary in events: event.erase("hold_seconds")
			check(concise.complete and concise.configured_hold_seconds < report.configured_hold_seconds and standard_trace == concise_trace, "Concise timing reduces waiting while retaining every action and individual consequence")
		check(before == var_to_str(fixture), "Simulation preserves the shared resource recipe")
	var recipe: CombatPacingFixture = load("res://resources/combat_pacing/ordinary.tres")
	var terrain_recipe: CombatPacingFixture = load("res://resources/combat_pacing/terrain.tres")
	var straight := Runner.simulate(terrain_recipe, SolVisualSettings.new(), "test", false)
	var crossing := Runner.simulate(terrain_recipe, SolVisualSettings.new(), "test", true)
	check(crossing.complete and straight.complete and crossing.repeated_state_visits == 0 and straight.repeated_state_visits == 0, "Both wall strategies remain finite under shared AP; their relative balance requires fresh owner review")
	check(crossing.action_captions.ally.has("Bramblepup uses Thin Passage"), "Terrain benefit comes from an actual phase action and legal crossing")
	var major: CombatPacingFixture = load("res://resources/combat_pacing/major_probe.tres")
	var ordinary := Runner.simulate(recipe, SolVisualSettings.new(), "test", true)
	var direct := Runner.simulate(major, SolVisualSettings.new(), "test", false)
	var prepared := Runner.simulate(major, SolVisualSettings.new(), "test", true)
	check(prepared.outcome == "victory" and prepared.turn_decisions > ordinary.turn_decisions and prepared.ally_hp > direct.ally_hp, "Major probe rewards preparation and lasts longer through legal choices, not extra HP")
	check(prepared.action_captions.ally.has("Bramblepup uses Focus") and prepared.action_captions.enemy.has("Bramblepup uses Heat & Smoke"), "The major trace retains preparation and the enemy's different terrain response")
	check(major.opponent.max_hp == preload("res://resources/starter_bramblepup.tres").max_hp, "Major health uses the unmodified existing peer profile")
	var looping := Runner.simulate(major, SolVisualSettings.new(), "test", false, 40, true)
	check(looping.complete and looping.healing_hp.ally > 0 and not looping.limit_reached, "The old heal-first policy now terminates under the new economy without a forced timeout or healing ban")
	var mend: Dictionary = preload("res://resources/move_library.tres").find("mend")
	check(direct.complete and direct.rejected_commands == 0 and int(direct.action_captions.ally.get("Bramblepup uses " + mend.name, 0)) <= SolMove.uses(mend), "Diagnostic policy completes without rejected commands or exceeding healing uses")
	var planning := major.build()
	planning.deploy(Runner.closest_release(planning))
	var planning_before := planning.view_snapshot()
	var queue_before := planning.queue.duplicate()
	var policy_used := {}
	var planned := Policy.choose(planning, true, policy_used)
	check(planning_before == planning.view_snapshot() and queue_before == planning.queue, "Development policy and detached forecasts never mutate the real battle")
	check(planned == Policy.choose(planning, true, {}), "Safe preparation choice is repeatable")
	var forked := Policy.fork(planning)
	check(forked.view_snapshot() == planning.view_snapshot() and forked.queue == planning.queue and forked.passives.units == planning.passives.units, "Detached forecast preserves initiative, statuses, fields, and individual class state")
	forked.enemy_hp -= 1
	forked.passives.units.ally.first_hit = false
	check(planning_before == planning.view_snapshot(), "Forecast mutations cannot leak into the measured encounter")
	var battle := recipe.build()
	battle.passives.units.clear() # Isolate an intentionally exact heal/hit cycle.
	battle.trainer = Vector2i(-1, 0)
	battle.ally_moves.assign([preload("res://resources/move_library.tres").find("mend")])
	var tuning := SolVisualSettings.new()
	var playback := BattlePlayback.new()
	playback.bind(battle, tuning)
	var metrics := BattlePacingMeasurement.new()
	metrics.bind(playback, {"test": "healing_cycle"})
	metrics.sample(3.0)
	metrics.sample(2.0, true)
	metrics.sample(1.0, false, false)
	metrics.sample(0.5, false, true, true)
	metrics.sample(NAN)
	metrics.sample(-1)
	check(metrics.seconds.choice == 3 and metrics.seconds.paused == 2 and metrics.seconds.commander == 1 and metrics.seconds.result_pending == 0.5, "Voluntary choice, menu pause, commander travel and pending results have disjoint clocks")
	playback.submit("deploy", Vector2i(1, 0))
	drain(playback, metrics)
	var amount := battle.damage_for("enemy", battle.enemy_moves[0], battle.enemy_cell)
	battle.ally_moves[0].power = amount
	battle.ally_moves[0].max_uses = 5 # Isolate five exact exchanges; production healing has fewer uses.
	battle.ally_hp = int(battle.ally.max_hp) - amount
	for repeat in range(5):
		playback.submit("move_slot", battle.ally_cell, 0)
		check(not playback.submit("wait"), "Busy duplicate attempts reject")
		drain(playback, metrics)
		playback.submit("wait")
		drain(playback, metrics)
	check(metrics.healing.ally == amount * 5 and metrics.damage.ally == amount * 5, "Net-zero heal/hit cycles retain individual healing and damage")
	check(metrics.repeated_states == 0 and metrics.damage_free_turns == 5 and metrics.rejected_commands == 5 and not battle.can_use(0, battle.ally_cell), "Charge depletion distinguishes finite heal/hit exchanges from an unbounded repeated state")
	playback.submit("retreat")
	drain(playback, metrics)
	var frozen := metrics.report()
	metrics.sample(99)
	check(frozen == metrics.report(), "Terminal encounters stop clocks before the result screen")
	metrics.unbind()
	playback.reset()
	# A short U/wall detour must temporarily increase distance; the target is reachable.
	var terrain: CombatPacingFixture = load("res://resources/combat_pacing/terrain.tres")
	battle = terrain.build()
	battle.passives.units.clear() # Isolate unreachable-path repetition from finite passive credit.
	battle.phase = "active"
	battle.turn = "enemy"
	battle.ally_cell = Vector2i(-1, 0)
	battle.enemy_cell = Vector2i(1, 0)
	battle.remaining = 1
	battle.movement = 1
	battle.fields.clear()
	battle.enemy_moves.assign([preload("res://resources/move_library.tres").find("strike")])
	var snapshot := battle.view_snapshot()
	var plan := battle.plan_enemy()
	check(plan.cell != battle.enemy_cell and TacticalBattle.distance(plan.cell, battle.ally_cell) > TacticalBattle.distance(battle.enemy_cell, battle.ally_cell), "Enemy takes a legal detour rather than stalling at the near wall")
	check(snapshot == battle.view_snapshot() and plan == battle.plan_enemy(), "Approach planning is read-only and deterministic")
	for y in range(-4, 5): battle.cells[Vector2i(0, y)] = false
	check(battle.approach_route("enemy").is_empty() and battle.plan_enemy().cell == battle.enemy_cell, "An unreachable opponent does not cause anchor-chasing oscillation")
	playback.bind(battle, tuning)
	metrics = BattlePacingMeasurement.new()
	metrics.bind(playback, {"test": "harmless_exchange"}, true)
	battle.turn = "ally"
	battle.queue.assign(["ally", "enemy"])
	for repeat in range(6):
		playback.submit("wait")
		drain(playback, metrics)
	check(metrics.repeated_states >= 4 and metrics.longest_damage_free_streak == 6, "Unreachable harmless exchanges are flagged without changing combat rules")
	metrics.unbind()
	playback.reset()
	var invalid := recipe.duplicate(true) as CombatPacingFixture
	invalid.opponent_moves = PackedStringArray(["missing"])
	check(not invalid.valid() and invalid.build() == null, "Bad fixture move references reject before simulation")
	print("COMBAT PACING: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
