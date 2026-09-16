tool
extends Reference

# Engine/version resolver shared by Palo launcher and future integrations.
# Godot 3.x compatible and intentionally independent of game-project code.

var manifest = {}

func load_manifest(path = "res://core/integration_manifest.json"):
	var file = File.new()
	if not file.file_exists(path):
		return false
	if file.open(path, File.READ) != OK:
		return false
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY:
		return false
	manifest = parsed.result
	return true

func get_integrations():
	return manifest.get("integrations", []).duplicate(true)

func find(engine_id, version):
	for integration in get_integrations():
		if str(integration.get("engine", "")) != str(engine_id):
			continue
		var versions = integration.get("supported_versions", [])
		if versions.empty() or str(version) in versions:
			return integration.duplicate(true)
	return {}

func is_available(engine_id, version):
	var integration = find(engine_id, version)
	return not integration.empty() and str(integration.get("status", "planned")) == "available"

func get_install_path(engine_id, version):
	var integration = find(engine_id, version)
	return str(integration.get("path", ""))
