tool
extends Reference

# Palo Firebase authentication foundation.
# Stores Firebase configuration and user session state.

var firebase_config = {}
var current_user = {}

func configure(config):
	firebase_config = config

func is_signed_in():
	return current_user.size() > 0

func set_user(user_data):
	current_user = user_data

func get_username():
	return str(current_user.get("github_username", "Guest"))

func sign_out():
	current_user.clear()
