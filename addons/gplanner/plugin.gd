extends EditorPlugin
tool

var thing

func enable_plugin() -> void:
	load("res://addons/gplanner/Widgets/PerItemColorPopupMenu/PerItemColorMenuButton.gd")
	thing = load("res://addons/gplanner/Nodes/MainPanel.tscn").instance()
	add_control_to_bottom_panel(thing, "Project Planning")

func disable_plugin() -> void:
	remove_control_from_bottom_panel(thing)
