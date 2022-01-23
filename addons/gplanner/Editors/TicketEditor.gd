extends Control
tool

signal milestone_grouping_change(task_id, old_group_id, new_group_id)
signal title_changed(task_id, new_title)
signal task_changes_commited(task_id)
signal task_marked_complete(task_id)
signal task_marked_abandoned(task_id)
signal task_deleted(task_id)

const LinkList = preload("res://addons/gplanner/Widgets/LinkList.gd")
#const Project = preload("res://addons/gplanner/DataHelpers/Project.gd") cyclic reference D:<
const Milestone = preload("res://addons/gplanner/DataHelpers/Milestone.gd")
const Task = preload("res://addons/gplanner/DataHelpers/Task.gd")
const StatusEnum = preload("res://addons/gplanner/DataHelpers/StatusEnum.gd")

const ungrouped_name = "Ungrouped"
const ungrouped_id = -1

export(NodePath) var _task_name_path
export(NodePath) var _description_path
export(NodePath) var _blockedby_linklist_path
export(NodePath) var _blocks_linklist_path
export(NodePath) var _milestone_menu_button_path
export(NodePath) var _status_menu_button_path

onready var _task_name = get_node(_task_name_path) as LineEdit
onready var _description = get_node(_description_path) as TextEdit
onready var _blockedby_linklist = get_node(_blockedby_linklist_path) as LinkList
onready var _blocks_linklist = get_node(_blocks_linklist_path) as LinkList
onready var _milestone_menu_button = get_node(_milestone_menu_button_path) as MenuButton
onready var _status_menu_button = get_node(_status_menu_button_path) as MenuButton
onready var _milestone_menu:Popup = _milestone_menu_button.get_popup()
onready var _status_menu:PopupMenu = _status_menu_button.get_popup()

var _project = null
var _task:Task = null
var _external_titles := []
var _idle_timing := 10.0
var _auto_save_countdown := 0.0
var _needs_save := false


func _ready() -> void:
	_milestone_menu.connect("index_pressed", self, "_on_milestone_clicked")
	_status_menu.connect("index_pressed", self, "_on_status_clicked")


func _process(delta: float) -> void:
	if !_needs_save or !_project or !_task:
		return
	_auto_save_countdown -= delta
	if _auto_save_countdown <= 0:
		_project.save_task(_task.id)
		emit_signal("task_changes_commited", _task.id)
		_needs_save = false


func load_ticket(project, task_id:int)->bool:
	if _task:
		if _task.id == task_id:
			return true
		project.close_task(_task.id)
	
	_clear()
	_project = project
	
	if task_id <= 0:
		_task = project.open_new_task()
	else:
		_task = project.open_task(task_id)
	
	_task_name.placeholder_text = "enter a title"
	var current_milestone = project.get_milestone(_task.milestone_id)
	if current_milestone:
		_milestone_menu_button.text = current_milestone.milestone_name
	else:
		_milestone_menu_button.text = "Ungrouped"
	_task_name.text = _task.name
	_description.text = _task.description
	_status_menu_button.text = StatusEnum.Values.keys()[_task.status]
	for ms in project.get_milestones():
		ms = ms as Milestone
		_milestone_menu.add_item(ms.milestone_name, ms.id)
	_milestone_menu.add_item("Ungrouped")
	
	_task_name.grab_focus()
	return true


func update_milestone_options(new_milestone:Milestone)->void:
	if !_milestone_menu: return
	_milestone_menu.add_item(new_milestone.milestone_name, new_milestone.id)


func _queue_save()->void:
	_needs_save = true
	_auto_save_countdown = _idle_timing


func _clear()->void:
	_project = null
	_task = null
	_task_name.text = ""
	_task_name.placeholder_text = "select a task to continue"
	_description.text = ""
	_milestone_menu.clear()
	_milestone_menu_button.text = ""


func add_blockedby(title:String)->void:
	var new_link := Button.new()
	new_link.text = title
	new_link.flat = true
	_blockedby_linklist.add_item(new_link)


func add_blocks(title:String)->void:
	var new_link := Button.new()
	new_link.text = title
	new_link.flat = true
	_blocks_linklist.add_item(new_link)


func _add_new_blockedby()->void:
	_queue_save()


func _add_new_blocks()->void:
	_queue_save()
	

func _complete_task()->void:
	emit_signal("task_marked_complete", _task.id)
	_project.complete_task(_task.id)

func _abandon_task()->void:
	emit_signal("task_marked_abandoned", _task.id)
	_project.abandon_task(_task.id)


func _delete_task()->void:
	emit_signal("task_deleted", _task.id)
	_project.delete_task(_task.id)
	_clear()


########################
#### Event Handlers ####
########################

func _on_milestone_clicked(index:int)->void:
	_queue_save()
	var ms_name = _milestone_menu.get_item_text(index)
	var ms_id = _milestone_menu.get_item_id(index) if ms_name != ungrouped_name else ungrouped_id
	_milestone_menu_button.text = ms_name
	
	var old_ms_id = _task.milestone_id
	_project.assign_task_to_milestone(_task.id, ms_id)
	var new_ms_id = _task.milestone_id
	
	emit_signal("milestone_grouping_change", _task.id, old_ms_id, new_ms_id)


func _on_status_clicked(index:int)->void:
	_queue_save()
	var status_id = _status_menu.get_item_id(index)
	_status_menu_button.text = _status_menu.get_item_text(status_id)
	_task.status = status_id
	match status_id:
		StatusEnum.Values.Completed:
			_complete_task()
		StatusEnum.Values.Abandoned:
			_abandon_task()


func _on_Name_text_changed(new_text: String) -> void:
	_queue_save()
	_task.name = new_text
	emit_signal("title_changed", _task.id, new_text)


func _on_Description_text_changed() -> void:
	_queue_save()
	_task.description = _description.text


func _on_SaveButton_pressed() -> void:
	if !_task or !_project: return
	var task_id:int = _task.id
	_task.name = _task_name.text
	_project.save_task(_task.id) # ensure that the new task is part of the project, not a stray saved file
	emit_signal("task_changes_commited", task_id)


func _on_Name_text_entered(new_text: String) -> void:
	if !_task or !_project: return
	var task_id:int = _task.id
	_task.name = _task_name.text
	_project.save_task(_task.id) # ensure that the new task is part of the project, not a stray saved file
	emit_signal("task_changes_commited", task_id)


func _on_DeleteButton_pressed() -> void:
	_delete_task()


func _on_AbandonButton_pressed() -> void:
	_abandon_task()


func _on_CompleteButton_pressed() -> void:
	_complete_task()
