tool
extends EditorPlugin

var panel

func _enter_tree():
	panel = VBoxContainer.new()

	var title = Label.new()
	title.text = "Palo"
	panel.add_child(title)

	var upload_btn = Button.new()
	upload_btn.text = "Upload My Work"
	panel.add_child(upload_btn)

	var update_btn = Button.new()
	update_btn.text = "Get Team Updates"
	panel.add_child(update_btn)

	var backup_btn = Button.new()
	backup_btn.text = "Create Backup"
	panel.add_child(backup_btn)

	add_control_to_dock(DOCK_SLOT_RIGHT_UL, panel)

func _exit_tree():
	remove_control_from_docks(panel)
	panel.free()
