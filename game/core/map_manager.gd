class_name MapManager
extends Node

signal node_changed(new_node: WorldNodeData)

var current_node: WorldNodeData = null


func start_at(first_node: WorldNodeData) -> void:
	current_node = first_node
	node_changed.emit(current_node)


## Avanza al next_node del node actual. No hay forma de retroceder:
## solo se guarda el node actual, nunca un historial.
func advance() -> void:
	if current_node == null or not current_node.has_next():
		return
	current_node = current_node.next_node
	node_changed.emit(current_node)


func has_next() -> bool:
	return current_node != null and current_node.has_next()
