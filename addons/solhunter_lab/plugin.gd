@tool
extends EditorPlugin
## Editor integration only. Runtime fixtures never enter the editor SceneTree.
const Workspace = preload("res://addons/solhunter_lab/editor/workspace.gd")
const ExportFilter = preload("res://addons/solhunter_lab/editor/export_filter.gd")
var workspace: Control
var export_filter: EditorExportPlugin
var prior_distraction_mode := false
var lab_owns_layout := false

func _enter_tree() -> void:
	export_filter = ExportFilter.new()
	add_export_plugin(export_filter)
	workspace = Workspace.new()
	workspace.name = "SolHunterLab"
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	EditorInterface.get_editor_main_screen().add_child(workspace)
	workspace.hide()
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_refresh_catalogue)

func _exit_tree() -> void:
	_make_visible(false)
	if export_filter != null:
		remove_export_plugin(export_filter)
		export_filter = null
	var filesystem := EditorInterface.get_resource_filesystem()
	if filesystem.filesystem_changed.is_connected(_refresh_catalogue):
		filesystem.filesystem_changed.disconnect(_refresh_catalogue)
	if is_instance_valid(workspace):
		workspace.shutdown_bridge()
		workspace.get_parent().remove_child(workspace)
		workspace.queue_free()
	workspace = null

func _has_main_screen() -> bool:
	return true

func _get_plugin_name() -> String:
	return "SolHunter Lab"

func _make_visible(showing: bool) -> void:
	if showing and not lab_owns_layout:
		prior_distraction_mode = EditorInterface.distraction_free_mode
		EditorInterface.distraction_free_mode = true
		lab_owns_layout = true
	elif not showing and lab_owns_layout:
		EditorInterface.distraction_free_mode = prior_distraction_mode
		lab_owns_layout = false
	if is_instance_valid(workspace):
		workspace.visible = showing

func _refresh_catalogue() -> void:
	if is_instance_valid(workspace):
		workspace.queue_catalogue_refresh()
