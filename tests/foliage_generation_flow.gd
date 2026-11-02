extends "res://tests/plant_diversity.gd"

func source() -> ExpeditionState:
	var state := ExpeditionState.new(17)
	var policy := (load("res://resources/vastra_settings.tres") as VastraSettings).plant_parameters()
	policy.repair_points = 0
	state.configure_flora(policy)
	state.admit_flora([{"id":"0:0","cell":[0,0],"kind":"plant"}])
	state.set_flora_active(["0:0"])
	return state

func environment(_at: Vector2i) -> Dictionary: return {"concentration":100,"overload":0}
func trees(_at: Vector2i,_reach: float) -> Array[Dictionary]: return []

func run() -> void:
	var flow := source()
	var baseline := source()
	var quantum := ExpeditionContract.ACTIVITY_INTERVAL/6.0
	var gain_per_step := float(flow.flora_view().policy.refill)*quantum
	for index in range(24):
		flow.advance_time(quantum)
		if (index+1)%6 == 0: flow.advance_flora(trees,environment)
		flow.advance_flora_refill(environment)
		check(is_equal_approx(flow.flora_reading(Vector2i.ZERO).energy,float(index+1)*gain_per_step),"Generation credits small real packets at the unchanged rate")
		check(PlantVastra.valid(flow.flora_view(),flow.activity_tick()),"Sub-tick generation remains conserved and save-valid")
		if (index+1)%6 == 0:
			baseline.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
			baseline.advance_flora(trees,environment)
			check(is_equal_approx(flow.flora_reading(Vector2i.ZERO).energy,baseline.flora_reading(Vector2i.ZERO).energy),"Smaller increments preserve the original accumulated amount at every ecology tick")
	var full_flow := source()
	var full_baseline := source()
	var intervals := ceili(100.0/(float(full_flow.flora_view().policy.refill)*ExpeditionContract.ACTIVITY_INTERVAL))
	for interval in range(intervals):
		for part in range(6):
			full_flow.advance_time(quantum)
			if part == 5: full_flow.advance_flora(trees,environment)
			full_flow.advance_flora_refill(environment)
		full_baseline.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
		full_baseline.advance_flora(trees,environment)
		check(is_equal_approx(full_flow.flora_reading(Vector2i.ZERO).energy,full_baseline.flora_reading(Vector2i.ZERO).energy),"Full charge keeps the same totals through every original accumulation interval")
	check(full_flow.flora_reading(Vector2i.ZERO).energy == 100.0 and full_baseline.flora_reading(Vector2i.ZERO).energy == 100.0,"Both generation schedules reach full reserve within the same original accumulation interval")
	flow.advance_time(0.03)
	var resumed := ExpeditionState.restore(JSON.parse_string(JSON.stringify(flow.snapshot())),17)
	check(resumed != null,"Save admission accepts fractional generation progress")
	var future := flow.snapshot()
	future.flora.nodes["0:0"].refill_since = flow.activity_seconds()+0.1
	check(ExpeditionState.restore(future,17) == null,"Save admission rejects refill credit timestamps ahead of the saved clock")
	resumed.set_flora_active(["0:0"])
	for state in [flow,resumed]:
		state.advance_time(quantum)
		state.advance_flora_refill(environment)
	check(flow.snapshot().flora == resumed.snapshot().flora,"Mid-step reload preserves fractional refill without duplicate or lost energy")
	var before := flow.snapshot()
	flow.advance_flora_refill(environment)
	check(flow.snapshot() == before,"Repeated updates during pause cannot generate energy")
	flow.set_flora_active([])
	flow.advance_time(15.0)
	flow.set_flora_active(["0:0"])
	var retained: float = flow.flora_reading(Vector2i.ZERO).energy
	flow.advance_flora_refill(environment)
	check(flow.flora_reading(Vector2i.ZERO).energy == retained,"Reactivation grants no offline generation")
	var terrain := FlatTerrain.new(18)
	terrain.kind = "plant"
	terrain.flora_specialist_percent = 100
	var found := false
	for x in range(40,65):
		var cell := Vector2i(x,60)
		var normal := Library.placement(terrain,cell,terrain.sample(cell),"plant",true,0.0,0.0,1.0)
		var larger := Library.placement(terrain,cell,terrain.sample(cell),"plant",true,0.0,0.0,2.0)
		if normal.is_empty() or larger.is_empty(): continue
		check(larger.transform.basis.get_scale().is_equal_approx(normal.transform.basis.get_scale()*2.0),"Foliage is twice its previous scale where terrain clearance permits")
		check(normal.flora_id == larger.flora_id and normal.cell == larger.cell,"Larger foliage retains its canonical identity and ground cell")
		found = true
		break
	check(found and NatureSettings.new().foliage_size_multiplier == 2.0,"The connected foliage size control defaults to double")
	print("FOLIAGE GENERATION FLOW: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
