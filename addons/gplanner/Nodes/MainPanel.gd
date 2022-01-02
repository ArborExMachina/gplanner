extends Control
tool

# Menu actions
enum ProjectActions {New, Open, Save, Details, Close}

# Types (don't pollute user namespace with class_name)
const GroupBox := preload("res://addons/gplanner/GroupVBox.gd")
const Project := preload("res://addons/gplanner/DataHelpers/Project.gd")
const TicketEditor := preload("res://addons/gplanner/Editors/TicketEditor.gd")
const Milestone = preload("res://addons/gplanner/DataHelpers/Milestone.gd")
const Task = preload("res://addons/gplanner/DataHelpers/Task.gd")

# Scenes
const group_scene := preload("res://addons/gplanner/GroupVBox.tscn")
const ticket_editor := preload("res://addons/gplanner/Editors/TicketEditor.tscn")


# instance variables
	# onready
onready var inspector_container = $VSplitContainer/Body/Inspector
onready var groups_container:VBoxContainer = $VSplitContainer/Body/TabContainer/Milestones
onready var open_project_popup:PopupMenu = $PopupContainer/OpenProjectOptions
onready var new_project_popup:AcceptDialog = $PopupContainer/NewProjectName
onready var new_project_lineedit:LineEdit = $PopupContainer/NewProjectName/LineEdit
onready var project_name_label:Label = $VSplitContainer/MenuStrip/ProjectNameLabel
onready var new_milestone_popup:AcceptDialog = $PopupContainer/NewMilestoneName
onready var new_milestone_name_edit:LineEdit = $PopupContainer/NewMilestoneName/LineEdit
onready var save_changes_dialog = $PopupContainer/SaveUnsavedDialog
onready var task_list_container:VBoxContainer = $VSplitContainer/Body/TabContainer/Tasks

	# vanilla
var project:Project
var ticket_editor_instance:TicketEditor
var active_editor:Control
var _post_save_action_stack := []
var _action_stack_locked := false
var _group_boxes := {}

func _ready() -> void:
	Project.set_working_dir()
	ticket_editor_instance = ticket_editor.instance()
	ticket_editor_instance.connect("milestone_grouping_change", self, "_on_task_grouping_changed")
	ticket_editor_instance.connect("title_changed", self, "_on_editied_task_title_change")
	ticket_editor_instance.connect("task_changes_commited", self, "_on_editied_task_saved")
	
	# signal generators
	var project_menu_popup = $VSplitContainer/MenuStrip/ProjectMenu.get_popup()
	var unsaved_close: TextureButton = save_changes_dialog.get_close_button()
	var unsaved_cancel: Button = save_changes_dialog.get_cancel()
	# connect signals
	project_menu_popup.connect("id_pressed", self, "_on_project_action_pressed")
	save_changes_dialog.connect("modal_closed", self, "_on_SaveUnsavedDialog_cancelled")
	unsaved_close.connect("pressed", self, "_on_SaveUnsavedDialog_cancelled")
	unsaved_cancel.connect("pressed", self, "_on_SaveUnsavedDialog_cancelled")

func _exit_tree() -> void:
	if ticket_editor_instance != null:
		ticket_editor_instance.queue_free()

func _do_action_stack()->void:
	if _action_stack_locked: 
		return
	
	_action_stack_locked = true
	while len(_post_save_action_stack) > 0:
		var action = _post_save_action_stack.pop_back()
		callv(action[0], action[1])
	
	_action_stack_locked = false

func _close_project()->void:
	if !project: 
		return
	if !project.is_saved_since_changes():
		project.save_all()
	project = null
#	if project.is_saved_since_changes():
#		project = null
#	else:
#		_post_save_action_stack.append(["_close_project", []])
#		save_changes_dialog.show()
#		return
	
	_set_inspector(null)
	project_name_label.text = ""
	for i in range(groups_container.get_child_count() - 1, 0, -1):
		var child = groups_container.get_child(i)
		groups_container.remove_child(child)
		child.free()
	
	_refresh_task_list(true)
	
#	_do_action_stack()

func _load_project(name:String)->void:
	if project:
		_post_save_action_stack.append(["_load_project", [name]])
		_close_project()
		return
	project = Project.new()
	project.open(name)
	project_name_label.text = name
	for m in project.get_milestones():
		m = m as Milestone
		_add_milestone(m)
	
	_refresh_task_list()

func _refresh_task_list(only_clear:bool = false)->void:
	var task_buttons = task_list_container.get_children()
	for tb in task_buttons:
		task_list_container.remove_child(tb)
		tb.queue_free()
	
	if only_clear: return
	
	for task_data in project.get_all_task_data():
		var task_button = Button.new()
		task_list_container.add_child(task_button)
		task_button.text = task_data.title
		task_button.clip_text = true
		task_button.connect("pressed", self, "_handle_task_click", [task_data.id])

func _add_milestone(milestone:Milestone)->void:
	var group_box:GroupBox = group_scene.instance()
	groups_container.add_child(group_box)
	group_box.load_milestone(project, milestone._id)
	group_box.shrink()
	group_box.connect("item_clicked", self, "_handle_task_click")
	_group_boxes[milestone._id] = group_box
	ticket_editor_instance.update_milestone_options(milestone)

func _set_inspector(type)->void:
	if type == null and active_editor != null:
		inspector_container.remove_child(active_editor)
		active_editor = null
		return
	if type == TicketEditor:
		if active_editor != null:
			inspector_container.remove_child(active_editor)
		inspector_container.add_child(ticket_editor_instance)
		active_editor = ticket_editor_instance
		return

func _display_open_menu()->void:
	var project_names = Project.list_projects()
	open_project_popup.clear()
	for name in project_names:
		open_project_popup.add_item(name)
	open_project_popup.show()

# click handlers
func _handle_task_click(task_id:int)->void:
	if !project.is_saved_since_changes():
		project.save_all()
#		_post_save_action_stack.append(["_handle_task_click",[task_id]])
#		save_changes_dialog.show()
#		return
	if active_editor != ticket_editor_instance:
		_set_inspector(TicketEditor)
	ticket_editor_instance.load_ticket(project, task_id)

func _on_NewTicket_pressed() -> void:
	if !project: 
		return
	if !project.is_saved_since_changes():
		project.save_all()
#		_post_save_action_stack.append(["_on_NewTicket_pressed",[]])
#		save_changes_dialog.show()
#		return
	if active_editor != ticket_editor_instance:
		_set_inspector(TicketEditor)
	ticket_editor_instance.load_ticket(project, -1)

func _on_project_action_pressed(actionID:int) -> void:
	match actionID:
		ProjectActions.New:
			new_project_popup.show()
			new_project_lineedit.text = ""
			new_project_lineedit.grab_focus()
		ProjectActions.Open:
			_display_open_menu()
		ProjectActions.Save:
			if project:
				project.save_all()
		ProjectActions.Close:
			_close_project()

func _on_NewProjectName_confirmed() -> void:
	if project:
#		_post_save_action_stack.append(["_on_NewProjectName_confirmed", []])
		_close_project()
#		return
	var name = new_project_lineedit.text
	project = Project.new()
	if project.open(name):
		project_name_label.text = name
	else:
		print("Failed to open the project '%s'" % name)

func _on_OpenProjectOptions_index_pressed(index: int) -> void:
	var name = open_project_popup.get_item_text(index)
	_load_project(name)

func _on_NewMilestoneName_confirmed() -> void:
	var name:String = new_milestone_name_edit.text
	var ms = project.new_milestone(name)
	_add_milestone(ms)
	project.save_all()

func _on_NewMilestoneButton_pressed() -> void:
	if !project: 
		return
	new_milestone_popup.show()
	new_milestone_name_edit.text = ""
	new_milestone_name_edit.grab_focus()

func _on_SaveUnsavedDialog_confirmed() -> void:
	project.save_all()
	_do_action_stack()

func _on_SaveUnsavedDialog_cancelled() -> void:
	print("Cleared action stack")
	_post_save_action_stack.clear()

func _on_task_grouping_changed(task_id:int, old_group_id:int, new_group_id:int)->void:
	var old_ms: Milestone = project.get_milestone(old_group_id)
	var new_ms: Milestone = project.get_milestone(new_group_id)
	var old_groupbox: GroupBox = _group_boxes[old_group_id] if old_ms else null
	var new_groupbox: GroupBox = _group_boxes[new_group_id] if new_ms else null
	
	#HACK: this whole method is a hack. Instead of smartly updating only what changed, 
	# we just nuke the things and have them reload. (The nuking happens at the top of load_ms
	if old_groupbox:
		old_groupbox.load_milestone(project, old_ms._id)
	if new_groupbox:
		new_groupbox.load_milestone(project, new_ms._id)
	project.save_all()

func _on_editied_task_title_change(task_id:int, new_title:String)->void:
	#TODO: if you're feeling like a refactor, allow all the places you display a tasks's title to update in real time
	pass 

func _on_editied_task_saved(task_id:int)->void:
	#HACK: no smart updates, just nukes
	project.save_all()
	_refresh_task_list()
	var milestone: Milestone = project.get_milestone(task_id)
	if !milestone: 
		return
	var group_box:GroupBox = _group_boxes[milestone._id]
	if group_box.is_expanded:
		group_box.load_milestone(project, milestone._id)
