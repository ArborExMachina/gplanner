extends Resource

const save_format_version = 0.1
const _working_dir = "user://Projects"

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
var _task_data := {}

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

func new_milestone(name:String)->Milestone:
	_unsaved_changes = true
	var ms = Milestone.new(_nextTaskID)
	_nextTaskID += 1
	ms.milestone_name = name
	ms._id
	_milestones[ms._id] = ms
	return ms

func get_milestones()->Array:
	return _milestones.values()

func get_milestone(id:int)->Milestone:
	if id in _milestones:
		return _milestones[id]
	else:
		return null

func get_all_task_data()->Array:
	var arr := []
	for data in _task_data.values():
		arr.append(data)
	return arr

func get_task_title(task_id:int)->String:
	var data = _task_data.get(task_id, null)
	return data.title if data else "TASK NOT FOUND"

func open_new_task()->Task:
	_unsaved_changes = true
	var task := Task.new(_nextTaskID)
	_nextTaskID += 1
	_open_tasks[task._id] = task
	
	var task_data:TaskData
	_task_data[task._id] = TaskData.from_task(task)
	
	save_all()
	return task

func open_task(id:int)->Task:
	if id in _open_tasks:
		return _open_tasks[id]
	
	var file = File.new()
	file.open("%s/%s.json" % [_dir_root(), id], File.READ)
	var json = file.get_as_text()
	var data = JSON.parse(json).result
	file.close()
	var task:Task = Task.new(-1)
	task.load_from_data(data)
	if task._id in _open_tasks:
		push_error("task '%s' id %s differs from provided id of %s" % [task.name, task._id, id])
		return null
	_open_tasks[task._id] = task
	var x = _task_data[task._id]
	var y = x.milestone_id
	task.milestone_id = y
	#task.milestone_id = _task_data[task._id].milestone_id
	task._unsaved_changes = false
	return task

func save_task(id:int)->void:
	var task := _open_tasks.get(id, null) as Task
	_dsource.commit_task(task)
	if task:
		var file := File.new()
		file.open("%s/%s.json" % [_dir_root(), task.id], File.WRITE)
		task.commit_data(file)
		file.close()
		_task_data[id] = TaskData.from_task(task)

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
	var task_data = _task_data[task_id]
	var old_ms:Milestone = get_milestone(task_data.milestone_id)
	var new_ms:Milestone = get_milestone(ms_id)
	
	if old_ms:
		old_ms.remove_task(task_id)
	if new_ms:
		new_ms.add_task(task_id)
		task_data.milestone_id = new_ms._id
	else:
		task_data.milestone_id = -1
	
	var task:Task = _open_tasks.get(task_id, null)
	if task:
		task.milestone_id = task_data.milestone_id

func open(name:String)->bool:
	_dsource = DataSource.new()
	_dsource.open(name)
	_name = name
	var dir = Directory.new()
	var data_file = File.new()
	if dir.dir_exists(_dir_root()):
		data_file.open(_data_path(), File.READ)
		
		var json:String = data_file.get_as_text()
		var data:Dictionary = JSON.parse(json).result
		
		if data.save_format_version != save_format_version:
			printerr("Expected save format version %s, found %s" % [save_format_version, data.save_format_version])
			return false
		_nextTaskID = data.nextTaskID
		for task_dict in data.task_data:
			task_dict.id = int(task_dict.id)
			_task_data[task_dict.id] = task_dict
			open_task(task_dict.id)
		
		for ms in data["milestones"]:
			var milestone := Milestone.new(-1)
			milestone.load_from_data(ms)
			_milestones[milestone._id] = milestone
		
		return true
	else:
		dir.make_dir(_dir_root())
		var saved := save_all()
		return saved

func save_all()->bool:
	var milestones_data = []
	for ms in _milestones:
		ms = _milestones[ms] as Milestone
		ms.commit_data(milestones_data)
		_dsource.commit_milestone(ms)
	
	for id in _open_tasks:
		save_task(id)
	
	for ms in _milestones:
		ms = _milestones[ms] as Milestone
		for tid in ms._task_ids:
			var task:Task = _open_tasks[int(tid)] as Task
			_dsource._commit_task_milestone_link(task.id, ms.id)
		
	
	var flat_task_data := []
	for task_data in _task_data.values():
		flat_task_data.append(task_data)
	
	var data := {
		"save_format_version" : save_format_version,
		"nextTaskID" : _nextTaskID,
		"milestones" : milestones_data,
		"task_data" : flat_task_data
	}
	var json = JSON.print(data, "\t")
	
	var proj_data_file = File.new()
	proj_data_file.open(_data_path(), File.WRITE)
	proj_data_file.store_string(json)
	
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
