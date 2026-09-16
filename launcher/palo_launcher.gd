tool
extends Control

# Palo launcher foundation for Godot 3.x.
# This UI resolves engine/version selections to an integration manifest.
# Authentication, billing and workspace authorization remain backend services.

var integration_manager = null
var engine_option = null
var version_option = null
var status_label = null
var continue_button = null

func _ready():
	integration_manager = preload("res://core/integration_manager.gd").new()
	integration_manager.load_manifest()
	_build_ui()
	_refresh_versions()

func _build_ui():
	var root = VBoxContainer.new()
	root.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	root.margin_left = 32
	root.margin_top = 32
	root.margin_right = -32
	root.margin_bottom = -32
	add_child(root)

	var title = Label.new()
	title.text = "PALO"
	title.add_font_override("font_size", 30)
	root.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Game development collaboration"
	root.add_child(subtitle)
	root.add_child(HSeparator.new())

	var account = Button.new()
	account.text = "Sign in / Create Palo account"
	root.add_child(account)

	var engine_label = Label.new()
	engine_label.text = "Game engine"
	root.add_child(engine_label)
	engine_option = OptionButton.new()
	root.add_child(engine_option)

	var version_label = Label.new()
	version_label.text = "Engine version"
	root.add_child(version_label)
	version_option = OptionButton.new()
	root.add_child(version_option)

	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.connect("pressed", self, "_on_continue")
	root.add_child(continue_button)

	status_label = Label.new()
	status_label.autowrap = true
	status_label.text = "Select an engine and version."
	root.add_child(status_label)

	engine_option.connect("item_selected", self, "_on_engine_selected")
	var engines = []
	for integration in integration_manager.get_integrations():
		var engine = str(integration.get("engine", ""))
		if engine != "" and not engine in engines:
			engines.append(engine)
	for engine in engines:
		engine_option.add_item(engine.capitalize())

func _on_engine_selected(_index):
	_refresh_versions()

func _refresh_versions():
	if not engine_option or not version_option:
		return
	version_option.clear()
	if engine_option.selected < 0:
		return
	var selected_engine = engine_option.get_item_text(engine_option.selected).to_lower()
	var seen = []
	for integration in integration_manager.get_integrations():
		if str(integration.get("engine", "")) != selected_engine:
			continue
		for version in integration.get("supported_versions", []):
			if not version in seen:
				seen.append(version)
	for version in seen:
		version_option.add_item(str(version))
	if version_option.get_item_count() == 0:
		version_option.add_item("No released versions yet")

func _on_continue():
	if engine_option.selected < 0 or version_option.selected < 0:
		status_label.text = "Choose an engine and version first."
		return
	var engine = engine_option.get_item_text(engine_option.selected).to_lower()
	var version = version_option.get_item_text(version_option.selected)
	var integration = integration_manager.find(engine, version)
	if integration.empty():
		status_label.text = "No Palo integration matches that engine/version."
		return
	if str(integration.get("status", "planned")) != "available":
		status_label.text = "That Palo integration is planned and is not available yet."
		return
	status_label.text = "Integration ready: %s\nNext: connect GitHub and choose a workspace." % str(integration.get("name", "Palo integration"))
