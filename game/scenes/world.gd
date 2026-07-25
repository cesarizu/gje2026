class_name World
extends Node2D

static var instance: World

@onready var node_container: Node2D = $NodeContainer
@onready var player: Player = $Player


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	UI.reset_to_hud()
	_load_current_node()


func _load_current_node() -> void:
	for child in node_container.get_children():
		child.queue_free()

	var node_data: WorldNodeData = Core.map.current_node
	if node_data == null or node_data.scene_path.is_empty():
		return
	var node_scene: PackedScene = load(node_data.scene_path)
	var node_instance: WorldNode = node_scene.instantiate()
	node_instance.node_data = node_data
	node_container.add_child(node_instance)
