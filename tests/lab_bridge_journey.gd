extends SceneTree
## Rendered production-fixture journey through the same bridge used by the editor.
const Client = preload("res://addons/solhunter_lab/editor/bridge_client.gd")
const Catalogue = preload("res://tools/lab_station_catalogue.gd")
var client = Client.new()
var failures := 0
var evidence: Array[Dictionary] = []
var pictures := "res://artifacts/lab-phase-review"

func _initialize() -> void:
	create_timer(900 if "--all-stations" in OS.get_cmdline_user_args() else 300).timeout.connect(func(): client.send({"command":"close"}); quit(1))
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _process(_delta: float) -> bool:
	client.poll()
	return false

func wait_ready() -> bool:
	for attempt in range(1200):
		await create_timer(0.05).timeout
		client.poll()
		if client.connected and not client.busy: return true
	print("Bridge timeout: ", client.message, " connected=", client.connected, " busy=", client.busy, " log=", client.runtime_log)
	return false

func inspect() -> Dictionary:
	client.inspection = {}
	client.send({"command":"inspect"})
	for attempt in range(200):
		await create_timer(0.025).timeout
		client.poll()
		if not client.inspection.is_empty(): return client.inspection.duplicate(true)
	check(false, "Inspection arrived")
	print("Inspection timeout: ", client.message, "; protocol failed=", client.wire.failed, "; connected=", client.connected, "; runtime log=", client.runtime_log)
	return {}

func picture(name: String) -> void:
	var revision: int = client.image_revision
	client.request_frame()
	for attempt in range(400):
		await create_timer(0.025).timeout
		client.poll()
		if client.image_revision > revision: break
	check(client.latest_image != null, "Rendered preview for " + name)
	if client.latest_image != null: client.latest_image.save_png(pictures.path_join(name + ".png"))
	evidence.append({"station": name, "metrics": client.metrics.duplicate(true)})

func run() -> void:
	DirAccess.make_dir_recursive_absolute(pictures)
	client.workspace_path = pictures.path_join("workspace.cfg")
	check(client.start(Catalogue.find("plants.maker")), "Start Plant Maker bridge")
	check(await wait_ready(), "Plant Maker ready")
	var before := await inspect()
	if before.is_empty(): client.send({"command":"close"}); quit(1); return
	client.send({"command":"parameter", "key":"wind_strength", "value":0.9})
	await create_timer(0.5).timeout
	var after := await inspect()
	check(before.fixture_id == after.fixture_id, "Presentation tuning retains fixture instance")
	check(before.geometry == after.geometry, "Presentation tuning retains generated geometry")
	check(is_equal_approx(float(after.settings.wind_strength), 0.9), "Authoritative setting applies")
	client.send({"command":"action", "action":"undo"})
	await create_timer(0.4).timeout
	var undone := await inspect()
	check(is_equal_approx(float(undone.settings.wind_strength), float(before.settings.wind_strength)), "Undo restores the prior setting")
	check(undone.fixture_id == before.fixture_id, "Undo retains the authoring scene")
	client.send({"command":"action", "action":"baseline"})
	await create_timer(0.3).timeout
	check(bool((await inspect()).baseline), "Before/after comparison is available")
	await picture("plant-maker")
	for id in ["grass_blade_preview", "vastra_particle_lab", "cohesive_world_sample", "sols.authoring"]:
		client.start(Catalogue.find(id))
		check(await wait_ready(), "Station ready: " + id)
		var state := await inspect()
		check(state.get("station") == id, "Selected station is active: " + id)
		await picture(id)
	client.send({"command":"suspend", "value":true})
	await create_timer(0.5).timeout
	var hidden := await inspect()
	check(bool(hidden.suspended) and not bool(hidden.rendering_enabled), "Hidden preview suspends simulation and rendering")
	client.send({"command":"suspend", "value":false})
	if "--all-stations" in OS.get_cmdline_user_args():
		for entry in Catalogue.discover().stations:
			if entry.get("host") != "workstation" or entry.id in ["plants.maker", "grass_blade_preview", "vastra_particle_lab", "cohesive_world_sample"]: continue
			print("LAB ADMISSION: ", entry.id)
			client.start(entry)
			check(await wait_ready(), "Registered station ready: " + str(entry.id))
			var state := await inspect()
			check(state.get("station") == entry.id, "Registered station is active: " + str(entry.id))
			var record := FileAccess.open(pictures.path_join(str(entry.id) + "-controls.json"), FileAccess.WRITE)
			record.store_string(JSON.stringify(state, "  "))
			record.close()
			await picture(str(entry.id))
	client.start(Catalogue.find("plants.maker"))
	check(await wait_ready(), "Return to saved Plant Maker workspace")
	check((await inspect()).station == "plants.maker", "Return restores the correct authoring owner")
	client.send({"command":"save"})
	client.send({"command":"close"})
	await create_timer(1.0).timeout
	check(not client.connected, "Graceful close completes")
	var runtime_log := FileAccess.get_file_as_string(client.runtime_log)
	check(not "SCRIPT ERROR:" in runtime_log and not "ERROR:" in runtime_log, "Runtime fixture log contains no engine/script errors")
	var report := FileAccess.open(pictures.path_join("journey.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures": failures, "evidence": evidence}, "  "))
	report.close()
	print("LAB BRIDGE JOURNEY: ", failures, " failures")
	quit(1 if failures else 0)
