class_name Hill
extends Node2D


func _ready() -> void:
	UI.reset_to_hud()


func _on_exit_area_interacted() -> void:
	Core.game.enter_snow()


func _on_inventory_area_2d_interacted() -> void:
	UI.push_inventory()
