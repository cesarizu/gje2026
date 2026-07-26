class_name Snow
extends Node2D

@onready var ice_sprite_2d: Sprite2D = %IceSprite2D
@onready var ice: StaticBody2D = %Ice

var _ice_hit := false

func _ready() -> void:
	UI.reset_to_hud()
	await UI.fade_in()


func _on_exit_area_interacted() -> void:
	Core.game.enter_bridge()


func _on_inventory_area_2d_interacted() -> void:
	UI.push_inventory()
