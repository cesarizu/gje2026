class_name Inventory
extends Menu

const INVENTORY_SLOT = preload(
	"res://game/ui/menus/inventory/InventorySlot.tscn"
)

@onready var backpack_grid: GridContainer = %BackpackGrid
@onready var placed_items_layer: Control = %PlacedItemsLayer
@onready var items_container: GridContainer = %ItemsContainer
@onready var exit_button: Button = %ExitButton

var selected_item: ItemData = null
var selected_item_rotated: bool = false
var selected_item_card: ItemCard = null

var slots: Array[Array] = []
var placed_items: Array[Dictionary] = []
var active_moved_item: Dictionary = {}
var hovered_drop_slot: InventorySlot = null


func _ready() -> void:
	super()

	create_backpack_grid()
	connect_item_cards()
	load_inventory_state()
	if not placed_items_layer.resized.is_connected(
		_on_placed_items_layer_resized
	):
		placed_items_layer.resized.connect(
			_on_placed_items_layer_resized
		)
	call_deferred("_rebuild_placed_item_visuals")

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
			slot.inventory = self

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

	_clear_selection()


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
	if get_viewport().gui_is_dragging():
		var drag_value: Variant = get_viewport().gui_get_drag_data()

		if drag_value is Dictionary:
			_rotate_drag_data(drag_value)

		return

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
	start_column: int,
	current_charges: int = -1
) -> void:
	if current_charges < 0:
		current_charges = item.max_charges

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
		"current_charges": current_charges
	})

	_rebuild_placed_item_visuals()
	_refresh_manifest_cards()


func begin_backpack_drag(slot: InventorySlot) -> Dictionary:
	if not active_moved_item.is_empty():
		return {}

	var placed_index := find_placed_item_at_slot(slot.row, slot.column)

	if placed_index == -1:
		return {}

	active_moved_item = placed_items[placed_index].duplicate()
	placed_items.remove_at(placed_index)
	_clear_item_cells(active_moved_item)
	_rebuild_placed_item_visuals()

	return {
		"source": "backpack",
		"item": active_moved_item["item"],
		"rotated": active_moved_item["rotated"],
		"current_charges": active_moved_item["current_charges"]
	}


func can_drop_data_at(slot: InventorySlot, data: Variant) -> bool:
	clear_drop_highlights()
	hovered_drop_slot = slot

	if not (data is Dictionary):
		return false

	if (
		not data.has("item")
		or not data.has("rotated")
		or not data.has("source")
	):
		return false

	var drag_data: Dictionary = data
	var item: ItemData = drag_data["item"]
	var rotated: bool = drag_data["rotated"]
	selected_item_rotated = rotated

	var duplicate_manifest_item: bool = (
		drag_data["source"] == "manifest"
		and _has_placed_item(item.id)
	)
	var valid: bool = (
		not duplicate_manifest_item
		and can_place_item(item, slot.row, slot.column)
	)

	_highlight_item_area(
		item,
		slot.row,
		slot.column,
		rotated,
		valid
	)

	return valid


func drop_data_at(slot: InventorySlot, data: Variant) -> void:
	if not can_drop_data_at(slot, data):
		return

	var drag_data: Dictionary = data
	var item: ItemData = drag_data["item"]
	selected_item_rotated = drag_data["rotated"]
	place_item(
		item,
		slot.row,
		slot.column,
		drag_data.get("current_charges", item.max_charges)
	)

	active_moved_item.clear()
	clear_drop_highlights()
	hovered_drop_slot = null
	_clear_selection()


func cancel_active_drag() -> void:
	clear_drop_highlights()
	hovered_drop_slot = null

	if active_moved_item.is_empty():
		return

	var item: ItemData = active_moved_item["item"]
	selected_item_rotated = active_moved_item["rotated"]
	place_item(
		item,
		active_moved_item["row"],
		active_moved_item["column"],
		active_moved_item["current_charges"]
	)
	active_moved_item.clear()
	_clear_selection()


func clear_drop_highlights() -> void:
	for row_slots in slots:
		for slot in row_slots:
			slot.set_drop_highlight(0)


func _rotate_drag_data(drag_data: Dictionary) -> void:
	if not drag_data.has("item") or not drag_data.has("rotated"):
		return

	var item: ItemData = drag_data["item"]

	if not item.can_rotate:
		return

	var rotated: bool = not bool(drag_data["rotated"])
	drag_data["rotated"] = rotated
	selected_item_rotated = rotated

	if drag_data.get("source_card") is ItemCard:
		var source_card: ItemCard = drag_data["source_card"]
		source_card.set_rotated(rotated)

	if drag_data.get("preview") is Control:
		var preview: Control = drag_data["preview"]
		var preview_width := item.height if rotated else item.width
		var preview_height := item.width if rotated else item.height
		var preview_size := Vector2(
			preview_width * 64,
			preview_height * 64
		)
		preview.custom_minimum_size = preview_size
		preview.size = preview_size

		if drag_data.get("preview_icon") is TextureRect:
			var preview_icon: TextureRect = drag_data["preview_icon"]
			var preview_icon_root: Control = drag_data.get(
				"preview_icon_root",
				preview_icon.get_parent()
			)
			preview_icon_root.custom_minimum_size = preview_size
			_fit_rotated_icon(
				preview_icon,
				preview_icon_root,
				rotated,
				preview_size
			)

	if hovered_drop_slot != null:
		can_drop_data_at(hovered_drop_slot, drag_data)
	else:
		clear_drop_highlights()


func _highlight_item_area(
	item: ItemData,
	start_row: int,
	start_column: int,
	rotated: bool,
	valid: bool
) -> void:
	var item_width := item.height if rotated else item.width
	var item_height := item.width if rotated else item.height
	var state := 1 if valid else -1

	for row in range(start_row, mini(start_row + item_height, 3)):
		for column in range(start_column, mini(start_column + item_width, 3)):
			slots[row][column].set_drop_highlight(state)


func _clear_item_cells(placed_item: Dictionary) -> void:
	var item: ItemData = placed_item["item"]
	var item_width := (
		item.height if placed_item["rotated"] else item.width
	)
	var item_height := (
		item.width if placed_item["rotated"] else item.height
	)

	for row in range(
		placed_item["row"],
		placed_item["row"] + item_height
	):
		for column in range(
			placed_item["column"],
			placed_item["column"] + item_width
		):
			slots[row][column].clear_item()


func _has_placed_item(item_id: StringName) -> bool:
	for placed_item in placed_items:
		var placed_data: ItemData = placed_item["item"]

		if placed_data.id == item_id:
			return true

	return false


func _refresh_manifest_cards() -> void:
	for child in items_container.get_children():
		if child is ItemCard and child.item_data != null:
			child.visible = not _has_placed_item(child.item_data.id)


func _rebuild_placed_item_visuals() -> void:
	for child in placed_items_layer.get_children():
		placed_items_layer.remove_child(child)
		child.queue_free()

	for placed_item in placed_items:
		var item: ItemData = placed_item["item"]
		var rotated: bool = placed_item["rotated"]
		var item_width := item.height if rotated else item.width
		var item_height := item.width if rotated else item.height
		var start_row: int = placed_item["row"]
		var start_column: int = placed_item["column"]
		var end_row := start_row + item_height - 1
		var end_column := start_column + item_width - 1
		var start_slot: InventorySlot = slots[start_row][start_column]
		var end_slot: InventorySlot = slots[end_row][end_column]
		var visual := _create_placed_item_visual(item, rotated)
		visual.position = start_slot.position
		visual.size = (
			end_slot.position
			+ end_slot.size
			- start_slot.position
		)
		placed_items_layer.add_child(visual)


func _on_placed_items_layer_resized() -> void:
	call_deferred("_rebuild_placed_item_visuals")


func _create_placed_item_visual(
	item: ItemData,
	rotated: bool
) -> Control:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)

	var icon_root := Control.new()
	icon_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_root)

	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_root.resized.connect(
		func() -> void:
			_fit_rotated_icon(
				icon,
				icon_root,
				rotated,
				icon_root.size
			)
	)
	icon_root.add_child(icon)
	_fit_rotated_icon(icon, icon_root, rotated, icon_root.size)

	return panel


func _fit_rotated_icon(
	icon: TextureRect,
	icon_root: Control,
	is_rotated: bool,
	available_size: Vector2
) -> void:
	var icon_size := (
		Vector2(available_size.y, available_size.x)
		if is_rotated
		else available_size
	)
	icon.size = icon_size
	icon.position = (available_size - icon_size) / 2.0
	icon.pivot_offset = icon_size / 2.0
	icon.rotation = PI / 2.0 if is_rotated else 0.0


func _clear_selection() -> void:
	if selected_item_card != null:
		selected_item_card.set_rotated(false)

	selected_item = null
	selected_item_rotated = false
	selected_item_card = null


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
	_refresh_manifest_cards()
	_rebuild_placed_item_visuals()

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

	_refresh_manifest_cards()
	_rebuild_placed_item_visuals()


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
	cancel_active_drag()
	save_inventory_state()

	queue_free()
