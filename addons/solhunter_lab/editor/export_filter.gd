@tool
extends EditorExportPlugin
## Editor tooling never becomes a release dependency.
const Catalogue = preload("res://tools/lab_station_catalogue.gd")
var station_scenes: Dictionary = {}

func _get_name() -> String:
	# Godot sorts export plugins by name. Run before its "GDScript" plugin,
	# so skip() prevents both bytecode generation and companion remap files.
	return "000_SolHunterLabEditorOnly"

func _export_begin(_features: PackedStringArray, _debug: bool, _path: String, _flags: int) -> void:
	station_scenes.clear()
	for entry in Catalogue.discover().stations: station_scenes[entry.scene] = true
	station_scenes["res://scenes/development_workstation.tscn"] = true
	station_scenes["res://scenes/sol_lab.tscn"] = true

func _export_file(path: String, _type: String, _features: PackedStringArray) -> void:
	if path.begins_with("res://addons/solhunter_lab/") or path.begins_with("res://tests/") or station_scenes.has(path):
		skip()
	elif path.begins_with("res://tools/") and path != "res://tools/bake_runtime_plants.gd":
		# PlantLibrary currently hashes this bake source as part of cache admission.
		# Preserve it until that runtime signature contract is deliberately changed.
		skip()
