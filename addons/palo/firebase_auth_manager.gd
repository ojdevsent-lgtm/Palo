tool
extends Reference

# Palo Firebase configuration and session foundation.
# Firebase Authentication remains the identity provider. Network sign-in is
# intentionally kept separate from this model until the Firebase auth flow
# is connected to the Godot 3 UI.

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
