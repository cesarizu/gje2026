class_name Hill
extends Node2D

@onready var hole_sprite_2d: Sprite2D = %HoleSprite2D
@onready var hole: StaticBody2D = %Hole

var _hole_hit := false
var _mosquito_hit := false


func _ready() -> void:
	Dialogic.VAR.player_can_move = true
	UI.reset_to_hud()
	await UI.fade_in()


func _on_exit_area_interacted() -> void:
	Core.game.enter_snow()


func _on_inventory_area_2d_interacted() -> void:
	UI.push_inventory()


func _on_hole_area_2d_body_entered(body: Node2D) -> void:
	if body is not Player:
		return

	if RunInventory.has_item(&"thermal_blanket") or RunInventory.has_item(&"rope"):
		hole_sprite_2d.show()
		hole.queue_free()
	elif not _hole_hit:
		Player.instance.hit()
		_hole_hit = true


func _on_mosquito_area_2d_body_entered(body: Node2D) -> void:
	if body is not Player:
		return

	if RunInventory.has_item(&"repellent"):
		pass
	elif not _mosquito_hit:
		Player.instance.hit()
		_mosquito_hit = true
