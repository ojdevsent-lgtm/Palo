tool
extends Reference

# Firebase Authentication bridge for Palo.
# GitHub Device Flow remains the GitHub API login. The resulting GitHub OAuth
# access token is exchanged with Firebase so Palo gets its own account identity.

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
var _auth_http = null

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

func exchange_github_token(github_access_token):
    if not is_configured():
        emit_signal("auth_failed", "Firebase is not configured. Add your Firebase Web API key to the Palo configuration.")
        return false
    var token = str(github_access_token).strip_edges()
    if token == "":
        emit_signal("auth_failed", "GitHub access token is empty.")
        return false

    if _auth_http:
        _auth_http.queue_free()
        _auth_http = null

    _auth_http = HTTPRequest.new()
    var tree = Engine.get_main_loop()
    if not tree or not tree.root:
        emit_signal("auth_failed", "Firebase authentication requires a running Godot tree.")
        _auth_http = null
        return false
    tree.root.add_child(_auth_http)

    var api_key = str(firebase_config.get("apiKey", ""))
    var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=" + api_key.http_escape()
    var headers = ["Content-Type: application/json"]
    var post_body = "access_token=" + token.http_escape() + "&providerId=github.com"
    var body = {
        "postBody": post_body,
        "requestUri": "http://localhost",
        "returnSecureToken": true,
        "returnIdpCredential": false
    }

    var error = _auth_http.request(url, headers, true, HTTPClient.METHOD_POST, JSON.print(body))
    if error != OK:
        _auth_http.queue_free()
        _auth_http = null
        emit_signal("auth_failed", "Could not start Firebase authentication request.")
        return false

    _auth_http.connect("request_completed", self, "_on_auth_request_completed", [], CONNECT_ONESHOT)
    return true

func _on_auth_request_completed(result, response_code, body):
    var response_text = body.get_string_from_utf8()
    var parsed = {}
    if response_text != "":
        var json_result = JSON.parse(response_text)
        if json_result.error == OK and typeof(json_result.result) == TYPE_DICTIONARY:
            parsed = json_result.result

    if response_code < 200 or response_code >= 300:
        var message = str(parsed.get("error", {}).get("message", "Firebase authentication failed."))
        emit_signal("auth_failed", message)
    else:
        var user_data = {
            "firebase_uid": str(parsed.get("localId", "")),
            "uid": str(parsed.get("localId", "")),
            "email": str(parsed.get("email", "")),
            "display_name": str(parsed.get("displayName", "")),
            "github_username": str(parsed.get("screenName", "")),
            "photo_url": str(parsed.get("photoUrl", ""))
        }
        set_session(user_data, str(parsed.get("idToken", "")))
        emit_signal("auth_succeeded", user_data.duplicate(true), id_token)

    if _auth_http:
        _auth_http.queue_free()
        _auth_http = null

func set_session(user_data, firebase_id_token = ""):
    set_user(user_data)
    id_token = str(firebase_id_token)

func set_user(user_data):
    if typeof(user_data) == TYPE_DICTIONARY:
        current_user = user_data.duplicate(true)

func is_signed_in():
    return current_user.size() > 0 and str(current_user.get("firebase_uid", current_user.get("uid", ""))) != ""

func get_user():
    return current_user.duplicate(true)

func get_uid():
    return str(current_user.get("firebase_uid", current_user.get("uid", "")))

func get_email():
    return str(current_user.get("email", ""))

func get_username():
    return str(current_user.get("github_username", current_user.get("githubUsername", "Guest")))

func get_id_token():
    return id_token

func clear_session():
    current_user.clear()
    id_token = ""

func sign_out():
    clear_session()
