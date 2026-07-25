class_name Inventory
extends Menu

const INVENTORY_SLOT = preload(
	"res://game/ui/menus/inventory/InventorySlot.tscn"
)

@onready var backpack_grid: GridContainer = %BackpackGrid
@onready var items_container: GridContainer = %ItemsContainer

var selected_item: ItemData = null

var slots: Array[Array] = []


func _ready() -> void:
	super()

	create_backpack_grid()
	connect_item_cards()


func create_backpack_grid() -> void:
	slots.clear()

	for row in range(3):
		var row_slots: Array[InventorySlot] = []

		for column in range(3):
			var slot: InventorySlot = INVENTORY_SLOT.instantiate()

			slot.row = row
			slot.column = column
			slot.slot_clicked.connect(_on_slot_clicked)

			backpack_grid.add_child(slot)
			row_slots.append(slot)

		slots.append(row_slots)


func connect_item_cards() -> void:
	for child in items_container.get_children():
		if child is ItemCard:
			child.item_selected.connect(_on_item_selected)


func _on_item_selected(item_data: ItemData) -> void:
	selected_item = item_data

	print(
		"Objeto seleccionado: ",
		item_data.item_name
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
		"]"
	)

	selected_item = null


func can_place_item(
	item: ItemData,
	start_row: int,
	start_column: int
) -> bool:

	var end_row := start_row + item.height
	var end_column := start_column + item.width

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

	for row in range(
		start_row,
		start_row + item.height
	):
		for column in range(
			start_column,
			start_column + item.width
		):
			slots[row][column].set_item(item)
