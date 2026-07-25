extends Node

@export var start_scene: PackedScene
@export var hud_scene: PackedScene
@export var game_over_scene: PackedScene
@export var inventory_scene: PackedScene

@onready var menu_stack: MenuStack = %MenuStack


func _ready() -> void:
	MenuStack.main_stack = menu_stack


func reset_to_start_menu() -> void:
	menu_stack.reset_to(start_scene)


func reset_to_hud() -> void:
	menu_stack.reset_to(hud_scene)


func push_game_over() -> void:
	menu_stack.push(game_over_scene)


func push_inventory() -> void:
	menu_stack.push(inventory_scene)
