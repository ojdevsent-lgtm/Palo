tool
extends EditorPlugin

var panel = null
var git = null
var github = null
var settings = null

func _enter_tree():
	git = preload("res://addons/palo/git_manager.gd").new()
	github = preload("res://addons/palo/github_client.gd").new()
	settings = preload("res://addons/palo/settings_manager.gd").new()
	panel = preload("res://addons/palo/palo_panel.gd").new()
	github.setup(panel)
	panel.setup(git, github, settings)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, panel)

func _exit_tree():
	if panel:
		remove_control_from_docks(panel)
		panel.queue_free()
	panel = null
	github = null
	settings = null
	git = null
