extends Node

@export var start_scene: PackedScene
@export var hud_scene: PackedScene
@export var game_over_scene: PackedScene
@export var inventory_scene: PackedScene

@onready var menu_stack: MenuStack = %MenuStack


func _ready() -> void:
	MenuStack.main_stack = menu_stack


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("inventory"):
		return

	var open_inventory := menu_stack.get_menu(Inventory)

	if (
		open_inventory != null
		and menu_stack.top == open_inventory
		and open_inventory.read_only
	):
		open_inventory.close_inventory()
	elif menu_stack.top != null and menu_stack.top.name == "Hud":
		push_backpack()

	get_viewport().set_input_as_handled()


func reset_to_start_menu() -> void:
	menu_stack.reset_to(start_scene)


func reset_to_hud() -> void:
	menu_stack.reset_to(hud_scene)


func push_game_over() -> void:
	menu_stack.push(game_over_scene)


func push_inventory() -> void:
	menu_stack.push(inventory_scene, false)


func push_backpack() -> void:
	menu_stack.push(inventory_scene, true)
