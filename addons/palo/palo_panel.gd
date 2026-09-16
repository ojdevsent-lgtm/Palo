tool
extends VBoxContainer

# Palo dashboard for the Godot 3.x integration.
# GitHub remains the source-control provider. Workspace/account services are
# optional here so the UI can be tested before the Firebase network layer is
# fully connected.

var git = null
var github = null
var settings = null
var cloud_service = null
var account = null
var workspace_manager = null

var status_label = null
var account_label = null
var plan_label = null
var workspace_list = null
var repo_list = null
var repo_input = null
var selected_repo = ""
var repos = []
var pending_api_action = ""

var workspace_name_input = null
var engine_option = null
var version_option = null
var workspace_repo_option = null
var create_workspace_button = null
var details_label = null
var team_list = null
var client_id_input = null
var connect_button = null

var workspaces = []
var active_workspace = {}

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
	_load_local_workspaces()
	var saved_token = settings.load_token()
	if saved_token != "":
		github.set_token(saved_token)
		_set_account("GitHub token loaded")
		_set_status("GitHub token loaded. Checking account...")
		pending_api_action = "profile"
		github.get_profile()

func setup_platform_services(cloud, palo_account, local_workspace_manager):
	cloud_service = cloud
	account = palo_account
	workspace_manager = local_workspace_manager

func _build_ui():
	set_name("Palo")
	var title = Label.new()
	title.text = "PALO"
	title.add_font_override("font_size", 22)
	add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Game development collaboration"
	add_child(subtitle)
	add_child(HSeparator.new())

	var account_title = Label.new()
	account_title.text = "Account"
	account_title.add_font_override("font_size", 14)
	add_child(account_title)

	account_label = Label.new()
	account_label.text = "Not connected"
	account_label.autowrap = true
	add_child(account_label)

	plan_label = Label.new()
	plan_label.text = "Plan: Free"
	add_child(plan_label)

	var auth_title = Label.new()
	auth_title.text = "Connect GitHub"
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

	add_child(HSeparator.new())

	var workspace_title = Label.new()
	workspace_title.text = "Your Workspaces"
	workspace_title.add_font_override("font_size", 16)
	add_child(workspace_title)

	workspace_list = ItemList.new()
	workspace_list.rect_min_size = Vector2(0, 100)
	workspace_list.connect("item_selected", self, "_on_workspace_selected")
	add_child(workspace_list)

	var create_title = Label.new()
	create_title.text = "Create Workspace"
	create_title.add_font_override("font_size", 14)
	add_child(create_title)

	workspace_name_input = LineEdit.new()
	workspace_name_input.placeholder_text = "Workspace name (e.g. My Game Team)"
	add_child(workspace_name_input)

	engine_option = OptionButton.new()
	engine_option.add_item("Godot")
	add_child(engine_option)

	version_option = OptionButton.new()
	version_option.add_item("3.x")
	add_child(version_option)

	workspace_repo_option = OptionButton.new()
	workspace_repo_option.add_item("Select GitHub repository")
	add_child(workspace_repo_option)

	create_workspace_button = Button.new()
	create_workspace_button.text = "Create Workspace"
	create_workspace_button.connect("pressed", self, "_on_create_workspace")
	add_child(create_workspace_button)

	details_label = Label.new()
	details_label.text = "No workspace selected."
	details_label.autowrap = true
	add_child(details_label)

	add_child(HSeparator.new())

	var project_title = Label.new()
	project_title.text = "Project Repository"
	project_title.add_font_override("font_size", 14)
	add_child(project_title)

	repo_input = LineEdit.new()
	repo_input.placeholder_text = "Filter repositories..."
	repo_input.connect("text_changed", self, "_filter_repositories")
	add_child(repo_input)

	repo_list = ItemList.new()
	repo_list.rect_min_size = Vector2(0, 120)
	repo_list.connect("item_selected", self, "_on_repo_selected")
	add_child(repo_list)

	var team_title = Label.new()
	team_title.text = "Team Activity"
	team_title.add_font_override("font_size", 14)
	add_child(team_title)
	team_list = ItemList.new()
	team_list.rect_min_size = Vector2(0, 100)
	add_child(team_list)

	var upload_btn = Button.new()
	upload_btn.text = "Upload My Work"
	upload_btn.connect("pressed", self, "_on_upload")
	add_child(upload_btn)

	var update_btn = Button.new()
	update_btn.text = "Get Team Updates"
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
		var login = str(body.get("login", ""))
		_set_account("GitHub connected ✓\n@" + login)
		pending_api_action = "repos"
		_set_status("Signed in as @" + login + ". Loading repositories...")
		github.list_repositories()
	elif pending_api_action == "repos":
		repos = body if typeof(body) == TYPE_ARRAY else []
		_refresh_repo_options()
		_filter_repositories(repo_input.text)
		_set_status("GitHub connected. Choose a repository and create a workspace.")
	elif pending_api_action == "collaborators":
		_show_team(body)
	elif pending_api_action == "activity":
		_show_activity(body)

func _refresh_repo_options():
	if workspace_repo_option == null:
		return
	workspace_repo_option.clear()
	workspace_repo_option.add_item("Select GitHub repository")
	for repo in repos:
		workspace_repo_option.add_item(str(repo.get("full_name", repo.get("name", ""))))

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
	repo_label_unused()
	team_list.clear()
	team_list.add_item("Loading team activity...")
	pending_api_action = "collaborators"
	github.get_collaborators(name)

func repo_label_unused():
	# Kept as a small compatibility hook for older dashboard builds.
	return

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

func _on_create_workspace():
	var name = workspace_name_input.text.strip_edges()
	if name == "":
		_set_status("Enter a workspace name.")
		return
	var repository = ""
	if workspace_repo_option.selected > 0:
		repository = workspace_repo_option.get_item_text(workspace_repo_option.selected)
	if repository == "":
		_set_status("Select a GitHub repository for the workspace.")
		return

	var workspace = {
		"id": "local-%d" % OS.get_unix_time(),
		"name": name,
		"owner_user_id": _get_owner_id(),
		"plan_id": "free",
		"engine": engine_option.get_item_text(engine_option.selected).to_lower(),
		"engine_version": version_option.get_item_text(version_option.selected),
		"repository": {"provider": "github", "full_name": repository},
		"members": [{"user_id": _get_owner_id(), "role": "owner"}]
	}
	workspaces.append(workspace)
	_save_local_workspaces()
	_refresh_workspace_list()
	active_workspace = workspace
	_update_workspace_details()
	_set_status("Workspace created locally. Backend persistence and membership enforcement will be connected next.")

func _get_owner_id():
	if account and account.has_method("get_uid"):
		var uid = account.get_uid()
		if uid != "":
			return uid
	return "local-user"

func _refresh_workspace_list():
	if workspace_list == null:
		return
	workspace_list.clear()
	for workspace in workspaces:
		var label = "%s  •  %s" % [str(workspace.get("name", "Workspace")), str(workspace.get("engine_version", "3.x"))]
		workspace_list.add_item(label)

func _on_workspace_selected(index):
	if index < 0 or index >= workspaces.size():
		return
	active_workspace = workspaces[index].duplicate(true)
	_update_workspace_details()

func _update_workspace_details():
	if details_label == null:
		return
	if active_workspace.empty():
		details_label.text = "No workspace selected."
		return
	var repository = active_workspace.get("repository", {})
	var repo_name = str(repository.get("full_name", "Not connected"))
	var members = active_workspace.get("members", [])
	details_label.text = "Workspace: %s\nEngine: %s %s\nPlan: %s\nGitHub: %s\nMembers: %d / 1 on Free" % [
		str(active_workspace.get("name", "")),
		str(active_workspace.get("engine", "godot")),
		str(active_workspace.get("engine_version", "3.x")),
		str(active_workspace.get("plan_id", "free")),
		repo_name,
		members.size()
	]
	plan_label.text = "Plan: " + str(active_workspace.get("plan_id", "free")).capitalize()

func _load_local_workspaces():
	var file = File.new()
	if file.file_exists("user://palo_workspaces.json"):
		if file.open("user://palo_workspaces.json", File.READ) == OK:
			var parsed = JSON.parse(file.get_as_text())
			file.close()
			if parsed.error == OK and typeof(parsed.result) == TYPE_ARRAY:
				workspaces = parsed.result
	_refresh_workspace_list()

func _save_local_workspaces():
	var file = File.new()
	if file.open("user://palo_workspaces.json", File.WRITE) == OK:
		file.store_string(JSON.print(workspaces))
		file.close()

func _on_upload():
	_set_status("Uploading your work...\n" + str(git.upload_my_work()))

func _on_updates():
	_set_status("Getting team updates...\n" + str(git.get_team_updates()))

func _on_backup():
	_set_status("Creating backup...\n" + str(git.create_backup()))

func _on_status():
	_set_status(git.refresh_git_status())

func _set_account(text):
	if account_label:
		account_label.text = str(text)

func _set_status(text):
	if status_label:
		status_label.text = str(text)
