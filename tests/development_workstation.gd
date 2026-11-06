extends SceneTree
var failures := 0

func check(condition: bool, text: String) -> void:
 if not condition:
  failures += 1
  push_error(text)

func _initialize() -> void:
 create_timer(40).timeout.connect(func(): quit(1))
 run.call_deferred()

func run() -> void:
 var lab: Control = load("res://scenes/development_workstation.tscn").instantiate()
 lab.session_path = "res://artifacts/development-workstation/test-session-%d.cfg" % Time.get_ticks_usec()
 root.add_child(lab)
 await process_frame
 check(lab.fixture != null, "Default fixture loads")
 check(lab.viewport.own_world_3d, "Fixture has a separate 3D world")
 for path in lab.FIXTURES.values():
  check(ResourceLoader.exists("res://scenes/%s.tscn" % path), "Registered fixture exists: " + path)
 lab.set_paused(true)
 check(lab.fixture.process_mode == Node.PROCESS_MODE_DISABLED, "Pause stops fixture subtree")
 check(lab.fixture.particles.speed_scale == 0.0, "Pause stops GPU particle clock")
 lab.notes.text = "Test note"
 var data: Dictionary = lab.report()
 check(data.notes == "Test note" and data.fixture == "vastra_particle_lab", "Report includes review context")
 check(not data.controls.is_empty(), "Report includes live fixture controls")
 check(data.readings.plants.size() == 5, "Report includes plant numerical readings")
 var previous: Node = lab.fixture
 lab.overrides["max_members"] = 128
 lab.load_fixture()
 check(lab.fixture != previous and lab.fixture.max_members == 128, "Reset rebuilds with test overrides")
 check(lab.paused and lab.fixture.process_mode == Node.PROCESS_MODE_DISABLED, "Reset preserves pause")
 lab.picker.select(7)
 lab.overrides.clear()
 lab.load_fixture()
 check(lab.fixture.get_script().resource_path.ends_with("sol_model_workshop.gd"), "Switch loads a different fixture")
 lab.set_paused(false)
 check(lab.fixture.process_mode == Node.PROCESS_MODE_INHERIT, "Resume restores processing")
 # Review journey: tuning, baseline, switching, undo, presets and disk restore.
 lab.picker.select(lab.FIXTURES.keys().find("Grass / single blades"))
 lab.load_fixture()
 lab.notes.text = "Grass review"
 lab.fixture.yaw = 0.7
 lab.fixture.update_camera()
 lab.set_baseline()
 lab.overrides["blade_height"] = 0.8
 lab.load_fixture()
 check(is_equal_approx(lab.fixture.yaw, 0.7), "Tuning retains orbit state")
 check(not lab.baseline.is_empty(), "Tuning retains comparison baseline")
 lab.picker.select(0)
 lab.load_fixture()
 check(lab.station_box.get_child_count() == 1, "Vastra controls are docked outside preview")
 lab.fixture.controls["Opacity"].value = 0.35
 lab.fixture.plant_nodes.source.select(1)
 lab.fixture.plant_nodes.source.item_selected.emit(1)
 lab.notes.text = "Vastra review"
 lab.picker.select(lab.FIXTURES.keys().find("Grass / single blades"))
 lab.load_fixture()
 check(lab.notes.text == "Grass review" and is_equal_approx(lab.fixture.blade_height, 0.8), "Each station restores its notes and tuning")
 check(not lab.baseline.is_empty(), "Switching retains station baseline")
 lab.restore_baseline()
 check(is_equal_approx(lab.fixture.blade_height, 0.5), "Baseline restores authored settings")
 lab.picker.select(0)
 lab.load_fixture()
 check(lab.notes.text == "Vastra review" and is_equal_approx(lab.fixture.controls["Opacity"].value, 0.35), "Docked live controls survive station switch")
 check(lab.fixture.plant_nodes.source.selected == 1, "Endpoint selector survives station switch")
 lab.preset_name.text = "Test setup"
 lab.save_preset()
 lab.fixture.controls["Opacity"].value = 0.7
 lab.load_preset()
 check(is_equal_approx(lab.fixture.controls["Opacity"].value, 0.35), "Named preset restores docked controls")
 lab.restore_defaults()
 check(not is_equal_approx(lab.fixture.controls["Opacity"].value, 0.35), "Restore defaults resets live station tuning")
 lab.undo_tuning()
 check(is_equal_approx(lab.fixture.controls["Opacity"].value, 0.35), "Undo restores live controls after default reset")
 lab.set_paused(false)
 lab.begin_measurement()
 lab.set_paused(true)
 lab.update_measurement(0.1)
 check(not lab.measuring, "Pause interrupts measurement")
 lab.set_paused(false)
 lab.begin_measurement()
 lab.fixture.yaw += 0.1
 lab.update_measurement(0.1)
 check(not lab.measuring, "Camera changes invalidate a measurement window")
 lab.save_workspace()
 var saved_path: String = lab.session_path
 lab.queue_free()
 await process_frame
 var restored: Control = load("res://scenes/development_workstation.tscn").instantiate()
 restored.session_path = saved_path
 root.add_child(restored)
 check(restored.notes.text == "Vastra review" and is_equal_approx(restored.fixture.controls["Opacity"].value, 0.35), "Local workspace survives reopening")
 check(restored.baseline.is_empty(), "Reports without baseline images are not restored from disk")
 restored.queue_free()
 DirAccess.remove_absolute(saved_path)
 await process_frame
 print("WORKSTATION: %d failures" % failures)
 quit(1 if failures else 0)
