class_name InventorySlot
extends PanelContainer

signal slot_left_clicked(slot: InventorySlot)
signal slot_right_clicked(slot: InventorySlot)

@export var row: int = 0
@export var column: int = 0

var occupied: bool = false
var item: ItemData = null
var inventory: Inventory = null
var base_panel_style: StyleBox = null

@onready var item_icon: TextureRect = %ItemIcon


func _ready() -> void:
	base_panel_style = get_theme_stylebox("panel").duplicate()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			slot_left_clicked.emit(self)

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			slot_right_clicked.emit(self)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not occupied or inventory == null:
		return null

	var data := inventory.begin_backpack_drag(self)

	if data.is_empty():
		return null

	var dragged_item: ItemData = data["item"]
	var rotated: bool = data["rotated"]
	var preview_width := dragged_item.height if rotated else dragged_item.width
	var preview_height := dragged_item.width if rotated else dragged_item.height
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(
		preview_width * 64,
		preview_height * 64
	)
	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color = Color(0.05, 0.22, 0.25, 0.82)
	preview_style.border_color = Color(0.25, 0.9, 0.92, 1.0)
	preview_style.set_border_width_all(2)
	preview_style.set_corner_radius_all(4)
	preview.add_theme_stylebox_override("panel", preview_style)
	preview.modulate = Color(1, 1, 1, 0.85)

	var preview_icon_root := Control.new()
	preview_icon_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_icon_root.custom_minimum_size = preview.custom_minimum_size
	preview.add_child(preview_icon_root)

	var preview_icon := TextureRect.new()
	preview_icon.texture = dragged_item.icon
	preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_icon_root.add_child(preview_icon)
	_fit_rotated_icon(
		preview_icon,
		preview_icon_root,
		rotated,
		preview.custom_minimum_size
	)
	data["preview"] = preview
	data["preview_icon"] = preview_icon
	data["preview_icon_root"] = preview_icon_root
	set_drag_preview(preview)

	return data


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if inventory == null:
		return false

	return inventory.can_drop_data_at(self, data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if inventory != null:
		inventory.drop_data_at(self, data)


func _notification(what: int) -> void:
	if (
		what == NOTIFICATION_DRAG_END
		and inventory != null
		and not get_viewport().gui_is_drag_successful()
	):
		inventory.cancel_active_drag()


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


func set_drop_highlight(state: int) -> void:
	if state == 0:
		z_index = 0
		if base_panel_style != null:
			add_theme_stylebox_override("panel", base_panel_style)
		return

	z_index = 10
	var style := StyleBoxFlat.new()
	style.bg_color = (
		Color(0.08, 0.35, 0.24, 0.9)
		if state > 0
		else Color(0.42, 0.09, 0.09, 0.9)
	)
	style.border_color = (
		Color(0.25, 1.0, 0.6, 1.0)
		if state > 0
		else Color(1.0, 0.25, 0.25, 1.0)
	)
	style.set_border_width_all(3)
	style.set_corner_radius_all(3)
	add_theme_stylebox_override("panel", style)


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
