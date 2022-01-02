extends Reference

const Task = preload("res://addons/gplanner/DataHelpers/Task.gd")

static func from_task(task:Task)->Dictionary:
	return {
		"id" : task._id,
		"title" : task.name,
		"milestone_id":task.milestone_id
	}
