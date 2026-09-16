tool
extends Reference

# Palo workspace and subscription rules.
# This module is intentionally local and deterministic for the Godot 3.x
# integration. Final membership enforcement must also be performed by the
# Palo backend so users cannot bypass limits by changing devices/accounts.

const FREE_PLAN = "free"
const TEAM_PLAN = "team"
const TEAM_PLUS_PLAN = "team_plus"
const LARGE_TEAM_PLAN = "large_team"

var workspace = {}

func create_local_workspace(workspace_name, owner_user_id, engine_id, engine_version):
	workspace = {
		"id": "local-workspace",
		"name": str(workspace_name),
		"owner_user_id": str(owner_user_id),
		"plan_id": FREE_PLAN,
		"engine": str(engine_id),
		"engine_version": str(engine_version),
		"repository": {},
		"members": [
			{"user_id": str(owner_user_id), "role": "owner"}
		]
	}
	return workspace

func set_workspace(data):
	workspace = data.duplicate(true)

func get_workspace():
	return workspace.duplicate(true)

func set_plan(plan_id):
	workspace["plan_id"] = str(plan_id)

func get_plan_id():
	return str(workspace.get("plan_id", FREE_PLAN))

func get_member_limit():
	match get_plan_id():
		TEAM_PLAN:
			return 5
		TEAM_PLUS_PLAN:
			return 20
		LARGE_TEAM_PLAN:
			return -1
		_:
			return 1

func get_member_count():
	return int(workspace.get("members", []).size())

func can_add_member():
	var limit = get_member_limit()
	return limit < 0 or get_member_count() < limit

func get_access_message():
	if can_add_member():
		return "Access allowed."
	return "Team access required. This project is currently using the Palo Free plan, which supports one person. Contact the workspace administrator to upgrade the plan before adding another person."

func add_member(user_id, role="member"):
	var uid = str(user_id)
	if uid == "":
		return {"allowed": false, "reason": "A valid Palo user ID is required."}

	for member in workspace.get("members", []):
		if str(member.get("user_id", "")) == uid:
			return {"allowed": true, "reason": "User is already a workspace member."}

	if not can_add_member():
		return {"allowed": false, "reason": get_access_message()}

	workspace["members"].append({"user_id": uid, "role": str(role)})
	return {"allowed": true, "reason": "Member added locally. Backend confirmation is required for persistent membership."}

func remove_member(user_id):
	var uid = str(user_id)
	var members = workspace.get("members", [])
	for i in range(members.size() - 1, -1, -1):
		if str(members[i].get("user_id", "")) == uid:
			if str(members[i].get("role", "")) == "owner":
				return {"allowed": false, "reason": "The workspace owner cannot be removed."}
			members.remove(i)
			return {"allowed": true, "reason": "Member removed locally."}
	return {"allowed": false, "reason": "User is not a workspace member."}

func associate_repository(provider, full_name):
	workspace["repository"] = {
		"provider": str(provider),
		"full_name": str(full_name)
	}

func get_repository():
	return workspace.get("repository", {}).duplicate(true)
