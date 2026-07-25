class_name WorldNode
extends Node2D

@export var node_data: WorldNodeData


func _on_exit_zone_body_entered(body: Node2D) -> void:
	if body != Player.instance:
		return
	if not Core.map.has_next():
		return
	Core.map.advance()
	Core.game.enter_world()
