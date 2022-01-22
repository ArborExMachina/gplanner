extends Reference

const save_format_version = 1
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
	_db.create_table("ProjectInfo", {
		"Field": {"data_type": "TEXT", "not_null": true, "primary_key": true},
		"Value": {"data_type": "TEXT", "not_null": true},
	})
	_db.query("INSERT INTO ProjectInfo (Field, Value) VALUES ('DBVersion', '%s');" % save_format_version)
	
	_db.create_table("Milestones", {
		"Id": {"data_type": "int", "not_null": true, "primary_key": true, "auto_increment": true},
		"Name": {"data_type": "TEXT", "not_null": true},
	})
	_db.create_table("Tasks", {
		"Id": {"data_type": "int", "not_null": true, "primary_key": true, "auto_increment": true},
		"Title": {"data_type": "TEXT", "not_null": true},
		"Description": {"data_type": "BLOB"},
		"Completed": {"data_type": "int", "not_null": true, "default": 0},
	})
	_db.create_table("TaskHierarchy", {
		"ParentId": {"data_type": "int", "not_null":true, "foreign_key": "Tasks.Id"},
		"ChildId": {"data_type": "int", "not_null":true, "foreign_key": "Tasks.Id"},
	})
	var q:String = """CREATE TABLE "MilestoneTasks" (
	"TaskID"	INTEGER NOT NULL UNIQUE,
	"MilestoneID"	INTEGER NOT NULL,
	FOREIGN KEY("TaskID") REFERENCES "Tasks"("Id"),
	FOREIGN KEY("MilestoneID") REFERENCES "Milestones"("Id")
);"""
	_do_query(q)

func _commit_task_milestone_link(task_id:int, ms_id:int)->void:
	if task_id < 0:
		return
	
	var query:String = "DELETE FROM MilestoneTasks WHERE TaskID = %s" % task_id
	_do_query(query)
	print(_db.query_result)
	
	query = "INSERT INTO MilestoneTasks (MilestoneID, TaskID) VALUES (%s, %s)" % [ms_id, task_id]
	_do_query(query)
	print(_db.query_result)

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
	
	var db_version:int = get_db_version()
	if db_version < save_format_version:
		migrate(db_version)
	
	return true


func get_db_version()->int:
	var q:String = "SELECT Value FROM ProjectInfo WHERE Field = 'DBVersion'"
	_do_query(q)
	if len(_db.query_result) != 1:
		push_error("failed to get db version")
	return int(_db.query_result[0].Value)


func migrate(from_version:int)->void:
	print("migrating db versions")
	var steps := {}
	var dir := Directory.new()
	dir.open("res://addons/gplanner/DataHelpers/VersionMigrations")
	dir.list_dir_begin(true, true)
	var file_name:String = dir.get_next()
	while file_name != "":
		if "sql" in file_name:
			var split:Array = file_name.split('.')
			var num:int = int(split[0])
			steps[num] = "%s/%s" % [dir.get_current_dir(), file_name]
		file_name = dir.get_next()
	
	for x in range(from_version, save_format_version):
		print("Running migration from version %s to %s" % [x, x + 1])
		var sql_file = File.new()
		var err = sql_file.open(steps[x], File.READ) 
		if err != OK:
			push_error("Failed to open sql migration file %s: %s" % [x, err])
		var sql_statement:String = sql_file.get_as_text()
		_do_query(sql_statement)
	
	var q:String = "UPDATE ProjectInfo SET VALUE = %s WHERE Field = 'DBVersion'" % save_format_version
	_do_query(q)
	print("Version migration successful")


func get_task_ids()->Array:
	return _db.select_rows("Tasks", "", ["Id"])

func get_milestone_ids()->Array:
	return _db.select_rows("Milestones", "", ["Id"])

func get_task_binding_data(id:int)->Task.BindingData:
	var query = """SELECT t.Id, mt.MilestoneID, t.Title 
					FROM Tasks t 
					LEFT OUTER JOIN MilestoneTasks mt on t.id = mt.TaskID
					WHERE t.id = %s""" % id
	_do_query(query)
	
	if _db.query_result == null or len(_db.query_result) != 1:
		return null
	
	var row = _db.query_result[0]
	var bd := Task.BindingData.new()
	bd.task_id = row.Id
	bd.milestone_id = row.MilestoneID if row.MilestoneID != null else -1
	bd.title = row.Title
	return bd


func get_all_task_binding_data()->Array:
	var query = """SELECT t.Id, mt.MilestoneID, t.Title 
					FROM Tasks t 
					LEFT OUTER JOIN MilestoneTasks mt on t.id = mt.TaskID"""
	_do_query(query)
	
	if _db.query_result == null or len(_db.query_result) < 1:
		return []
	
	var results := []
	for row in _db.query_result:
		var bd := Task.BindingData.new()
		bd.task_id = row.Id
		bd.milestone_id = row.MilestoneID if row.MilestoneID != null else -1
		bd.title = row.Title
		results.append(bd)
	return results


func commit_task(task:Task)->bool:
	var query:String
	var is_insert := false
	if task.id < 0:
		var row := {"Title": task.name, "Description": task.description.to_utf8()}
		_db.insert_row("Tasks", row)
		is_insert = true
	else:
		_db.update_rows("Tasks", "Id=%s" % task.id, {"Title":task.name, "Description": task.description.to_utf8()})
	
	#_do_query(query)
	if is_insert:
		task.id = _db.last_insert_rowid
	return true


func commit_milestone(ms:Milestone)->bool:
	var query:String
	var is_insert := false
	if ms.id < 0:
		query = "INSERT INTO Milestones (Name) VALUES ('%s')" % ms.milestone_name
		is_insert = true
	else:
		query = "UPDATE Milestones SET Name = '%s' WHERE Id = %s" % [ms.milestone_name, ms.id]
	
	_do_query(query)
	if is_insert:
		ms.id = _db.last_insert_rowid
	return true

func retrieve_task(task_id:int)->Task:
	var results:Array = _db.select_rows("Tasks", "Id = %s" % task_id, ["*"])
	if results == null or len(results) != 1:
		return null
	
	var data:Dictionary = results[0]
	var task:Task = Task.new()
	task.id = data.Id
	task.name = data.Title
	var raw_bytes = data.get("Description", PoolByteArray())
#	task.description = raw_bytes.get_string_from_utf8()
	if raw_bytes is PoolByteArray:
		task.description = raw_bytes.get_string_from_utf8()
	elif raw_bytes != null:
		var bytes:PoolByteArray
		var jpr := JSON.parse(raw_bytes)
		for i in jpr.result:
			bytes.append(int(i))
		task.description = bytes.get_string_from_utf8()
	
	results = _db.select_rows("MilestoneTasks", "TaskID = %s" % task_id, ["MilestoneID"])
	if results != null and len(results) == 1:
		task.milestone_id = results[0].MilestoneID
		
	task._unsaved_changes = false
	return task

func retrieve_all_milestone()->Array:
	var mss := []
	
	var results = _db.select_rows("Milestones", "", ["*"]).duplicate()
	for row in results:
		var ms := Milestone.new()
		ms.id = row.Id
		ms.milestone_name = row.Name
		var cfs = row.Color.split(",")
		ms._color = Color(float(cfs[0]), float(cfs[1]), float(cfs[2]), float(cfs[3]))
		
		var task_link_results = _db.select_rows("MilestoneTasks", "MilestoneID = %s" % ms.id, ["TaskID"])
		for task_link_row in task_link_results:
			ms.add_task(task_link_row.TaskID)
		
		ms._unsaved_changes = false
		mss.append(ms)
	
	return mss
