tool
extends Reference

# Firebase Authentication bridge for Godot 3.x.
# Palo uses Firebase Auth for account identity while GitHub remains the
# source-control provider. A GitHub OAuth access token is exchanged with
# Firebase Identity Toolkit; Palo stores only the Firebase ID token/session.

signal auth_succeeded(user_data, id_token)
signal auth_failed(message)

const DEFAULT_CONFIG = {
	"apiKey": "",
	"authDomain": "palo-vx.firebaseapp.com",
	"databaseURL": "https://palo-vx-default-rtdb.europe-west1.firebasedatabase.app",
	"projectId": "palo-vx",
	"storageBucket": "palo-vx.firebasestorage.app",
	"messagingSenderId": "315319157646",
	"appId": "1:315319157646:web:c716c2d4e305a5e49edadf",
	"measurementId": "G-GYKPWKWS55"
}

var firebase_config = {}
var current_user = {}
var id_token = ""
var pending_http = null

func _init():
	firebase_config = DEFAULT_CONFIG.duplicate(true)

func configure(config):
	firebase_config = DEFAULT_CONFIG.duplicate(true)
	if typeof(config) == TYPE_DICTIONARY:
		for key in config.keys():
			firebase_config[key] = config[key]

func get_config():
	return firebase_config.duplicate(true)

func is_configured():
	return str(firebase_config.get("apiKey", "")) != "" and str(firebase_config.get("projectId", "")) != ""

func get_database_url():
	return str(firebase_config.get("databaseURL", "")).rstrip("/")

func set_session(user_data, firebase_id_token = ""):
	set_user(user_data)
	id_token = str(firebase_id_token)

func set_user(user_data):
	if typeof(user_data) == TYPE_DICTIONARY:
		current_user = user_data.duplicate(true)

func is_signed_in():
	return current_user.size() > 0 and get_uid() != "" and id_token != ""

func get_user():
	return current_user.duplicate(true)

func get_uid():
	return str(current_user.get("firebase_uid", current_user.get("uid", "")))

func get_email():
	return str(current_user.get("email", ""))

func get_username():
	return str(current_user.get("github_username", current_user.get("githubUsername", current_user.get("screenName", "Guest"))))

func get_id_token():
	return id_token

func exchange_github_token(github_access_token):
	if not is_configured():
		emit_signal("auth_failed", "Firebase is not configured. Add apiKey to user://palo_firebase.json.")
		return false
	if str(github_access_token) == "":
		emit_signal("auth_failed", "GitHub access token is missing.")
		return false

	if pending_http:
		pending_http.queue_free()
	pending_http = null

	var tree = Engine.get_main_loop()
	if not tree or not tree.root:
		emit_signal("auth_failed", "Godot main loop is unavailable.")
		return false

	pending_http = HTTPRequest.new()
	tree.root.add_child(pending_http)
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=" + str(firebase_config["apiKey"])
	var post_body = "access_token=" + str(github_access_token).http_escape() + "&providerId=github.com"
	var body = {
		"postBody": post_body,
		"requestUri": "http://localhost",
		"returnIdpCredential": true,
		"returnSecureToken": true
	}
	var error = pending_http.request(url, ["Content-Type: application/json"], true, HTTPClient.METHOD_POST, JSON.print(body))
	if error != OK:
		pending_http.queue_free()
		pending_http = null
		emit_signal("auth_failed", "Could not start Firebase authentication request (%s)." % error)
		return false

	var result = yield(pending_http, "request_completed")
	var response_code = int(result[1])
	var response_body = result[3].get_string_from_utf8()
	pending_http.queue_free()
	pending_http = null

	var parsed = null
	if response_body != "":
		parsed = JSON.parse(response_body).result
	if response_code < 200 or response_code >= 300 or typeof(parsed) != TYPE_DICTIONARY:
		var message = "Firebase authentication failed (HTTP %d)." % response_code
		if typeof(parsed) == TYPE_DICTIONARY and parsed.has("error"):
			message = str(parsed["error"].get("message", message))
		emit_signal("auth_failed", message)
		return false

	id_token = str(parsed.get("idToken", ""))
	var uid = str(parsed.get("localId", ""))
	if uid == "" or id_token == "":
		emit_signal("auth_failed", "Firebase returned an incomplete authentication session.")
		return false

	current_user = {
		"firebase_uid": uid,
		"email": str(parsed.get("email", "")),
		"display_name": str(parsed.get("displayName", parsed.get("screenName", ""))),
		"github_username": str(parsed.get("screenName", "")),
		"photo_url": str(parsed.get("photoUrl", "")),
		"provider": "github.com"
	}
	emit_signal("auth_succeeded", current_user.duplicate(true), id_token)
	return true

func clear_session():
	current_user.clear()
	id_token = ""

func sign_out():
	clear_session()
