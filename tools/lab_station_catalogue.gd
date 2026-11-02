@tool
extends RefCounted
## Read navigation metadata only; discovering stations never loads their scenes.
const DIRECTORY := "res://addons/solhunter_lab/stations"
static var loaded_snapshots: Dictionary = {}

static func discover(directory: String = DIRECTORY) -> Dictionary:
	var stations: Array[Dictionary] = []
	var errors: Array[String] = []
	var ids := {}
	var files := DirAccess.get_files_at(directory)
	files.sort()
	for filename in files:
		if filename.get_extension() != "json":
			continue
		var path := directory.path_join(filename)
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary:
			errors.append(filename + ": invalid station JSON")
			continue
		var entry: Dictionary = parser.data
		var problem := validate(entry)
		if not problem.is_empty():
			errors.append(filename + ": " + problem)
			continue
		if ids.has(entry.id):
			errors.append(filename + ": duplicate station ID " + entry.id)
			continue
		ids[entry.id] = true
		stations.append(entry)
	stations.sort_custom(func(a: Dictionary, b: Dictionary): return a.domain + a.title < b.domain + b.title)
	return {"stations": stations, "errors": errors}

static func fixture_map() -> Dictionary:
	var entries: Array = discover().stations
	entries.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.get("order", 1000)) < int(b.get("order", 1000)))
	var result := {}
	for entry in entries:
		if entry.has("fixture_key"):
			result[entry.label] = entry.fixture_key
	return result

static func find(id: String) -> Dictionary:
	for entry in discover().stations:
		if entry.id == id: return entry
	return {}

static func fingerprint(entry: Dictionary, loaded_snapshot: bool = false) -> String:
	# Explicit and transitive literal resource references; includes inherited scripts.
	var identity := JSON.stringify(entry).sha256_text()
	if loaded_snapshot and loaded_snapshots.has(identity): return loaded_snapshots[identity]
	var pending: Array[String] = [str(entry.scene)]
	for path in entry.get("dependencies", []): pending.append(str(path))
	if entry.get("host") == "workstation": pending.append("res://tools/development_workstation.gd")
	if entry.has("host"):
		pending.append("res://tools/lab_bridge_runner.gd")
		pending.append("res://tools/lab_bridge_wire.gd")
	var visited := {}
	while not pending.is_empty():
		var path: String = pending.pop_back()
		if visited.has(path) or not FileAccess.file_exists(path): continue
		visited[path] = FileAccess.get_sha256(path)
		for suffix in [".import", ".uid"]:
			if FileAccess.file_exists(path + suffix): visited[path + suffix] = FileAccess.get_sha256(path + suffix)
		if path.get_extension() not in ["gd", "tscn", "tres", "gdshader", "gdshaderinc", "json"]: continue
		var text := FileAccess.get_file_as_string(path)
		var pattern := RegEx.new()
		pattern.compile('res://[A-Za-z0-9_./ -]+\\.(?:gdshaderinc|gdshader|tscn|tres|json|gltf|glb|fbx|obj|jpeg|jpg|png|webp|svg|ogg|wav|res|gd)')
		for match_value in pattern.search_all(text):
			var dependency := match_value.get_string()
			if not visited.has(dependency): pending.append(dependency)
	var paths: Array = visited.keys()
	paths.sort()
	var manifest := JSON.stringify(entry)
	for path in paths: manifest += str(path) + str(visited[path])
	var result := manifest.sha256_text()
	if loaded_snapshot: loaded_snapshots[identity] = result
	return result

static func validate(entry: Dictionary) -> String:
	for key in ["id", "domain", "title", "description", "scene", "storage", "reason"]:
		if not entry.get(key) is String or str(entry[key]).strip_edges().is_empty():
			return "missing text field: " + key
	if entry.get("contract_version") != 1:
		return "unsupported station contract version"
	if entry.get("execution") != "runtime":
		return "only isolated runtime stations are supported in this slice"
	var scene: String = entry.scene
	if not scene.begins_with("res://scenes/") or ".." in scene or scene.get_extension() != "tscn":
		return "scene must be a project fixture under scenes/"
	if not FileAccess.file_exists(scene):
		return "missing fixture: " + scene
	if entry.has("fixture_key") and scene != "res://scenes/" + str(entry.fixture_key) + ".tscn":
		return "fixture key and scene reference disagree"
	if entry.has("host") and entry.host not in ["workstation", "sol", "standalone"]:
		return "unsupported station host"
	if entry.has("dependencies"):
		if not entry.dependencies is Array: return "dependencies must be project path references"
		for dependency in entry.dependencies:
			if not dependency is String or not dependency.begins_with("res://") or not FileAccess.file_exists(dependency): return "missing declared dependency"
	return ""
