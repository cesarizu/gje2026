class_name Ship
extends Node2D

static var instance: Ship


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	UI.reset_to_hud()
	UI.push_inventory()


func _on_exit_ship_button_pressed() -> void:
	Core.game.enter_world()
