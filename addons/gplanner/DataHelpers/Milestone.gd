extends Reference

const Task = preload("res://addons/gplanner/DataHelpers/Task.gd")

var _id:int
var _unsaved_changes:bool = false
var _is_backed:bool = false
var id:int setget set_id, get_id
var milestone_name:String setget set_ms_name, get_ms_name
var _task_ids := []
var _color:Color

func _init(id:int) -> void:
	_unsaved_changes = true
	_id = id
	_color = Color(
		randf(),
		randf(),
		randf(),
		1.0
	)

func get_id()->int:
	return id

func set_id(value:int)->void:
	if !_is_backed:
		id = value
		_is_backed = true
	else:
		push_error("Task Ids can not be changed")

func add_task(id:int)->void:
	if id in _task_ids:
		return
	_unsaved_changes = true
	_task_ids.append(id)

func remove_task(id:int)->void:
	var index:int = -1
	var i:int = 0
	for tid in _task_ids:
		if tid == id:
			index = i
		i += 1
	if index > -1:
		_unsaved_changes = true
		_task_ids.remove(index)

func get_task_ids()->Array:
	return _task_ids

func contains_task(id:int)->bool:
	return id in _task_ids

func get_ms_name()->String:
	return milestone_name

func set_ms_name(value:String)->void:
	_unsaved_changes = true
	milestone_name = value

func commit_data(milestone_list:Array)->void:
	milestone_list.append({
		"id": _id,
		"name": milestone_name,
		"task_ids": _task_ids,
		"color": _color
	})
	_unsaved_changes = false

func load_from_data(data:Dictionary):
	_id = data.id
	milestone_name = data.name
	_task_ids = data.task_ids
	
	var cs = data.color.split(",")
	_color = Color(float(cs[0]), float(cs[1]), float(cs[2]), float(cs[3]))
	
	_unsaved_changes = false
