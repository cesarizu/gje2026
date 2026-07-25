class_name GameManager
extends Node

signal state_changed(new_state: GameState)

enum GameState {
	NONE,
	NOT_STARTED,
	IN_SHIP,
	IN_WORLD,
	GAME_OVER,
}

@export var boot_scene: PackedScene
@export var ship_scene: PackedScene
@export var world_scene: PackedScene

var state: GameState = GameState.NONE:
	set(value):
		if state == value:
			return
		state = value
		state_changed.emit(state)


func go_to_start_menu() -> void:
	state = GameState.NOT_STARTED
	UI.reset_to_start_menu()


func start_game() -> void:
	enter_ship()


func enter_ship() -> void:
	state = GameState.IN_SHIP
	get_tree().change_scene_to_packed(ship_scene)


func enter_world() -> void:
	state = GameState.IN_WORLD
	get_tree().change_scene_to_packed(world_scene)


func end_game() -> void:
	if not is_playing():
		return
	state = GameState.GAME_OVER
	UI.push_game_over()


func restart_game() -> void:
	enter_ship()


func return_to_start_menu() -> void:
	state = GameState.NOT_STARTED
	get_tree().change_scene_to_packed(boot_scene)


func quit_game() -> void:
	state = GameState.NONE
	get_tree().quit()


func is_playing() -> bool:
	return state == GameState.IN_SHIP or state == GameState.IN_WORLD
