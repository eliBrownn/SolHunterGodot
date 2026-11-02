extends SceneTree

var failed := false

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failed = true

func _initialize() -> void:
	var settings := AtmosphereSettings.new()
	var base := Vector2(0.1, 0.035)
	var peak := settings.airflow(base, settings.wind_cycle_seconds * 0.25)
	var trough := settings.airflow(base, settings.wind_cycle_seconds * 0.75)
	check(settings.valid(), "Wind defaults validate")
	check(peak.length() > base.length() and trough.length() < peak.length(), "Wind builds to a stronger peak and eases")
	check(peak.normalized().is_equal_approx(base.normalized()), "Changing strength preserves shared direction")
	check(peak == settings.airflow(base, settings.wind_cycle_seconds * 0.25), "Same saved time freezes/reconstructs airflow")
	check(settings.airflow(Vector2.ZERO, 6.0) == Vector2.ZERO, "Zero base wind remains calm")
	var grass = preload("res://scripts/scenery/meadow_art.gd")
	grass.mesh()
	grass.set_weather(peak, 0.0, 6.0)
	var high: float = grass.material.get_shader_parameter("wind_strength")
	grass.set_weather(trough, 0.0, 18.0)
	check(high > float(grass.material.get_shader_parameter("wind_strength")), "Grass follows airflow magnitude instead of steady motion")
	settings.wind_variation = 0.0
	check(settings.airflow(base, 0.0) == settings.airflow(base, 12.0), "Zero variation provides steady wind")
	settings.wind_strength = 0.0
	check(settings.airflow(base, 6.0) == Vector2.ZERO, "Zero strength disables wind")
	settings.wind_cycle_seconds = 0.0
	check(not settings.valid(), "Invalid cycle is rejected")
	print("WIND PRESENTATION: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
