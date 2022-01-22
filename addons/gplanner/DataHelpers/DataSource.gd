extends Reference

const save_format_version = 0.1
const _working_dir = "user://Projects"

const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")
const Task = preload("res://addons/gplanner/DataHelpers/Task.gd")
const Milestone = preload("res://addons/gplanner/DataHelpers/Milestone.gd")


static func list_source_dirs()->Array:
	var dir_names := []
	var dir = Directory.new()
	var dir_status = dir.open(_working_dir)
	if dir_status == OK:
		dir.list_dir_begin()
		var file_name:String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not "." in file_name:
				dir_names.append(file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path. Error code %s." % dir_status)
	return dir_names


var _db:SQLite


func _source_dir_path(source_name:String)->String:
	return "%s/%s" % [_working_dir, source_name]
	

func _data_path(source_name:String)->String:
	return "%s/Data.db" % _source_dir_path(source_name)


func _init_db()->void:
	_db.create_table("Milestones", {
		"Id": {"data_type": "int", "not_null": true, "primary_key": true, "auto_increment": true},
		"Name": {"data_type": "text", "not_null": true},
	})
	_db.create_table("Tasks", {
		"Id": {"data_type": "int", "not_null": true, "primary_key": true, "auto_increment": true},
		"Title": {"data_type": "text", "not_null": true},
		"Description": {"data_type": "blob"},
	})
	_db.create_table("TaskHierarchy", {
		"ParentId": {"data_type": "int", "not_null":true, "foreign_key": "Tasks.Id"},
		"ChildId": {"data_type": "int", "not_null":true, "foreign_key": "Tasks.Id"},
	})
	_db.create_table("MilestoneTasks", {
		"TaskID": {"data_type": "int", "not_null":true, "foreign_key": "Tasks.Id"},
		"MilestoneID": {"data_type": "int", "not_null":true, "foreign_key": "Milestones.Id"},
	})

func _commit_task_milestone_link(task_id:int, ms_id:int)->void:
	var query = "INSERT INTO MilestoneTasks (MilestoneID, TaskID) VALUES (%s, %s)" % [ms_id, task_id]
	_do_query(query)

func _do_query(query:String)->void:
	if !_db.query(query):
		push_error("%s %s" % [query, _db.error_message])


func open(source_name:String)->bool:
	var dir := Directory.new()
	var path:String = _source_dir_path(source_name)
	if !dir.dir_exists(path):
		print("Creating new directory:")
		print(path)
		dir.make_dir_recursive(path)
	
	var db_path = _data_path(source_name)
	var is_new:bool = !dir.file_exists(db_path)
	_db = SQLite.new()
	_db.path = db_path
	_db.foreign_keys = true
	if not _db.open_db():
		push_error("failed to open the %s db" % source_name)
		return false
	if is_new:
		_init_db()
	
	return true


func get_task_ids()->Array:
	return _db.select_rows("Tasks", "", ["Id"])

func get_milestone_ids()->Array:
	return _db.select_rows("Milestones", "", ["Id"])

func get_task_binding_data(id:int)->Array:
	var query = "SELECT t.Id, mt.MilestoneID, t.Title FROM Tasks t LEFT OUTER JOIN MilestoneTasks on t.id = mt.TaskID"
	_do_query(query)
	
	var data := []
	for result in _db.query_result:
		var x = Task.BindingData.new()
		
		data.append(x)
	
	return data

func commit_task(task:Task)->bool:
	var query:String
	var is_insert := false
	if true:#task.id < 0:
		var values := [task.name, task.description.to_utf8()]
		query = "INSERT INTO Tasks (Title, Description) VALUES ('%s', '%s')" % values
		is_insert = true
	else:
		query = "UPDATE Tasks SET Title = %s, Description = '%s' WHERE Id = %s" % [task.name, task.description, task.id]
	
	if _db.query(query):
		if is_insert:
			task.id = _db.last_insert_rowid
		return true
	else:
		push_error("%s %s" % [query, _db.error_message])
		return false

func commit_milestone(ms:Milestone)->bool:
	var query:String
	var is_insert := false
	if true:#ms.id < 0:
		query = "INSERT INTO Milestones (Name) VALUES ('%s')" % ms.milestone_name
		is_insert = true
	else:
		query = "UPDATE Milestones SET Name = '%s' WHERE Id = %s" % [ms.milestone_name, ms.id]
	
	if _db.query(query):
		if is_insert:
			ms.id = _db.last_insert_rowid
	else:
		push_error("%s %s" % [query, _db.error_message])
		return false
	
	return true

func retrieve_task(task_id:int)->Task:
	var results:Array = _db.select_rows("Tasks", "Id = %s" % task_id, ["*"])
	if results == null or len(results) != 1:
		return null
	
	var task:Task = Task.new()
	
	
	return null

func retrieve_milestone(ms_id:int)->Milestone:
	return null
