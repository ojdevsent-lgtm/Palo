tool
extends VBoxContainer

var git = null
var status_label = null
var repo_label = null

func setup(git_manager):
	git = git_manager
	_build_ui()

func _build_ui():
	set_name("Palo")
	var title = Label.new()
	title.text = "Palo — Team Collaboration"
	title.add_font_override("font_size", 18)
	add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Simple controls for your GitHub game project"
	add_child(subtitle)

	add_child(HSeparator.new())

	repo_label = Label.new()
	repo_label.text = "Project: " + ProjectSettings.globalize_path("res://")
	repo_label.autowrap = true
	add_child(repo_label)

	var git_state = Label.new()
	git_state.text = "Git: " + ("Ready" if git and git.git_available else "Not detected")
	add_child(git_state)

	var upload_btn = Button.new()
	upload_btn.text = "Upload My Work"
	upload_btn.hint_tooltip = "Commit local changes and push them to the connected repository."
	upload_btn.connect("pressed", self, "_on_upload")
	add_child(upload_btn)

	var update_btn = Button.new()
	update_btn.text = "Get Team Updates"
	update_btn.hint_tooltip = "Download the latest team changes."
	update_btn.connect("pressed", self, "_on_updates")
	add_child(update_btn)

	var backup_btn = Button.new()
	backup_btn.text = "Create Backup"
	backup_btn.connect("pressed", self, "_on_backup")
	add_child(backup_btn)

	var status_btn = Button.new()
	status_btn.text = "Check Project Status"
	status_btn.connect("pressed", self, "_on_status")
	add_child(status_btn)

	add_child(HSeparator.new())
	status_label = Label.new()
	status_label.text = "Palo is ready."
	status_label.autowrap = true
	add_child(status_label)

func _on_upload():
	_set_status("Uploading your work...")
	_set_status(git.upload_my_work())

func _on_updates():
	_set_status("Getting team updates...")
	_set_status(git.get_team_updates())

func _on_backup():
	_set_status("Creating backup...")
	_set_status(git.create_backup())

func _on_status():
	_set_status(git.refresh_git_status())

func _set_status(text):
	if status_label:
		status_label.text = str(text)
