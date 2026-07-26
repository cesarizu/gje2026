class_name Bridge
extends Node2D

static var instance: Bridge


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	UI.reset_to_hud()


func _on_exit_area_interacted() -> void:
	Core.game.enter_pod()


func _on_inventory_area_2d_interacted() -> void:
	UI.push_inventory()
