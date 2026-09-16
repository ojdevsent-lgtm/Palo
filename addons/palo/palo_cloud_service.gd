tool
extends Reference

# Palo cloud coordinator. Firebase Authentication supplies identity and the
# Realtime Database stores account/workspace metadata. Membership changes and
# workspace creation go through trusted Firebase callable functions.

signal profile_loaded(success, data)
signal profile_saved(success, data)
signal workspace_created(success, data)
signal workspace_loaded(success, data)
signal workspace_index_loaded(success, data)

var auth = null
var database = null
var account = null
var workspace_manager = null
var functions_region = "us-central1"
var functions_http = null
var pending_function = ""

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

func load_workspace_index():
	if not is_ready() or not auth.is_signed_in():
		emit_signal("workspace_index_loaded", false, {"error": "Not signed in to Palo."})
		return false
	return database.load_user_workspace_index(auth.get_uid())

func create_workspace(workspace_name, engine_id, engine_version, repository_full_name = ""):
	if not is_ready() or not auth.is_signed_in():
		emit_signal("workspace_created", false, {"error": "Sign in to Palo before creating a workspace."})
		return false
	if repository_full_name == "":
		emit_signal("workspace_created", false, {"error": "A GitHub repository is required."})
		return false
	return _call_function("createWorkspace", {
		"name": str(workspace_name),
		"engine": str(engine_id),
		"engineVersion": str(engine_version),
		"repository": str(repository_full_name)
	})

func load_workspace(workspace_id):
	if not is_ready() or not auth.is_signed_in():
		emit_signal("workspace_loaded", false, {"error": "Not signed in to Palo."})
		return false
	return database.load_workspace(workspace_id)

func _call_function(function_name, data):
	if not auth or not auth.is_signed_in():
		return false
	var tree = Engine.get_main_loop()
	if not tree or not tree.root:
		return false
	if functions_http:
		functions_http.queue_free()
	functions_http = HTTPRequest.new()
	tree.root.add_child(functions_http)
	pending_function = str(function_name)
	var project_id = str(auth.get_config().get("projectId", ""))
	if project_id == "":
		emit_signal("workspace_created", false, {"error": "Firebase project ID is missing."})
		return false
	var url = "https://%s-%s.cloudfunctions.net/%s" % [functions_region, project_id, function_name]
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + auth.get_id_token()
	]
	var body = JSON.print({"data": data})
	var error = functions_http.request(url, headers, true, HTTPClient.METHOD_POST, body)
	if error != OK:
		functions_http.queue_free()
		functions_http = null
		emit_signal("workspace_created", false, {"error": "Could not start Firebase backend request (%s)." % error})
		return false

	var result = yield(functions_http, "request_completed")
	var response_code = int(result[1])
	var response_body = result[3].get_string_from_utf8()
	functions_http.queue_free()
	functions_http = null
	var parsed = null
	if response_body != "":
		parsed = JSON.parse(response_body).result
	var success = response_code >= 200 and response_code < 300
	if not success:
		var message = "Firebase backend request failed (HTTP %d)." % response_code
		if typeof(parsed) == TYPE_DICTIONARY and parsed.has("error"):
			message = str(parsed["error"].get("message", message))
		emit_signal("workspace_created", false, {"error": message})
		return false
	emit_signal("workspace_created", true, parsed.get("data", parsed) if typeof(parsed) == TYPE_DICTIONARY else parsed)
	return true

func _on_database_request(request_name, success, data):
	var name = str(request_name)
	if name.begins_with("get:users/"):
		emit_signal("profile_loaded", success, data)
	elif name.begins_with("put:users/"):
		emit_signal("profile_saved", success, data)
	elif name.begins_with("get:user_workspaces/"):
		emit_signal("workspace_index_loaded", success, data)
	elif name.begins_with("get:workspaces/"):
		emit_signal("workspace_loaded", success, data)
