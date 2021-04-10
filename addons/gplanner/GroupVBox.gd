extends VBoxContainer
tool

signal item_clicked(group_name, item_name)

export var group_name := "Group"
export var items := []

onready var member_box = $MemberArea

func setup(group_name:String, items:Array)->void:
	self.group_name = group_name
	self.items = items
	

func _ready() -> void:
	$GroupButton.text = group_name
	for item in items:
		var item_button := Button.new()
		item_button.text = item
		item_button.connect("button_down", self, "item_button_clicked", [item])
		$MemberArea/VBoxContainer.add_child(item_button)

func expand()->void:
	add_child(member_box)


func shrink()->void:
	remove_child(member_box)


func item_button_clicked(item)->void:
	emit_signal("item_clicked",group_name, item)


func _on_GroupButton_toggled(button_pressed: bool) -> void:
	if(button_pressed):
		expand()
	else:
		shrink()
