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
const StatusEnum = preload("res://addons/gplanner/DataHelpers/StatusEnum.gd")
const DataBind = preload("res://addons/gplanner/DataHelpers/DataBind.gd")

# Scenes
const group_scene := preload("res://addons/gplanner/GroupVBox.tscn")
const ticket_editor := preload("res://addons/gplanner/Editors/TicketEditor.tscn")

export var inspector_container_path:NodePath
export var groups_container_path:NodePath
export var open_project_popup_path:NodePath
export var new_project_popup_path:NodePath
export var new_project_lineedit_path:NodePath
export var project_name_label_path:NodePath
export var new_milestone_popup_path:NodePath
export var new_milestone_name_edit_path:NodePath
export var save_changes_dialog_path:NodePath
export var task_backlog_container_path:NodePath

onready var inspector_container:MarginContainer = get_node(inspector_container_path)
onready var groups_container:VBoxContainer = get_node(groups_container_path)
onready var open_project_popup:PopupMenu = get_node(open_project_popup_path)
onready var new_project_popup:AcceptDialog = get_node(new_project_popup_path)
onready var new_project_lineedit:LineEdit = get_node(new_project_lineedit_path)
onready var project_name_label:Label = get_node(project_name_label_path)
onready var new_milestone_popup:AcceptDialog = get_node(new_milestone_popup_path)
onready var new_milestone_name_edit:LineEdit = get_node(new_milestone_name_edit_path)
onready var save_changes_dialog = get_node(save_changes_dialog_path)
onready var task_backlog_container:VBoxContainer = get_node(task_backlog_container_path)

var project:Project
var ticket_editor_instance:TicketEditor
var active_editor:Control
var _post_save_action_stack := []
var _action_stack_locked := false
var _group_boxes := {}
var _data_binds := {}

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

func _unhandled_key_input(event: InputEventKey) -> void:
	if event.is_action_pressed("save_all") and project != null:
		print("saving")
		project.save_all()

func _do_action_stack()->void:
	if _action_stack_locked: 
		return
	
	_action_stack_locked = true
	while len(_post_save_action_stack) > 0:
		var action = _post_save_action_stack.pop_back()
		callv(action[0], action[1])
	
	_action_stack_locked = false

func _update_task_name(new_name:String)->void:
	pass

func _update_task_milestoneID(new_id:int)->void:
	pass

func _update_task_status(task:Task)->void:
	_refresh_task_list()

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
	var children := groups_container.get_children()
	for child in children:
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
	
	project.connect("abandoned_task", self, "_on_task_abandoned")
	project.connect("completed_task", self, "_on_task_completed")
	project.connect("deleted_task", self, "_on_task_deleted")
	project.connect("deleted_milestone", self, "_on_milestone_deleted")
	project.connect("milestone_created", self, "_register_observer_milestone")
	project.connect("task_opened", self, "_register_observer_task")

func _refresh_task_list(only_clear:bool = false)->void:
	var task_buttons = task_backlog_container.get_children()
	for tb in task_buttons:
		task_backlog_container.remove_child(tb)
		tb.queue_free()
	
	if only_clear: return
	
	for task_data in project.get_all_task_data():
		if (task_data.milestone_id > 0 
			or task_data.status == StatusEnum.Values.Abandoned 
			or task_data.status == StatusEnum.Values.Completed):
			continue
		var task_button = Button.new()
		task_backlog_container.add_child(task_button)
		task_button.text = task_data.title
		task_button.clip_text = true
		task_button.connect("pressed", self, "_handle_task_click", [task_data.task_id])
		
		var key := [task_data.task_id, Task.Fields.Name, "text"]
		var data_bind:DataBind = _data_binds.get(key, DataBind.new())
		if len(data_bind.targets) == 0:
			_data_binds[key] = data_bind
			data_bind.property = "text"
		data_bind.targets.append(task_button)

func _add_milestone(milestone:Milestone)->void:
	var group_box:GroupBox = group_scene.instance()
	groups_container.add_child(group_box)
	group_box.load_milestone(project, milestone.id, _data_binds)
	group_box.shrink()
	group_box.connect("item_clicked", self, "_handle_task_click")
	_group_boxes[milestone.id] = group_box
	ticket_editor_instance.update_milestone_options(milestone)

func _remove_milestone(id:int)->void:
	pass

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
		old_groupbox.load_milestone(project, old_ms.id, _data_binds)
	if new_groupbox:
		new_groupbox.load_milestone(project, new_ms.id, _data_binds)
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
	var group_box:GroupBox = _group_boxes[milestone.id]
	if group_box.is_expanded:
		group_box.load_milestone(project, milestone.id, _data_binds)


func _on_task_abandoned(id:int)->void:
	_refresh_task_list()
	

func _on_task_completed(id:int)->void:
	_refresh_task_list()


func _on_task_deleted(id:int)->void:
	_refresh_task_list()
	

func _on_milestone_deleted(id:int)->void:
	_remove_milestone(id)
	_refresh_task_list()


func _register_observer_milestone(ms:Milestone)->void:
	ms.connect("changed", self, "_on_milestone_changed", [ms])


func _register_observer_task(task:Task)->void:
	task.connect("changed", self, "_on_task_changed", [task])


func _on_milestone_changed(field:int, value, ms:Milestone)->void:
	pass

# Honestly, probably just use an event bus
func _on_task_changed(field:int, value, task:Task)->void:
	var key:Array
	match field:
		Task.Fields.Name:
			key = [task.id, Task.Fields.Name, "text"]
	
	if key in _data_binds:
		_data_binds[key].update(value)
