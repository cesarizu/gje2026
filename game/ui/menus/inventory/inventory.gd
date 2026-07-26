class_name Inventory
extends Menu

const INVENTORY_SLOT = preload(
	"res://game/ui/menus/inventory/InventorySlot.tscn"
)

@onready var backpack_grid: GridContainer = %BackpackGrid
@onready var items_container: GridContainer = %ItemsContainer
@onready var exit_button: Button = %ExitButton

var selected_item: ItemData = null
var selected_item_rotated: bool = false
var selected_item_card: ItemCard = null

var slots: Array[Array] = []
var placed_items: Array[Dictionary] = []


func _ready() -> void:
	super()

	create_backpack_grid()
	connect_item_cards()
	load_inventory_state()

	exit_button.pressed.connect(_on_exit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate_item"):
		rotate_selected_item()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		close_inventory()
		get_viewport().set_input_as_handled()


func create_backpack_grid() -> void:
	slots.clear()

	for child in backpack_grid.get_children():
		child.queue_free()

	for row in range(3):
		var row_slots: Array[InventorySlot] = []

		for column in range(3):
			var slot: InventorySlot = INVENTORY_SLOT.instantiate()

			slot.row = row
			slot.column = column

			slot.slot_left_clicked.connect(_on_slot_clicked)
			slot.slot_right_clicked.connect(_on_slot_right_clicked)

			backpack_grid.add_child(slot)
			row_slots.append(slot)

		slots.append(row_slots)


func connect_item_cards() -> void:
	for child in items_container.get_children():
		if child is ItemCard:
			if not child.item_selected.is_connected(_on_item_selected):
				child.item_selected.connect(_on_item_selected.bind(child))


func _on_item_selected(
	item_data: ItemData,
	item_card: ItemCard
) -> void:
	if selected_item_card != null:
		selected_item_card.set_rotated(false)

	selected_item = item_data
	selected_item_rotated = false
	selected_item_card = item_card
	selected_item_card.set_rotated(false)

	print(
		"Objeto seleccionado: ",
		item_data.item_name,
		" | Tamaño: ",
		get_item_width(item_data),
		"x",
		get_item_height(item_data)
	)


func _on_slot_clicked(slot: InventorySlot) -> void:
	if selected_item == null:
		return

	if not can_place_item(
		selected_item,
		slot.row,
		slot.column
	):
		print(
			"No se puede colocar ",
			selected_item.item_name,
			" en [",
			slot.row,
			",",
			slot.column,
			"]"
		)

		return

	place_item(
		selected_item,
		slot.row,
		slot.column
	)

	print(
		"Colocado: ",
		selected_item.item_name,
		" en [",
		slot.row,
		",",
		slot.column,
		"]",
		" | Rotado: ",
		selected_item_rotated
	)

	selected_item = null
	selected_item_rotated = false
	selected_item_card = null


func _on_slot_right_clicked(slot: InventorySlot) -> void:
	if not slot.occupied:
		return

	var placed_index := find_placed_item_at_slot(
		slot.row,
		slot.column
	)

	if placed_index == -1:
		return

	remove_placed_item(placed_index)


func rotate_selected_item() -> void:
	if selected_item == null:
		return

	if not selected_item.can_rotate:
		print(
			selected_item.item_name,
			" no puede rotarse."
		)
		return

	selected_item_rotated = not selected_item_rotated

	if selected_item_card != null:
		selected_item_card.set_rotated(selected_item_rotated)

	print(
		"Rotación: ",
		selected_item.item_name,
		" → ",
		get_item_width(selected_item),
		"x",
		get_item_height(selected_item)
	)


func get_item_width(item: ItemData) -> int:
	if selected_item_rotated:
		return item.height

	return item.width


func get_item_height(item: ItemData) -> int:
	if selected_item_rotated:
		return item.width

	return item.height


func can_place_item(
	item: ItemData,
	start_row: int,
	start_column: int
) -> bool:

	var item_width := get_item_width(item)
	var item_height := get_item_height(item)

	var end_row := start_row + item_height
	var end_column := start_column + item_width

	if end_row > 3 or end_column > 3:
		return false

	for row in range(start_row, end_row):
		for column in range(start_column, end_column):
			if slots[row][column].occupied:
				return false

	return true


func place_item(
	item: ItemData,
	start_row: int,
	start_column: int
) -> void:

	var item_width := get_item_width(item)
	var item_height := get_item_height(item)

	for row in range(
		start_row,
		start_row + item_height
	):
		for column in range(
			start_column,
			start_column + item_width
		):
			slots[row][column].set_item(item)

	placed_items.append({
		"item": item,
		"row": start_row,
		"column": start_column,
		"rotated": selected_item_rotated,
		"current_charges": item.max_charges
	})


func find_placed_item_at_slot(
	target_row: int,
	target_column: int
) -> int:

	for index in range(placed_items.size()):
		var placed_item: Dictionary = placed_items[index]

		var item: ItemData = placed_item["item"]
		var start_row: int = placed_item["row"]
		var start_column: int = placed_item["column"]
		var rotated: bool = placed_item["rotated"]

		var item_width := item.width
		var item_height := item.height

		if rotated:
			item_width = item.height
			item_height = item.width

		var end_row := start_row + item_height
		var end_column := start_column + item_width

		if (
			target_row >= start_row
			and target_row < end_row
			and target_column >= start_column
			and target_column < end_column
		):
			return index

	return -1


func remove_placed_item(index: int) -> void:
	if index < 0 or index >= placed_items.size():
		return

	var placed_item: Dictionary = placed_items[index]

	var item: ItemData = placed_item["item"]
	var start_row: int = placed_item["row"]
	var start_column: int = placed_item["column"]
	var rotated: bool = placed_item["rotated"]

	var item_width := item.width
	var item_height := item.height

	if rotated:
		item_width = item.height
		item_height = item.width

	for row in range(
		start_row,
		start_row + item_height
	):
		for column in range(
			start_column,
			start_column + item_width
		):
			slots[row][column].clear_item()

	placed_items.remove_at(index)

	print(
		"Objeto retirado: ",
		item.item_name
	)


func load_inventory_state() -> void:
	placed_items.clear()

	for stored_item in RunInventory.backpack_items:
		var item: ItemData = stored_item["item"]
		var row: int = stored_item["row"]
		var column: int = stored_item["column"]
		var rotated: bool = stored_item["rotated"]
		var current_charges: int = stored_item["current_charges"]

		placed_items.append({
			"item": item,
			"row": row,
			"column": column,
			"rotated": rotated,
			"current_charges": current_charges
		})

		place_stored_item(
			item,
			row,
			column,
			rotated
		)


func place_stored_item(
	item: ItemData,
	start_row: int,
	start_column: int,
	rotated: bool
) -> void:

	var item_width := item.width
	var item_height := item.height

	if rotated:
		item_width = item.height
		item_height = item.width

	for row in range(
		start_row,
		start_row + item_height
	):
		for column in range(
			start_column,
			start_column + item_width
		):
			slots[row][column].set_item(item)


func save_inventory_state() -> void:
	RunInventory.clear_backpack()

	for placed_item in placed_items:
		RunInventory.add_backpack_item(
			placed_item["item"],
			placed_item["row"],
			placed_item["column"],
			placed_item["rotated"],
			placed_item["current_charges"]
		)

	RunInventory.notify_inventory_changed()

	print(
		"Mochila guardada. Objetos: ",
		RunInventory.backpack_items.size()
	)


func _on_exit_pressed() -> void:
	close_inventory()


func close_inventory() -> void:
	save_inventory_state()

	queue_free()
