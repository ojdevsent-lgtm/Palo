tool
extends Reference

# Coordinates Palo account and workspace metadata stored in Firebase.
# Firebase Authentication is the identity layer; GitHub remains the source
# control provider. Subscription and membership enforcement must ultimately be
# performed by a trusted backend, not this client.

signal profile_loaded(success, data)
signal profile_saved(success, data)
signal workspace_created(success, data)
signal workspace_loaded(success, data)

var auth = null
var database = null
var account = null
var workspace_manager = null

func setup(firebase_auth_manager, firebase_database, palo_account, local_workspace_manager):
    auth = firebase_auth_manager
    database = firebase_database
    account = palo_account
    workspace_manager = local_workspace_manager
    if database and not database.is_connected("request_completed", self, "_on_database_request"):
        database.connect("request_completed", self, "_on_database_request")

func is_ready():
    return auth != null and database != null and account != null

func sign_in_with_github_token(github_access_token):
    if not auth:
        emit_signal("profile_loaded", false, {"error": "Firebase auth service is unavailable."})
        return false
    if auth.is_signed_in():
        return true
    return auth.exchange_github_token(github_access_token)

func save_current_profile(extra_data = {}):
    if not is_ready() or not auth.is_signed_in():
        emit_signal("profile_saved", false, {"error": "Not signed in to Palo."})
        return false
    account.set_firebase_user(auth.get_user())
    var data = account.get_data()
    for key in extra_data.keys():
        data[key] = extra_data[key]
    data["last_seen_at"] = OS.get_unix_time()
    return database.save_user(data)

func load_current_profile():
    if not is_ready() or not auth.is_signed_in():
        emit_signal("profile_loaded", false, {"error": "Not signed in to Palo."})
        return false
    return database.load_user(auth.get_uid())

func create_workspace(workspace_name, engine_id, engine_version, repository_full_name = ""):
    if not is_ready() or not auth.is_signed_in():
        emit_signal("workspace_created", false, {"error": "Sign in to Palo before creating a workspace."})
        return false
    if workspace_manager == null:
        emit_signal("workspace_created", false, {"error": "Workspace manager is unavailable."})
        return false

    var workspace_id = "%s-%s" % [auth.get_uid(), str(OS.get_unix_time())]
    var data = workspace_manager.create_local_workspace(
        workspace_name,
        auth.get_uid(),
        engine_id,
        engine_version
    )
    data["id"] = workspace_id
    data["members"] = {}
    data["members"][auth.get_uid()] = {
        "role": "owner",
        "joined_at": OS.get_unix_time()
    }
    if repository_full_name != "":
        data["repository"] = {
            "provider": "github",
            "full_name": repository_full_name
        }

    return database.save_workspace(workspace_id, data)

func load_workspace(workspace_id):
    if not is_ready() or not auth.is_signed_in():
        emit_signal("workspace_loaded", false, {"error": "Not signed in to Palo."})
        return false
    return database.load_workspace(workspace_id)

func _on_database_request(request_name, success, data):
    var name = str(request_name)
    if name.begins_with("get:users/"):
        emit_signal("profile_loaded", success, data)
    elif name.begins_with("put:users/"):
        emit_signal("profile_saved", success, data)
    elif name.begins_with("get:workspaces/"):
        emit_signal("workspace_loaded", success, data)
    elif name.begins_with("put:workspaces/"):
        emit_signal("workspace_created", success, data)
