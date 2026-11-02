extends RefCounted
## Copy-on-first-use migration; never replace an existing authoring workspace.
static func seed_workspace(source: String, target: String) -> Dictionary:
	if FileAccess.file_exists(target) or not FileAccess.file_exists(source): return {"copied": false}
	var folder := ProjectSettings.globalize_path(target.get_base_dir())
	if DirAccess.make_dir_recursive_absolute(folder) != OK: return {"error": "Cannot create the editor workspace folder."}
	var source_hash := FileAccess.get_sha256(source)
	if DirAccess.copy_absolute(ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(target)) != OK:
		return {"error": "Cannot copy the standalone workspace. The original remains unchanged."}
	var marker := FileAccess.open(target + ".migration.json", FileAccess.WRITE)
	if marker == null: return {"error": "Workspace copied, but its migration record could not be written. Originals are unchanged."}
	marker.store_string(JSON.stringify({"version": 1, "source": source, "source_sha256": source_hash, "target": target, "copied_at": Time.get_datetime_string_from_system()}, "  "))
	marker.close()
	return {"copied": true}
