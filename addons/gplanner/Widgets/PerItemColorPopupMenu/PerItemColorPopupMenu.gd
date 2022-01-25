extends PopupPanel

signal index_pressed(index)

const PIC_Item = preload("res://addons/gplanner/Widgets/PerItemColorPopupMenu/PIC_Item.gd")


onready var _items_container = $MenuItems
var _hovered_index:int

func _gui_input(event: InputEvent) -> void:
	if !event is InputEventMouseButton:
		return
	if event.is_pressed():
		emit_signal("index_pressed", _hovered_index)
		hide()


func add_colored_item(icon:Texture, label:String, color:Color, id:int)->void:
	var index:int = _items_container.get_child_count()
	var item = PIC_Item.new()
	_items_container.add_child(item)
	item.id = id
	item.text = label
	item.icon = icon
	item.color = color
	item.connect("mouse_entered", self, "_on_item_hovered", [index])
	show()
	hide()

func get_item_text(index:int)->String:
	return _items_container.get_child(index).text

func get_item_id(index:int)->int:
	return _items_container.get_child(index).id

func get_item_color(index:int)->Color:
	return _items_container.get_child(index).color

func get_item_index(id:int)->int:
	var i:int = 0
	while(i < _items_container.get_child_count()):
		if _items_container.get_child(i).id == id:
			return i
		i += 1
	return -1

func clear()->void:
	var children = _items_container.get_children()
	for child in children:
		_items_container.remove_child(child)
		child.queue_free()


func _on_item_hovered(index:int)->void:
	_hovered_index = index

func _on_PerItemColorPopupMenu_mouse_exited() -> void:
	pass
#	if !(get_global_rect().has_point(get_global_mouse_position())):
#		hide()


func _on_about_to_show() -> void:
	var par:Control = get_parent()
	rect_global_position = par.rect_global_position
#	rect_global_position.x -= 35
	rect_global_position.y += par.rect_size.y - 5
