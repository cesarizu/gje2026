class_name MultiplayerContext
extends Node

const GROUP_NAME := &"MultiplayerContexts"
const META_NAME := &"MultiplayerContext"

## Sentinel returned when a node has no MultiplayerContext ancestor. It resolves to AUTO:
## follow the global last-used device (any controller/keyboard/mouse works), ignoring any
## per-player pins. Distinct from explicit player_index 0, which is a real multiplayer slot.
const AUTO_PLAYER_INDEX := -1

@export var player_index: int = 0:
	set(value):
		if player_index == value:
			return
		player_index = value
		# Re-emit through InputManager so descendant shortcut indicators refresh for the new
		# player, even when no input-device change accompanies the reassignment.
		if is_inside_tree() and not Engine.is_editor_hint():
			InputManager.input_method_changed.emit(InputManager.get_input_method_for(value), value)


## Returns the player_index of the nearest MultiplayerContext ancestor, or AUTO_PLAYER_INDEX
## (-1) if none found.
static func get_player_index(node: Node) -> int:
	var current := node.get_parent()
	while current:
		if current.is_in_group(GROUP_NAME) and current.has_meta(META_NAME):
			return (current.get_meta(META_NAME) as MultiplayerContext).player_index
		current = current.get_parent()
	return AUTO_PLAYER_INDEX


func _enter_tree() -> void:
	var parent := get_parent()
	parent.add_to_group(GROUP_NAME)
	parent.set_meta(META_NAME, self)


func _exit_tree() -> void:
	var parent := get_parent()
	parent.remove_from_group(GROUP_NAME)
	parent.remove_meta(META_NAME)
