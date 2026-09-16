tool
extends Reference

var project_path = ""
var last_output = ""
var git_available = false

func _init():
	project_path = ProjectSettings.globalize_path("res://")
	git_available = _detect_git()

func _detect_git():
	var output = []
	var code = OS.execute("git", ["--version"], true, output)
	last_output = _join_output(output)
	return code == 0

func refresh_git_status():
	if not git_available:
		return "Git not found"
	return _run(["status", "--short", "--branch"])

func upload_my_work(message = "Palo: update project"):
	if not git_available:
		return "Git is not installed or not available on PATH."
	var add_result = _run(["add", "-A"])
	if add_result.begins_with("ERROR:"):
		return add_result
	var commit_result = _run(["commit", "-m", message])
	if commit_result.find("nothing to commit") >= 0:
		return "Nothing new to upload."
	if commit_result.begins_with("ERROR:"):
		return commit_result
	var push_result = _run(["push"])
	if push_result.begins_with("ERROR:"):
		return "Saved locally, but upload failed:\n" + push_result
	return "Work uploaded successfully."

func get_team_updates():
	if not git_available:
		return "Git is not installed or not available on PATH."
	var result = _run(["pull", "--rebase"])
	if result.begins_with("ERROR:"):
		return result
	return "Team updates received.\n" + result

func create_backup():
	var packer = ZIPPacker.new()
	var backup_dir = project_path.plus_file(".palo_backups")
	var dir = Directory.new()
	if not dir.dir_exists(backup_dir):
		dir.make_dir_recursive(backup_dir)
	var stamp = OS.get_datetime()
	var filename = "backup_%04d%02d%02d_%02d%02d%02d.zip" % [stamp.year, stamp.month, stamp.day, stamp.hour, stamp.minute, stamp.second]
	var destination = backup_dir.plus_file(filename)
	var error = packer.open(destination)
	if error != OK:
		return "ERROR: Could not create backup file."
	var root = Directory.new()
	_backup_directory(root, project_path, packer, "")
	packer.close()
	return "Backup created:\n" + destination

func _backup_directory(dir, absolute_path, packer, relative_path):
	var error = dir.open(absolute_path)
	if error != OK:
		return
	dir.list_dir_begin(true, true)
	var item = dir.get_next()
	while item != "":
		if item != "." and item != ".." and item != ".palo_backups" and item != ".git":
			var absolute_item = absolute_path.plus_file(item)
			var relative_item = relative_path.plus_file(item)
			if dir.current_is_dir():
				_backup_directory(dir, absolute_item, packer, relative_item)
			else:
				var file = File.new()
				if file.open(absolute_item, File.READ) == OK:
					packer.start_file(relative_item)
					packer.write_file(file.get_buffer(file.get_len()))
					packer.close_file()
					file.close()
			item = dir.get_next()
	dir.list_dir_end()

func _run(args):
	var output = []
	# Git's -C flag makes the operation target the Godot project rather than
	# the directory where the editor executable happens to live.
	var git_args = ["-C", project_path]
	for arg in args:
		git_args.append(arg)
	var code = OS.execute("git", git_args, true, output)
	var text = _join_output(output)
	last_output = text
	if code != 0:
		return "ERROR: " + text
	return text

func _join_output(output):
	var text = ""
	for line in output:
		text += str(line) + "\n"
	return text.strip_edges()
