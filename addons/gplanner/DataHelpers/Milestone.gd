extends Reference

signal changed(field, value)
enum Fields{Name, Colr}

var _unsaved_changes:bool = false
var _is_backed:bool = false
var id:int setget set_id, get_id
var milestone_name:String setget set_ms_name, get_ms_name
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

func get_ms_name()->String:
	return milestone_name

func set_ms_name(value:String)->void:
	_unsaved_changes = true
	milestone_name = value
	emit_signal("changed", Fields.Name, value)
