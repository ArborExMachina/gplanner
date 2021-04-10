tool
extends HBoxContainer

signal add_new_item()

export var list_name := "List"

onready var label:Label = $Label
onready var add_button:Button = $AddNew

func _ready() -> void:
	label.text = list_name

func add_item(item:Control)->void:
	add_child(item)
	move_child(add_button, get_child_count() - 1)

func _add_button_clicked()->void:
	emit_signal("add_new_item")