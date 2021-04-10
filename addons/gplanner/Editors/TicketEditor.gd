extends Control

export(NodePath) onready var blockedby_linklist = get_node(blockedby_linklist)
export(NodePath) onready var blocks_linklist = get_node(blocks_linklist)

func load_ticket(ticket)->void:
	pass

func add_blockedby(title:String)->void:
	var new_link := Button.new()
	new_link.text = title
	new_link.flat = true
	blockedby_linklist.add_item(new_link)

func add_blocks(title:String)->void:
	var new_link := Button.new()
	new_link.text = title
	new_link.flat = true
	blocks_linklist.add_item(new_link)

func _add_new_blockedby()->void:
	pass

func _add_new_blocks()->void:
	pass
