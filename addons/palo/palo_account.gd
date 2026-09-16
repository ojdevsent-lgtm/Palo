tool
extends Reference

# Normalized Palo account model.
# Firebase Authentication is the identity provider. This class does not
# perform network requests; it keeps the Godot integration independent from
# the eventual Firebase client implementation.

var user = {}

func set_firebase_user(firebase_user):
	user = {
		"firebase_uid": str(firebase_user.get("uid", firebase_user.get("firebase_uid", ""))),
		"email": str(firebase_user.get("email", "")),
		"display_name": str(firebase_user.get("displayName", firebase_user.get("display_name", ""))),
		"github_username": str(firebase_user.get("github_username", firebase_user.get("githubUsername", ""))),
		"country_code": str(firebase_user.get("country_code", "")),
		"region": str(firebase_user.get("region", ""))
	}
	return user.duplicate(true)

func set_user(data):
	user = data.duplicate(true)

func is_valid():
	return str(user.get("firebase_uid", "")) != ""

func get_uid():
	return str(user.get("firebase_uid", ""))

func get_email():
	return str(user.get("email", ""))

func get_display_name():
	return str(user.get("display_name", ""))

func get_github_username():
	return str(user.get("github_username", ""))

func get_country_code():
	return str(user.get("country_code", ""))

func get_region():
	return str(user.get("region", ""))

func get_data():
	return user.duplicate(true)

func clear():
	user.clear()
