extends Control
tool

# Types (don't pollute user namespace with class_name)
const GroupBox := preload("res://addons/gplanner/GroupVBox.gd")
const TicketEditor := preload("res://addons/gplanner/Editors/TicketEditor.gd")

# Scenes
const group_scene := preload("res://addons/gplanner/GroupVBox.tscn")
const ticket_editor := preload("res://addons/gplanner/Editors/TicketEditor.tscn")

export(NodePath) onready var inspector_container = get_node(inspector_container)
export var groups := ["Sprint", "Milestone1", "Backlog"]

onready var groups_container = $VSplitContainer/Body/Groups

var ticket_editor_instance:TicketEditor
var active_editor:Control

func _ready() -> void:
	ticket_editor_instance = ticket_editor.instance()
	for g in groups:
		var group_box:GroupBox = group_scene.instance()
		group_box.setup(g, ["test1", "test2", "test3"])
		groups_container.add_child(group_box)
		group_box.shrink()
		group_box.connect("item_clicked", self, "_handle_group_item_click")

func _exit_tree() -> void:
	if ticket_editor_instance != null:
		ticket_editor_instance.queue_free()

func set_inspector(type)->void:
	if type == TicketEditor:
		if active_editor != null:
			inspector_container.remove_child(active_editor)
		inspector_container.add_child(ticket_editor_instance)
		active_editor = ticket_editor_instance

func _handle_group_item_click(group_name, item_name)->void:
	pass


func _on_NewTicket_pressed() -> void:
	set_inspector(TicketEditor)
