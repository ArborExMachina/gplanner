extends Reference

var targets:Array
var property:String

func update(new_value):
	for t in targets:
		if t != null and is_instance_valid(t):
			t.set(property, new_value)
