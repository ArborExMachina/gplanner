extends VBoxContainer
tool

const Milestone = preload("res://addons/gplanner/DataHelpers/Milestone.gd")
const Task = preload("res://addons/gplanner/DataHelpers/Task.gd")

signal item_clicked(task_id)

var is_expanded:bool = false

var _milestone:Milestone

onready var member_box = $MemberArea
onready var vbox = $MemberArea/VBoxContainer

func load_milestone(project, milestone_id:int)->void:
	
	var children = vbox.get_children()
	for child in children:
		vbox.remove_child(child)
		child.queue_free()
	
	_milestone = project.get_milestone(milestone_id)
	var group_button = $GroupButton
	group_button.text = _milestone.milestone_name
	for task_id in _milestone.get_task_ids():
		var task_button := Button.new()
		vbox.add_child(task_button)
		task_button.text = project.get_task_title(task_id)
		task_button.connect("button_down", self, "item_button_clicked", [task_id, task_button])
		task_button.focus_mode = Control.FOCUS_NONE
		task_button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		task_button.align = Button.ALIGN_LEFT

	var norm_sb:StyleBoxFlat = StyleBoxFlat.new()
	norm_sb.bg_color = _milestone._color
	group_button.add_stylebox_override("normal", norm_sb)
	
	var pressed_sb:StyleBoxFlat = StyleBoxFlat.new()
	pressed_sb.bg_color = _milestone._color
	pressed_sb.border_color = _milestone._color.darkened(0.2)
	pressed_sb.border_width_left = 10
	group_button.add_stylebox_override("pressed", pressed_sb)
		
	if is_expanded:
		shrink()
		expand()

func expand()->void:
	add_child(member_box)
	is_expanded = true


func shrink()->void:
	remove_child(member_box)
	is_expanded = false


func item_button_clicked(task_id:int, task_button:Button)->void:
	emit_signal("item_clicked", task_id)


func _on_GroupButton_toggled(button_pressed: bool) -> void:
	if(button_pressed):
		expand()
	else:
		shrink()
