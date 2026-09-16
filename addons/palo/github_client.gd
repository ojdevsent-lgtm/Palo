tool
extends Reference

# Palo GitHub client for Godot 3.x.
# Device flow keeps a client secret out of the desktop plugin.

const API_ROOT = "https://api.github.com"
const DEVICE_URL = "https://github.com/login/device/code"
const TOKEN_URL = "https://github.com/login/oauth/access_token"
const DEVICE_GRANT = "urn:ietf:params:oauth:grant-type:device_code"

var token = ""
var client_id = ""
var http = null
var auth_http = null
var poll_timer = null
var pending_device_code = ""
var pending_interval = 5
var auth_request_kind = ""

signal request_finished(result, response_code, body)
signal auth_started(user_code, verification_uri, expires_in)
signal auth_pending()
signal auth_succeeded(access_token)
signal auth_failed(message)

func setup(owner):
	http = HTTPRequest.new()
	owner.add_child(http)
	http.connect("request_completed", self, "_on_request_completed")
	auth_http = HTTPRequest.new()
	owner.add_child(auth_http)
	auth_http.connect("request_completed", self, "_on_auth_request_completed")
	poll_timer = Timer.new()
	poll_timer.one_shot = true
	owner.add_child(poll_timer)
	poll_timer.connect("timeout", self, "_poll_token")

func set_client_id(value):
	client_id = value.strip_edges()

func set_token(value):
	token = value.strip_edges()

func has_token():
	return token != ""

func start_device_flow():
	if client_id == "":
		emit_signal("auth_failed", "GitHub Client ID is not configured.")
		return
	if auth_http == null:
		emit_signal("auth_failed", "GitHub authentication is not initialized.")
		return
	cancel_auth()
	auth_request_kind = "device"
	var headers = ["Accept: application/json", "Content-Type: application/x-www-form-urlencoded", "User-Agent: Palo-Godot-Plugin"]
	var form = "client_id=" + client_id.http_escape()
	form += "&scope=repo%20read%3Auser"
	var code = auth_http.request(DEVICE_URL, headers, true, HTTPClient.METHOD_POST, form)
	if code != OK:
		emit_signal("auth_failed", "Could not start GitHub sign-in (error %s)." % code)

func cancel_auth():
	pending_device_code = ""
	auth_request_kind = ""
	if poll_timer:
		poll_timer.stop()

func get_profile():
	return request("GET", "/user")

func list_repositories():
	return request("GET", "/user/repos?sort=updated&per_page=100")

func get_repository(full_name):
	return request("GET", "/repos/" + str(full_name).http_escape())

func get_collaborators(full_name):
	return request("GET", "/repos/" + str(full_name).http_escape() + "/collaborators")

func get_activity(full_name):
	return request("GET", "/repos/" + str(full_name).http_escape() + "/events?per_page=30")

func request(method, path, body = null):
	if http == null:
		return ERR_UNCONFIGURED
	var headers = [
		"Accept: application/vnd.github+json",
		"X-GitHub-Api-Version: 2022-11-28",
		"User-Agent: Palo-Godot-Plugin"
	]
	if has_token():
		headers.append("Authorization: Bearer " + token)
	var payload = ""
	if body != null:
		headers.append("Content-Type: application/json")
		payload = JSON.print(body)
	return http.request(API_ROOT + path, headers, true, method, payload)

func _on_auth_request_completed(result, response_code, headers, body):
	var text = body.get_string_from_utf8()
	var parsed = JSON.parse(text)
	if result != OK:
		emit_signal("auth_failed", "GitHub connection failed (error %s)." % result)
		return
	if parsed.error != OK:
		emit_signal("auth_failed", "GitHub returned an invalid response.")
		return
	var data = parsed.result
	if auth_request_kind == "device":
		if response_code < 200 or response_code >= 300:
			emit_signal("auth_failed", "GitHub sign-in could not start (HTTP %s)." % response_code)
			return
		pending_device_code = str(data.get("device_code", ""))
		pending_interval = int(data.get("interval", 5))
		if pending_device_code == "":
			emit_signal("auth_failed", "GitHub did not return a device code.")
			return
		emit_signal("auth_started", str(data.get("user_code", "")), str(data.get("verification_uri", "https://github.com/login/device")), int(data.get("expires_in", 900)))
		poll_timer.wait_time = max(5, pending_interval)
		poll_timer.start()
		return

	# Token polling response.
	if data.has("access_token"):
		token = str(data.get("access_token", ""))
		pending_device_code = ""
		if poll_timer:
			poll_timer.stop()
		emit_signal("auth_succeeded", token)
		return

	var error_code = str(data.get("error", ""))
	if error_code == "authorization_pending":
		poll_timer.wait_time = max(5, pending_interval)
		poll_timer.start()
		emit_signal("auth_pending")
	elif error_code == "slow_down":
		pending_interval += 5
		poll_timer.wait_time = max(5, pending_interval)
		poll_timer.start()
		emit_signal("auth_pending")
	elif error_code == "expired_token":
		cancel_auth()
		emit_signal("auth_failed", "GitHub sign-in code expired. Start sign-in again.")
	elif error_code == "access_denied":
		cancel_auth()
		emit_signal("auth_failed", "GitHub sign-in was cancelled.")
	else:
		cancel_auth()
		emit_signal("auth_failed", "GitHub sign-in failed: " + error_code)

func _poll_token():
	if pending_device_code == "":
		return
	auth_request_kind = "token"
	var headers = ["Accept: application/json", "Content-Type: application/x-www-form-urlencoded", "User-Agent: Palo-Godot-Plugin"]
	var form = "client_id=" + client_id.http_escape()
	form += "&device_code=" + pending_device_code.http_escape()
	form += "&grant_type=" + DEVICE_GRANT.http_escape()
	var code = auth_http.request(TOKEN_URL, headers, true, HTTPClient.METHOD_POST, form)
	if code != OK:
		emit_signal("auth_failed", "Could not check GitHub sign-in (error %s)." % code)

func _on_request_completed(result, response_code, headers, body):
	var text = body.get_string_from_utf8()
	var parsed = null
	if text != "":
		var json = JSON.parse(text)
		if json.error == OK:
			parsed = json.result
	emit_signal("request_finished", result, response_code, parsed)
