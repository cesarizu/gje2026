class_name Bridge
extends Node2D

var _hole_hit := false

func _ready() -> void:
	UI.reset_to_hud()
	await UI.fade_in()


func _on_exit_area_interacted() -> void:
	Core.game.enter_pod()


func _on_inventory_area_2d_interacted() -> void:
	UI.push_inventory()


func _on_hole_area_2d_body_entered(body: Node2D) -> void:
	if body is not Player:
		return
		
	if RunInventory.has_item(&"flashlight") or RunInventory.has_item(&"multitool"):
		pass
	elif not _hole_hit:
		Player.instance.hit()
		_hole_hit = true
	
