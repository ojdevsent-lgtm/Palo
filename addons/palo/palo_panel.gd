tool
extends VBoxContainer

var git = null
var github = null
var settings = null
var status_label = null
var repo_label = null
var repo_input = null
var repo_list = null
var team_list = null
var client_id_input = null
var connect_button = null
var selected_repo = ""
var repos = []
var pending_api_action = ""

func setup(git_manager, github_client, settings_manager):
	git = git_manager
	github = github_client
	settings = settings_manager
	_build_ui()
	github.connect("auth_started", self, "_on_auth_started")
	github.connect("auth_pending", self, "_on_auth_pending")
	github.connect("auth_succeeded", self, "_on_auth_succeeded")
	github.connect("auth_failed", self, "_on_auth_failed")
	github.connect("request_finished", self, "_on_github_request")
	var saved_token = settings.load_token()
	if saved_token != "":
		github.set_token(saved_token)
		_set_status("GitHub token loaded. Checking account...")
		pending_api_action = "profile"
		github.get_profile()

func _build_ui():
	set_name("Palo")
	var title = Label.new()
	title.text = "Palo — Team Collaboration"
	title.add_font_override("font_size", 18)
	add_child(title)

	var subtitle = Label.new()
	subtitle.text = "GitHub + simple game-project collaboration"
	add_child(subtitle)
	add_child(HSeparator.new())

	var auth_title = Label.new()
	auth_title.text = "1. Connect GitHub"
	auth_title.add_font_override("font_size", 14)
	add_child(auth_title)

	client_id_input = LineEdit.new()
	client_id_input.placeholder_text = "GitHub App Client ID"
	client_id_input.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(client_id_input)

	connect_button = Button.new()
	connect_button.text = "Connect GitHub"
	connect_button.connect("pressed", self, "_on_connect")
	add_child(connect_button)

	var repo_title = Label.new()
	repo_title.text = "2. Choose Project"
	repo_title.add_font_override("font_size", 14)
	add_child(repo_title)

	repo_input = LineEdit.new()
	repo_input.placeholder_text = "Filter repositories..."
	repo_input.connect("text_changed", self, "_filter_repositories")
	add_child(repo_input)

	repo_list = ItemList.new()
	repo_list.rect_min_size = Vector2(0, 120)
	repo_list.connect("item_selected", self, "_on_repo_selected")
	add_child(repo_list)

	repo_label = Label.new()
	repo_label.text = "Project: not selected"
	repo_label.autowrap = true
	add_child(repo_label)

	var team_title = Label.new()
	team_title.text = "3. Team Activity"
	team_title.add_font_override("font_size", 14)
	add_child(team_title)
	team_list = ItemList.new()
	team_list.rect_min_size = Vector2(0, 110)
	add_child(team_list)

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

func _on_connect():
	var id = client_id_input.text.strip_edges()
	if id == "":
		_set_status("Enter your GitHub App Client ID first.")
		return
	github.set_client_id(id)
	connect_button.disabled = true
	_set_status("Starting GitHub sign-in...")
	github.start_device_flow()

func _on_auth_started(user_code, verification_uri, expires_in):
	connect_button.disabled = false
	_set_status("GitHub code: " + user_code + "\nOpen " + verification_uri + " in your browser, enter the code, then return here.\nCode expires in about %d seconds." % expires_in)
	OS.shell_open(verification_uri)

func _on_auth_pending():
	_set_status("Waiting for GitHub approval...")

func _on_auth_succeeded(access_token):
	connect_button.disabled = false
	if settings.save_token(access_token):
		_set_status("GitHub connected. Loading your repositories...")
	else:
		_set_status("GitHub connected, but the local token could not be saved.")
	pending_api_action = "profile"
	github.get_profile()

func _on_auth_failed(message):
	connect_button.disabled = false
	_set_status(str(message))

func _on_github_request(result, response_code, body):
	if result != OK:
		_set_status("GitHub connection error: %s" % result)
		return
	if response_code < 200 or response_code >= 300:
		_set_status("GitHub API error: HTTP %s" % response_code)
		return
	if pending_api_action == "profile":
		pending_api_action = "repos"
		_set_status("Signed in as @" + str(body.get("login", "")) + ". Loading repositories...")
		github.list_repositories()
	elif pending_api_action == "repos":
		repos = body if typeof(body) == TYPE_ARRAY else []
		_filter_repositories(repo_input.text)
		_set_status("Choose the game repository you want to work with.")
	elif pending_api_action == "collaborators":
		_show_team(body)
	elif pending_api_action == "activity":
		_show_activity(body)

func _filter_repositories(text):
	if repo_list == null:
		return
	repo_list.clear()
	var needle = str(text).to_lower()
	for repo in repos:
		var name = str(repo.get("full_name", repo.get("name", "")))
		if needle == "" or name.to_lower().find(needle) >= 0:
			repo_list.add_item(name)

func _on_repo_selected(index):
	var name = repo_list.get_item_text(index)
	selected_repo = name
	repo_label.text = "Project: " + name
	team_list.clear()
	team_list.add_item("Loading team activity...")
	pending_api_action = "collaborators"
	github.get_collaborators(name)

func _show_team(body):
	team_list.clear()
	if typeof(body) != TYPE_ARRAY:
		team_list.add_item("Team information unavailable.")
		return
	if body.empty():
		team_list.add_item("No visible collaborators found.")
	else:
		for member in body:
			var login = str(member.get("login", "Unknown"))
			var permissions = member.get("permissions", {})
			var role = "Can upload" if bool(permissions.get("push", false)) else "Member"
			team_list.add_item("@" + login + "  •  " + role)
	pending_api_action = "activity"
	github.get_activity(selected_repo)

func _show_activity(body):
	team_list.add_item("--- Recent activity ---")
	if typeof(body) != TYPE_ARRAY:
		team_list.add_item("Activity unavailable.")
		return
	var shown = 0
	for event in body:
		if shown >= 8:
			break
		var actor = str(event.get("actor", {}).get("login", "Someone"))
		var event_type = str(event.get("type", "Activity"))
		team_list.add_item("@%s  •  %s" % [actor, _friendly_event(event_type)])
		shown += 1
	if shown == 0:
		team_list.add_item("No recent public activity.")

func _friendly_event(event_type):
	if event_type == "PushEvent":
		return "pushed changes"
	if event_type == "PullRequestEvent":
		return "updated a pull request"
	if event_type == "CreateEvent":
		return "created a branch/tag"
	if event_type == "DeleteEvent":
		return "deleted a branch/tag"
	return event_type.replace("Event", "")

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
