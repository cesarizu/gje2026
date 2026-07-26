extends PanelContainer
class_name ItemCard

signal item_selected(item_data: ItemData)

@export var item_data: ItemData:
	set(value):
		item_data = value

		if is_node_ready():
			_sync_inventory_state()
			update_ui()

var current_charges: int = 0
var rotated: bool = false

@onready var item_icon: TextureRect = %ItemIcon
@onready var name_label: Label = %NameLabel
@onready var charges_label: Label = %ChargesLabel


func _ready() -> void:
	if not RunInventory.inventory_changed.is_connected(_on_inventory_changed):
		RunInventory.inventory_changed.connect(_on_inventory_changed)
	var icon_root := item_icon.get_parent()
	if not icon_root.resized.is_connected(_update_item_icon_transform):
		icon_root.resized.connect(_update_item_icon_transform)

	_sync_inventory_state()
	_update_item_icon_transform()
	update_ui()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if item_data != null:
				item_selected.emit(item_data)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_data == null:
		return null

	var preview_width := item_data.height if rotated else item_data.width
	var preview_height := item_data.width if rotated else item_data.height
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
	preview_icon.texture = item_data.icon
	preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_icon.rotation = PI / 2.0 if rotated else 0.0
	preview_icon_root.add_child(preview_icon)
	_fit_rotated_icon(
		preview_icon,
		preview_icon_root,
		rotated,
		preview.custom_minimum_size
	)
	set_drag_preview(preview)

	return {
		"source": "manifest",
		"source_card": self,
		"item": item_data,
		"rotated": rotated,
		"current_charges": item_data.max_charges,
		"preview": preview,
		"preview_icon": preview_icon,
		"preview_icon_root": preview_icon_root
	}


func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAG_END:
		return

	var current_parent := get_parent()

	while current_parent != null:
		if current_parent is Inventory:
			current_parent.clear_drop_highlights()
			return

		current_parent = current_parent.get_parent()


func update_ui() -> void:
	if item_data == null:
		clear_ui()
		return

	name_label.text = item_data.item_name
	item_icon.texture = item_data.icon
	charges_label.visible = item_data.uses_charges

	if item_data.uses_charges:
		charges_label.text = "%d/%d" % [
			current_charges,
			item_data.max_charges
		]
	else:
		charges_label.text = ""

	tooltip_text = _build_tooltip()


func clear_ui() -> void:
	name_label.text = ""
	charges_label.text = ""
	charges_label.visible = false
	item_icon.texture = null
	tooltip_text = ""


func set_current_charges(value: int) -> void:
	current_charges = value

	if item_data != null and item_data.uses_charges:
		current_charges = clampi(value, 0, item_data.max_charges)

	if is_node_ready():
		update_ui()


func set_rotated(value: bool) -> void:
	rotated = value
	_update_item_icon_transform()

	if is_node_ready():
		tooltip_text = _build_tooltip()


func _update_item_icon_transform() -> void:
	if item_icon == null:
		return

	var icon_root := item_icon.get_parent() as Control
	_fit_rotated_icon(item_icon, icon_root, rotated, icon_root.size)


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


func _on_inventory_changed() -> void:
	_sync_inventory_state()
	update_ui()


func _sync_inventory_state() -> void:
	if item_data == null:
		current_charges = 0
		return

	current_charges = item_data.max_charges

	if item_data.id != &"" and RunInventory.has_item(item_data.id):
		current_charges = RunInventory.get_current_charges(item_data.id)


func _build_tooltip() -> String:
	if item_data == null:
		return ""

	var lines: Array[String] = [item_data.item_name.to_upper()]

	if not item_data.description.is_empty():
		lines.append("")
		lines.append(item_data.description)

	if not item_data.use_text.is_empty():
		lines.append("")
		lines.append("Uso: %s" % item_data.use_text)

	if item_data.uses_charges:
		lines.append("Cargas: %d/%d" % [
			current_charges,
			item_data.max_charges
		])

	var display_width := item_data.height if rotated else item_data.width
	var display_height := item_data.width if rotated else item_data.height
	lines.append("Tamaño: %d x %d" % [display_width, display_height])

	return "\n".join(lines)


func _make_custom_tooltip(for_text: String) -> Object:
	var panel := PanelContainer.new()
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.025, 0.035, 0.045, 0.98)
	background.border_color = Color(0.18, 0.45, 0.5, 1.0)
	background.set_border_width_all(1)
	background.set_corner_radius_all(4)
	background.content_margin_left = 12
	background.content_margin_top = 10
	background.content_margin_right = 12
	background.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", background)

	var label := Label.new()
	label.custom_minimum_size.x = 240
	label.text = for_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.94, 0.97, 0.98, 1.0))
	panel.add_child(label)

	return panel
