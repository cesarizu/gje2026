class_name Ship
extends Node2D
var alert_showed = false

func _ready() -> void:
	UI.reset_to_hud()
	Dialogic.start("player_dialog")


func _on_exit_area_interacted() -> void:
	if !alert_showed:
		Dialogic.start("ship_exit")
		alert_showed = true
	else:
		Dialogic.end_timeline()
		Core.game.enter_hill()


func _on_inventory_area_2d_interacted() -> void:
	UI.push_inventory()
