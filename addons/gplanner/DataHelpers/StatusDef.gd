extends Reference

const completed_task_priority = -1
const abandoned_task_priority = -2

enum Values {New, Active, Hold, Completed, Abandoned}
const _colors = [Color("#61e0fd"), Color("#f2fd61"), Color("#ffc156"), Color("#18c427"), Color("#aaa294")]

static func get_color(status:int)->Color:
	return _colors[status]

var id:int
var name:String
var color:Color
