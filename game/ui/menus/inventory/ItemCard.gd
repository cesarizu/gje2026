extends PanelContainer
class_name ItemCard

signal item_selected(item_data: ItemData)

@export var item_data: ItemData:
	set(value):
		item_data = value

		if is_node_ready():
			update_ui()


@onready var item_icon: TextureRect = $ContentMargin/Content/ItemIcon
@onready var name_label: Label = $ContentMargin/Content/ItemInfo/NameLabel
@onready var stats_label: Label = $ContentMargin/Content/ItemInfo/StatsLabel
@onready var description_label: Label = $ContentMargin/Content/ItemInfo/DescriptionLabel



func _ready() -> void:
	update_ui()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if item_data != null:
				item_selected.emit(item_data)


func update_ui() -> void:
	if item_data == null:
		clear_ui()
		return

	name_label.text = item_data.item_name

	var charges_text := "carga" if item_data.max_charges == 1 else "cargas"

	stats_label.text = "%dx%d · %d %s" % [
		item_data.width,
		item_data.height,
		item_data.max_charges,
		charges_text
	]

	description_label.text = item_data.description
	item_icon.texture = item_data.icon


func clear_ui() -> void:
	name_label.text = ""
	stats_label.text = ""
	description_label.text = ""
	item_icon.texture = null
