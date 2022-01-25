extends Reference

const completed_task_priority = -1
const abandoned_task_priority = -2

enum Values {New, Active, Hold, Completed, Abandoned}
const Colors = [Color("#61e0fd"), Color("#f2fd61"), Color("#ffc156"), Color("#18c427"), Color("#aaa294")]

var id:int
var name:String
var color:Color
