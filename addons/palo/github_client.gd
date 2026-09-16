tool
extends Reference

# Palo GitHub API client for Godot 3.x.
# Authentication is intentionally supplied at runtime; no secrets are stored in source.

const API_ROOT = "https://api.github.com"

var token = ""
var http = null

signal request_finished(result, response_code, body)

func setup(owner):
	http = HTTPRequest.new()
	owner.add_child(http)
	http.connect("request_completed", self, "_on_request_completed")

func set_token(value):
	token = value.strip_edges()

func has_token():
	return token != ""

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

func _on_request_completed(result, response_code, headers, body):
	var text = body.get_string_from_utf8()
	var parsed = null
	if text != "":
		var json = JSON.parse(text)
		if json.error == OK:
			parsed = json.result
	emit_signal("request_finished", result, response_code, parsed)
