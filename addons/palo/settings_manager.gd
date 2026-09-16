tool
extends Reference

const SETTINGS_PATH = "user://palo_settings.json"

func save_token(token):
	var file = File.new()
	if file.open(SETTINGS_PATH, File.WRITE) != OK:
		return false
	file.store_string(JSON.print({"github_token": token}))
	file.close()
	return true

func load_token():
	var file = File.new()
	if not file.file_exists(SETTINGS_PATH):
		return ""
	if file.open(SETTINGS_PATH, File.READ) != OK:
		return ""
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY:
		return ""
	return str(parsed.result.get("github_token", ""))

func clear():
	var dir = Directory.new()
	if dir.file_exists(SETTINGS_PATH):
		dir.remove(SETTINGS_PATH)
