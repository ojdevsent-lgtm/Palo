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
var cloud_service = null

func _enter_tree():
	git = preload("res://addons/palo/git_manager.gd").new()
	github = preload("res://addons/palo/github_client.gd").new()
	settings = preload("res://addons/palo/settings_manager.gd").new()
	firebase_auth = preload("res://addons/palo/firebase_auth_manager.gd").new()
	firebase_database = preload("res://addons/palo/firebase_database.gd").new()
	palo_account = preload("res://addons/palo/palo_account.gd").new()
	workspace_manager = preload("res://addons/palo/workspace_manager.gd").new()
	cloud_service = preload("res://addons/palo/palo_cloud_service.gd").new()

	_load_firebase_user_config()
	firebase_database.setup(firebase_auth)
	cloud_service.setup(firebase_auth, firebase_database, palo_account, workspace_manager)

	panel = preload("res://addons/palo/palo_panel.gd").new()
	panel.setup(git, github, settings)
	panel.setup_platform_services(cloud_service, palo_account, workspace_manager)
	github.setup(panel)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, panel)

	github.connect("auth_succeeded", self, "_on_github_auth_succeeded")
	firebase_auth.connect("auth_succeeded", self, "_on_firebase_auth_succeeded")
	firebase_auth.connect("auth_failed", self, "_on_firebase_auth_failed")

func _load_firebase_user_config():
	var file = File.new()
	if file.file_exists("user://palo_firebase.json"):
		if file.open("user://palo_firebase.json", File.READ) == OK:
			var parsed = JSON.parse(file.get_as_text())
			file.close()
			if parsed.error == OK and typeof(parsed.result) == TYPE_DICTIONARY:
				firebase_auth.configure(parsed.result)

func _on_github_auth_succeeded(access_token):
	panel.set_platform_status("GitHub connected. Signing in to Palo...")
	if not firebase_auth.is_configured():
		panel.set_platform_status("GitHub connected. Add Firebase apiKey to user://palo_firebase.json to enable Palo account sync.")
		return
	firebase_auth.exchange_github_token(access_token)

func _on_firebase_auth_succeeded(user_data, id_token):
	palo_account.set_firebase_user(user_data)
	panel.set_platform_account(palo_account)
	panel.set_platform_status("Palo account connected. Syncing your profile...")
	cloud_service.save_current_profile({
		"github_username": str(user_data.get("github_username", ""))
	})
	panel.load_cloud_workspaces()

func _on_firebase_auth_failed(message):
	panel.set_platform_status("Palo account sign-in failed: " + str(message))

func _exit_tree():
	if panel:
		remove_control_from_docks(panel)
		panel.queue_free()
		panel = null
	cloud_service = null
	firebase_database = null
	firebase_auth = null
	palo_account = null
	workspace_manager = null
	github = null
	settings = null
	git = null
