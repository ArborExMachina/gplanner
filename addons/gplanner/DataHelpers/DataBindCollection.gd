extends Reference

const TaskType = 0
const MSType = 0

class SourceBind:
	var _targets := []
	var _properties := []

	func add_target(target:Object, property:String)->void:
		for i in range(len(_targets)):
			var t:Object = _targets[i]
			var p:String = _properties[i]
			if t == target and p == property:
				return
		_targets.append(target)
		_properties.append(property)

	func remove_target(target:Object)->void:
		var i = len(_targets) - 1
		while(i >= 0):
			if _targets[i] == target:
				_targets.remove(i)
				_properties.remove(i)
			i -= 1

	func update_targets(new_value):
		for i in range(len(_targets)):
			var target:Object = _targets[i]
			var property:String = _properties[i]
			target.set(property, new_value)

var _source_binds := {}
var _bindkeys := {}

func _hash_array(array:Array)->int:
	return str(array).hash()

func bind(source_type:int, source_id:int, source_field_id:int, target:Object, property:String)->void:
	var hashkey:int = _hash_array([source_type, source_id, source_field_id])
	var bind:SourceBind = _source_binds.get(hashkey, null)
	
	if bind == null:
		bind = SourceBind.new()
		_source_binds[hashkey] = bind
		_bindkeys[target] = [hashkey]
	
	bind.add_target(target, property)

func unbind_target(target:Object)->void:
	var hashkeys:Array = _bindkeys.get(target, [])
	for hashkey in hashkeys:
		var source:SourceBind = _source_binds.get(hashkey, null)
		if source == null:
			continue
		source.remove_target(target)

func publish_change(source_type:int, source_id:int, source_field_id:int, new_value)->void:
	var hashkey:int = _hash_array([source_type, source_id, source_field_id])
	var bind:SourceBind = _source_binds.get(hashkey, null)
	
	if bind == null:
		return
	bind.update_targets(new_value)
