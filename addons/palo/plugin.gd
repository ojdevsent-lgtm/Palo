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
    github.setup(panel)
    panel.setup(git, github, settings)
    add_control_to_dock(DOCK_SLOT_RIGHT_UL, panel)

    github.connect("auth_succeeded", self, "_on_github_auth_succeeded")
    firebase_auth.connect("auth_succeeded", self, "_on_firebase_auth_succeeded")
    firebase_auth.connect("auth_failed", self, "_on_firebase_auth_failed")

func _load_firebase_user_config():
    var path = "user://palo_firebase.json"
    var file = File.new()
    if not file.file_exists(path):
        return
    if file.open(path, File.READ) != OK:
        return
    var parsed = JSON.parse(file.get_as_text())
    file.close()
    if parsed.error == OK and typeof(parsed.result) == TYPE_DICTIONARY:
        firebase_auth.configure(parsed.result)

func _on_github_auth_succeeded(access_token):
    if panel:
        panel._set_status("GitHub connected. Creating/checking your Palo account...")
    if not firebase_auth.is_configured():
        if panel:
            panel._set_status("GitHub connected. Firebase is not configured yet. Add user://palo_firebase.json using docs/firebase-setup.md, then reconnect.")
        return
    cloud_service.sign_in_with_github_token(access_token)

func _on_firebase_auth_succeeded(user_data, id_token):
    palo_account.set_firebase_user(user_data)
    cloud_service.save_current_profile({
        "github_username": str(user_data.get("github_username", "")),
        "platform": "palo"
    })
    if panel:
        panel._set_status("Palo account connected as " + str(user_data.get("email", user_data.get("display_name", "user"))) + ". GitHub remains connected for repository access.")

func _on_firebase_auth_failed(message):
    if panel:
        panel._set_status("GitHub is connected, but Palo Firebase account sign-in failed: " + str(message))

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
