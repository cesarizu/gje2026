extends PanelContainer
class_name InventorySlot

@export var row: int = 0
@export var column: int = 0

var occupied: bool = false
var item: ItemData = null

@onready var item_icon: TextureRect = $ContentMargin/ContentCenter/ItemIcon


func set_item(new_item: ItemData) -> void:
	item = new_item
	occupied = item != null

	if item != null and item.icon != null:
		item_icon.texture = item.icon
	else:
		item_icon.texture = null


func clear_item() -> void:
	item = null
	occupied = false
	item_icon.texture = null
