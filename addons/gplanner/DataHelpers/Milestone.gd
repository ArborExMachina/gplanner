extends Reference

var _unsaved_changes:bool = false
var _is_backed:bool = false
var id:int setget set_id, get_id
var milestone_name:String setget set_ms_name, get_ms_name
var _task_ids := []
var _color:Color

func _init() -> void:
	_unsaved_changes = true
	_color = Color(
		randf(),
		randf(),
		randf(),
		1.0
	)
	id = -1
	_is_backed = false

func get_id()->int:
	return id

func set_id(value:int)->void:
	if !_is_backed:
		id = value
		_is_backed = true
	else:
		push_error("Milestone ids can not be changed")

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
