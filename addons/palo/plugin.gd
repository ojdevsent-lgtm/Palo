tool
extends EditorPlugin

var panel = null
var git = null
var status_label = null

func _enter_tree():
	git = preload("res://addons/palo/git_manager.gd").new()
	panel = preload("res://addons/palo/palo_panel.gd").new()
	panel.setup(git)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, panel)

func _exit_tree():
	if panel:
		remove_control_from_docks(panel)
		panel.queue_free()
	panel = null
	git = null
