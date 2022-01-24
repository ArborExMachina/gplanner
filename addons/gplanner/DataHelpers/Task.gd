extends Reference

signal changed(field, value)
enum Fields{Name, Description, Status, Priority}

var _unsaved_changes:bool = false

var _is_backed:bool = false
var _stored_ms_id:int

var id:int setget set_id, get_id
var name:String setget set_name, get_name
var description:String setget set_description, get_description
var status:int setget set_status, get_status
var priority:int setget set_priority, get_priority

class BindingData:
	var title:String
	var task_id:int
	var milestone_id:int
	var status:int
	var priority:int


func _init():
	_unsaved_changes = true
	name = "New Task"
	description = ""
	id = -1
	_is_backed = false


func get_id()->int:
	return id

func set_id(value:int)->void:
	if !_is_backed:
		id = value
		_is_backed = true
	else:
		push_error("Task Ids can not be changed")


func get_name()->String:
	return name

func set_name(value:String)->void:
	_unsaved_changes = true
	name = value
	emit_signal("changed", Fields.Name, value)


func get_description()->String:
	return description

func set_description(value:String)->void:
	_unsaved_changes = true
	description = value
	emit_signal("changed", Fields.Description, value)


func set_status(value:int)->void:
	_unsaved_changes = true
	status = value
	emit_signal("changed", Fields.Status, value)

func get_status()->int:
	return status


func set_priority(value:int)->void:
	_unsaved_changes = true
	priority = value
	emit_signal("changed", Fields.Priority, value)

func get_priority()->int:
	return priority
