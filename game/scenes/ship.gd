class_name Ship
extends Node2D

const FIRST_NODE := "res://game/data/node_nave.tres"

static var instance: Ship


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	UI.reset_to_hud()
	UI.push_inventory()


func _on_exit_ship_button_pressed() -> void:
	Core.map.start_at(load(FIRST_NODE))
	Core.game.enter_world()
