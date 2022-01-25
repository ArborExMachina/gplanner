extends Button

const PerItemPopupMenu = preload("res://addons/gplanner/Widgets/PerItemColorPopupMenu/PerItemColorPopupMenu.gd")

const timeout = 0.1

onready var _popup:PerItemPopupMenu = $PerItemColorPopupMenu

var _mouse_over_self:bool = false
var _mouse_over_child:bool = false
var _timer:float
var _selected_index:int


#func _process(delta: float) -> void:
#	if !_popup.visible or _mouse_over_child or _mouse_over_self:
#		return
#
#	if _timer > 0:
#		_timer -= delta
#	else:
#		_popup.hide()


func get_popup()->PerItemPopupMenu:
	return _popup


func set_selected(index:int)->void:
	text = _popup.get_item_text(index)
	self_modulate = _popup.get_item_color(index)

func _on_pressed() -> void:
	_mouse_over_child = false
	_mouse_over_self = true
	_timer = timeout
	_popup.popup()


func _on_mouse_entered() -> void:
	_mouse_over_child = false
	_mouse_over_self = true
	_timer = timeout


func _on_mouse_exited() -> void:
#	_mouse_over_self = false
#	_mouse_over_child = false
#	_timer = timeout
	if _mouse_over_child:
		return
#	_popup.hide()

func _on_PerItemColorPopupMenu_mouse_entered() -> void:
	_mouse_over_child = true
	_timer = timeout


func _on_PerItemColorPopupMenu_index_pressed(index) -> void:
	self_modulate = _popup.get_item_color(index)
	set_selected(index)
