class_name InventorySlot
extends PanelContainer

signal slot_left_clicked(slot: InventorySlot)
signal slot_right_clicked(slot: InventorySlot)

@export var row: int = 0
@export var column: int = 0

var occupied: bool = false
var item: ItemData = null

@onready var item_icon: TextureRect = %ItemIcon


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			slot_left_clicked.emit(self)

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			slot_right_clicked.emit(self)


func set_item(new_item: ItemData) -> void:
	item = new_item
	occupied = item != null

	if item != null:
		item_icon.texture = item.icon
	else:
		item_icon.texture = null


func clear_item() -> void:
	item = null
	occupied = false
	item_icon.texture = null
