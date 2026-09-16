tool
extends Reference

# Minimal Firebase Realtime Database REST client for Godot 3.x.
# It expects a Firebase Authentication ID token when database rules require auth.
# It stores no service-account credentials.

signal request_completed(request_name, success, data)

var database_url = ""
var auth_manager = null

func setup(firebase_auth_manager):
	auth_manager = firebase_auth_manager
	if auth_manager:
		database_url = auth_manager.get_database_url()

func configure(url):
	database_url = str(url).rstrip("/")

func _build_url(path):
	var clean_path = str(path).trim_prefix("/").trim_suffix("/")
	var url = database_url + "/" + clean_path + ".json"
	if auth_manager and auth_manager.get_id_token() != "":
		url += "?auth=" + str(auth_manager.get_id_token()).http_escape()
	return url

func _request(request_name, method, path, body = null):
	var http = HTTPRequest.new()
	var tree = Engine.get_main_loop()
	if tree and tree.root:
		tree.root.add_child(http)
	else:
		return false

	var headers = ["Content-Type: application/json"]
	var payload = ""
	if body != null:
		payload = JSON.print(body)

	var error = http.request(_build_url(path), headers, true, method, payload)
	if error != OK:
		http.queue_free()
		return false

	var result = yield(http, "request_completed")
	var response_code = int(result[1])
	var response_body = result[3].get_string_from_utf8()
	var parsed = null
	if response_body != "":
		parsed = JSON.parse(response_body).result

	var success = response_code >= 200 and response_code < 300
	emit_signal("request_completed", request_name, success, parsed)
	http.queue_free()
	return success

func get_path(path):
	return _request("get:" + str(path), HTTPClient.METHOD_GET, path)

func put_path(path, data):
	return _request("put:" + str(path), HTTPClient.METHOD_PUT, path, data)

func patch_path(path, data):
	return _request("patch:" + str(path), HTTPClient.METHOD_PATCH, path, data)

func delete_path(path):
	return _request("delete:" + str(path), HTTPClient.METHOD_DELETE, path)

func save_user(user_data):
	if not user_data.has("firebase_uid"):
		return false
	return put_path("users/" + str(user_data["firebase_uid"]), user_data)

func load_user(firebase_uid):
	return get_path("users/" + str(firebase_uid))

func load_user_workspace_index(firebase_uid):
	return get_path("user_workspaces/" + str(firebase_uid))

func save_workspace(workspace_id, workspace_data):
	return put_path("workspaces/" + str(workspace_id), workspace_data)

func load_workspace(workspace_id):
	return get_path("workspaces/" + str(workspace_id))

func save_membership(workspace_id, firebase_uid, membership):
	return put_path("workspaces/%s/members/%s" % [str(workspace_id), str(firebase_uid)], membership)

func load_membership(workspace_id, firebase_uid):
	return get_path("workspaces/%s/members/%s" % [str(workspace_id), str(firebase_uid)])
