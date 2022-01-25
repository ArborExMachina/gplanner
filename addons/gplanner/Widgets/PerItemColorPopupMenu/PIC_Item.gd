extends HBoxContainer


var id:int
var text:String setget set_text,get_text
var icon:Texture setget set_icon
var color:Color setget set_color,get_colr

var _tex_rec:TextureRect
var _label:Label

func _init():
	_tex_rec = TextureRect.new()
	_label = Label.new()
	add_child(_tex_rec)
	add_child(_label)

func set_text(value:String)->void:
	_label.text = value

func get_text()->String:
	return _label.text

func set_icon(value:Texture)->void:
	_tex_rec.texture = value

func set_color(value:Color)->void:
	color = value
	modulate = value

func get_colr()->Color:
	return color
