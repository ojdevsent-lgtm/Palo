tool
extends EditorPlugin

var panel = null
var git = null
var github = null
var settings = null
var firebase_auth = null
var firebase_database = null
var palo_account = null
var workspace_manager = null

func _enter_tree():
	git = preload("res://addons/palo/git_manager.gd").new()
	github = preload("res://addons/palo/github_client.gd").new()
	settings = preload("res://addons/palo/settings_manager.gd").new()
	firebase_auth = preload("res://addons/palo/firebase_auth_manager.gd").new()
	firebase_database = preload("res://addons/palo/firebase_database.gd").new()
	palo_account = preload("res://addons/palo/palo_account.gd").new()
	workspace_manager = preload("res://addons/palo/workspace_manager.gd").new()

	github.setup(panel)
	firebase_database.setup(firebase_auth)
	panel = preload("res://addons/palo/palo_panel.gd").new()
	github.setup(panel)
	panel.setup(git, github, settings)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, panel)

func _exit_tree():
	if panel:
		remove_control_from_docks(panel)
		panel.queue_free()
		panel = null
	firebase_database = null
	firebase_auth = null
	palo_account = null
	workspace_manager = null
	github = null
	settings = null
	git = null
