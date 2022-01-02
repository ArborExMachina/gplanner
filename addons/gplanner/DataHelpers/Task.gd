extends Reference

var _unsaved_changes:bool = false
var _id:int = -1
var name:String setget set_name, get_name
var description:String setget set_description, get_description
var milestone_id:int setget set_milestone_id, get_milestone_id

func _init(id:int):
	_unsaved_changes = true
	_id = id
	name = "Unnamed Task"
	description = "Enter Description"
	milestone_id = -1

func get_name()->String:
	return name

func set_name(value:String)->void:
	_unsaved_changes = true
	name = value

func get_description()->String:
	return description

func set_description(value:String)->void:
	_unsaved_changes = true
	description = value

func get_milestone_id()->int:
	return milestone_id

func set_milestone_id(value:int)->void:
	_unsaved_changes = true
	milestone_id = value

func commit_data(file:File)->bool:
	
	var data := {
		"id": _id,
		"name": name,
		"description": description,
	}
	var json = JSON.print(data)
	file.store_string(json)
	
	_unsaved_changes = false
	return true

func load_from_data(data:Dictionary)->void:
	_id = data.id
	name = data.name
	description = data.description
	_unsaved_changes = false
