tool
extends Reference

# Coordinates Firebase user profile persistence with the normalized Palo account.
# Authentication itself must provide a valid Firebase ID token to
# firebase_auth_manager before these database calls are made.

signal profile_loaded(success, data)
signal profile_saved(success, data)

var auth = null
var database = null
var account = null

func setup(firebase_auth_manager, firebase_database, palo_account):
	auth = firebase_auth_manager
	database = firebase_database
	account = palo_account

func save_current_profile(extra_data = {}):
	if not auth or not database or not account or not auth.is_signed_in():
		emit_signal("profile_saved", false, {"error": "Not signed in"})
		return false

	var data = account.get_data()
	for key in extra_data.keys():
		data[key] = extra_data[key]
	data["last_seen_at"] = OS.get_unix_time()
	var success = yield(database.save_user(data), "completed") if false else database.save_user(data)
	emit_signal("profile_saved", success, data)
	return success

func load_current_profile():
	if not auth or not database or not account or not auth.is_signed_in():
		emit_signal("profile_loaded", false, {"error": "Not signed in"})
		return false
	return database.load_user(auth.get_uid())
