extends Reference

const save_format_version = 0.1
const _working_dir = "user://Projects"

signal abandoned_task(id)
signal completed_task(id)
signal deleted_task(id)
signal deleted_milestone(id)
signal task_opened(task)
signal milestone_created(ms)

#types
const Milestone = preload("res://addons/gplanner/DataHelpers/Milestone.gd")
const Task = preload("res://addons/gplanner/DataHelpers/Task.gd")
const TaskData = preload("res://addons/gplanner/DataHelpers/TaskData.gd")
const DataSource = preload("res://addons/gplanner/DataHelpers/DataSource.gd")

var _dsource:DataSource
var _unsaved_changes:bool = false
var _name:String = "Default"
var _nextTaskID:int = 1
var _milestones := {}
var _open_tasks := {}


static func set_working_dir()->String:
	var dir := Directory.new()
	if !dir.dir_exists(_working_dir):
		dir.make_dir(_working_dir)
	
	return _working_dir

static func list_projects()->Array:
	var project_names := []
	var dir = Directory.new()
	var dir_status = dir.open(_working_dir)
	if dir_status == OK:
		dir.list_dir_begin()
		var file_name:String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not "." in file_name:
				project_names.append(file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path. Error code %s." % dir_status)
	return project_names

func _dir_root()->String:
	return "%s/%s" % [_working_dir, _name]
	
func _data_path()->String:
	return "%s/ProjectData.json" % _dir_root()

func _remove_task_from_milestone(task_id:int)->void:
	if task_id < 0:
		return
	var binding_data:Task.BindingData = _dsource.get_task_binding_data(task_id)
	if binding_data.milestone_id < 0:
		return
	
	if task_id in _open_tasks:
		var task:Task = _open_tasks[task_id]
		task.milestone_id = -1
		_dsource.commit_task(task)
	
	for ms in _milestones:
		if ms.contains_task(task_id):
			ms.remove_task(task_id)
			_dsource.commit_milestone(ms)


func new_milestone(name:String)->Milestone:
	_unsaved_changes = true
	var ms = Milestone.new()
	_nextTaskID += 1
	ms.milestone_name = name
	ms.id
	_milestones[ms.id] = ms
	emit_signal("milestone_created", ms)
	return ms

func get_milestones()->Array:
	return _milestones.values()

func get_milestone(id:int)->Milestone:
	return _milestones.get(id, null)

func get_all_task_data()->Array:
	return _dsource.get_all_task_binding_data()

func get_task_title(task_id:int)->String:
	var data = _dsource.get_task_binding_data(task_id)
	return data.title if data else "TASK NOT FOUND"

func open_new_task()->Task:
	_unsaved_changes = true
	var task := Task.new()
	_open_tasks[task.id] = task
	
	
	save_all()
	emit_signal("task_opened", task)
	return task

func open_task(id:int)->Task:
	if id in _open_tasks:
		return _open_tasks[id]
		
	var task:Task = _dsource.retrieve_task(id)

	if task.id in _open_tasks:
		push_error("task '%s' id %s differs from provided id of %s" % [task.name, task.id, id])
		return null
	_open_tasks[task.id] = task
	emit_signal("task_opened", task)
	return task

func save_task(id:int)->bool:
	var task := _open_tasks.get(id, null) as Task
	if task == null:
		return false
	_dsource.commit_task(task)
	return true

func close_task(id:int)->void:
	save_task(id)
	_open_tasks.erase(id)

func is_task_open(id:int)->bool:
	return id in _open_tasks

func get_open_task(id:int)->Task:
	if id in _open_tasks:
		return _open_tasks[id]
	else:
		return null

func assign_task_to_milestone(task_id:int, ms_id:int)->void:
	_unsaved_changes = true
	var task_data:Task.BindingData = _dsource.get_task_binding_data(task_id)
	var old_ms:Milestone = get_milestone(task_data.milestone_id)
	var new_ms:Milestone = get_milestone(ms_id)
	
	if old_ms:
		old_ms.remove_task(task_id)
	if new_ms:
		new_ms.add_task(task_id)
		task_data.milestone_id = new_ms.id
	else:
		task_data.milestone_id = -1
	
	var task:Task = _open_tasks.get(task_id, null)
	if task:
		task.milestone_id = task_data.milestone_id

func open(name:String)->bool:
	_dsource = DataSource.new()
	_dsource.open(name)
	_name = name
		
	for ms in _dsource.retrieve_all_milestone():
		ms = ms as Milestone
		if ms == null:
			push_error("added a null milestone")
		_milestones[ms.id] = ms
		
	return true


func save_all()->bool:
	for ms in _milestones:
		ms = _milestones[ms] as Milestone
		_dsource.commit_milestone(ms)
	
	for id in _open_tasks:
		save_task(id)
	
	_unsaved_changes = false
	return true


func is_saved_since_changes() -> bool:
	if _unsaved_changes:
		return false
	for ms in _milestones:
		ms = _milestones[ms]
		if ms._unsaved_changes:
			return false
	for tsk in _open_tasks:
		tsk = _open_tasks[tsk]
		if tsk._unsaved_changes:
			return false
	return true


func complete_task(id:int)->void:
	_remove_task_from_milestone(id)
	emit_signal("completed_task", id)

func abandon_task(id:int)->void:
	_remove_task_from_milestone(id)
	emit_signal("abandoned_task", id)

func delete_task(id:int)->void:
	_remove_task_from_milestone(id)
	close_task(id)
	_dsource.delete_task(id)
	emit_signal("deleted_task", id)

func delete_milestone(id:int)->void:
	_dsource.delete_milestone(id)
	_milestones.erase(id)
	emit_signal("deleted_milestone", id)
