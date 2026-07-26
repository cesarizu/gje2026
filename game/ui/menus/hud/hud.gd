extends Menu

@onready var flashlight_control: HBoxContainer = %FlashlightControl
@onready var flashlight_button: TextureButton = %FlashligthButton

var player: Node = null


func _ready() -> void:
	super()

	if not RunInventory.inventory_changed.is_connected(update_inventory_hud):
		RunInventory.inventory_changed.connect(update_inventory_hud)

	if flashlight_button != null:
		flashlight_button.pressed.connect(_on_flashlight_pressed)

	player = get_tree().get_first_node_in_group("player")

	update_inventory_hud()


func update_inventory_hud() -> void:
	var has_flashlight := RunInventory.has_item("flashlight")

	flashlight_control.visible = has_flashlight

	if flashlight_button != null:
		flashlight_button.disabled = not has_flashlight

		if not has_flashlight:
			flashlight_button.button_pressed = false

	if not has_flashlight:
		if player != null and player.has_method("turn_off_flashlight"):
			player.turn_off_flashlight()


func _on_flashlight_pressed() -> void:
	if not RunInventory.has_item("flashlight"):
		return

	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if player == null:
		print("No se encontró al jugador.")
		return

	if not player.has_method("toggle_flashlight"):
		print("El jugador no tiene toggle_flashlight().")
		return

	player.toggle_flashlight()

	if "flashlight_on" in player:
		flashlight_button.button_pressed = player.flashlight_on
