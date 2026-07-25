extends Node

@export var start_scene: PackedScene
@export var hud_scene: PackedScene
@export var game_over_scene: PackedScene

@onready var menu_stack: MenuStack = %MenuStack


func reset_to_start_menu() -> void:
	menu_stack.reset_to(start_scene)


func reset_to_hud() -> void:
	menu_stack.reset_to(hud_scene)
