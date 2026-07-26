extends Node

signal inventory_changed

var backpack_items: Array[Dictionary] = []


func clear_backpack() -> void:
	backpack_items.clear()


func add_backpack_item(
	item: ItemData,
	row: int,
	column: int,
	rotated: bool,
	current_charges: int = -1
) -> void:

	if current_charges < 0:
		current_charges = item.max_charges

	backpack_items.append({
		"item": item,
		"row": row,
		"column": column,
		"rotated": rotated,
		"current_charges": current_charges
	})


func has_item(item_id: StringName) -> bool:
	for inventory_item in backpack_items:
		var item: ItemData = inventory_item["item"]

		if item.id == item_id:
			return true

	return false


func get_item(item_id: StringName) -> Dictionary:
	for inventory_item in backpack_items:
		var item: ItemData = inventory_item["item"]

		if item.id == item_id:
			return inventory_item

	return {}


func get_backpack_items() -> Array[Dictionary]:
	return backpack_items


func get_current_charges(item_id: StringName) -> int:
	for inventory_item in backpack_items:
		var item: ItemData = inventory_item["item"]

		if item.id == item_id:
			return inventory_item["current_charges"]

	return 0


func consume_charge(
	item_id: StringName,
	amount: int = 1
) -> bool:

	for inventory_item in backpack_items:
		var item: ItemData = inventory_item["item"]

		if item.id != item_id:
			continue

		var current_charges: int = inventory_item["current_charges"]

		if current_charges < amount:
			return false

		inventory_item["current_charges"] = current_charges - amount

		inventory_changed.emit()

		return true

	return false


func get_used_slots() -> int:
	var total := 0

	for inventory_item in backpack_items:
		var item: ItemData = inventory_item["item"]
		var rotated: bool = inventory_item["rotated"]

		var item_width := item.width
		var item_height := item.height

		if rotated:
			item_width = item.height
			item_height = item.width

		total += item_width * item_height

	return total


func get_free_slots() -> int:
	return 9 - get_used_slots()


func notify_inventory_changed() -> void:
	inventory_changed.emit()
