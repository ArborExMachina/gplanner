extends VBoxContainer
tool

signal want_edit_milestone(ms)
signal want_add_task_to_ms(ms)

const Milestone = preload("res://addons/gplanner/DataHelpers/Milestone.gd")
const Task = preload("res://addons/gplanner/DataHelpers/Task.gd")
const DataBinder = preload("res://addons/gplanner/DataHelpers/DataBindCollection.gd")
const StatusDef = preload("res://addons/gplanner/DataHelpers/StatusDef.gd")

signal item_clicked(task_id)

var is_expanded:bool = false

var _project
var _milestone:Milestone
var _data_binds:DataBinder

onready var member_box = $MemberArea
onready var vbox = $MemberArea/VBoxContainer
onready var group_button = $GroupButton


func _exit_tree() -> void:
	if !is_expanded and member_box:
		member_box.queue_free()

func load_milestone(project, milestone_id:int, data_binds:DataBinder, show_hidden:bool)->void:
	_project = project
	_milestone = project.get_milestone(milestone_id)
	_data_binds = data_binds
	group_button.text = _milestone.milestone_name
	
	var norm_sb:StyleBoxFlat = StyleBoxFlat.new()
	norm_sb.bg_color = _milestone._color
	
	var pressed_sb:StyleBoxFlat = StyleBoxFlat.new()
	pressed_sb.bg_color = _milestone._color
	pressed_sb.border_color = _milestone._color.darkened(0.2)
	pressed_sb.border_width_left = 10
	
	var hover:StyleBoxFlat = StyleBoxFlat.new()
	pressed_sb.bg_color = _milestone._color.darkened(0.2)
	
	group_button.add_stylebox_override("normal", norm_sb)
	group_button.add_stylebox_override("pressed", pressed_sb)
	group_button.add_stylebox_override("hover", hover)
	$GroupButton/HBoxContainer.modulate = _milestone._color
	
	refresh_member_list(show_hidden)

func clear()->void:
	var children = vbox.get_children()
	for child in children:
		vbox.remove_child(child)
		_data_binds.unbind_target(child)
		child.queue_free()

func refresh_member_list(show_hidden)->void:
	clear()
	
	for task_data in _project.get_milestone_tasks(_milestone.id):
		if (!show_hidden 
			and( task_data.status == StatusDef.Values.Completed 
			or task_data.status == StatusDef.Values.Abandoned)):
			continue
		var task_button := Button.new()
		vbox.add_child(task_button)
		task_button.text = task_data.title
		task_button.connect("button_down", self, "item_button_clicked", [task_data.task_id, task_button])
		task_button.focus_mode = Control.FOCUS_NONE
		task_button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		task_button.align = Button.ALIGN_LEFT
		task_button.self_modulate = StatusDef.get_color(task_data.status)
		
		_data_binds.bind(DataBinder.TaskType, task_data.task_id, Task.Fields.Name, task_button, "text")
		_data_binds.bind(DataBinder.TaskType, task_data.task_id, Task.Fields.Status, task_button, "self_modulate")
		
	update()

func expand()->void:
	if is_expanded:
		return
	add_child(member_box)
	is_expanded = true


func shrink()->void:
	if !is_expanded:
		return
	remove_child(member_box)
	is_expanded = false


func item_button_clicked(task_id:int, task_button:Button)->void:
	emit_signal("item_clicked", task_id)


func _on_GroupButton_toggled(button_pressed: bool) -> void:
	if(button_pressed):
		expand()
	else:
		shrink()


func _on_EditButton_pressed() -> void:
	emit_signal("want_edit_milestone", _milestone)


func _on_DeleteButton_pressed() -> void:
	_project.delete_milestone(_milestone.id)


func _on_AddTaskButton_pressed() -> void:
	emit_signal("want_add_task_to_ms", _milestone)
