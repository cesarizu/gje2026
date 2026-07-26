class_name GameManager
extends Node

signal state_changed(new_state: GameState)

enum GameState {
	NONE,
	NOT_STARTED,
	PLAYING,
	GAME_OVER,
}

@export var boot_scene: PackedScene
@export var ship_scene: PackedScene
@export var hill_scene: PackedScene
@export var snow_scene: PackedScene
@export var bridge_scene: PackedScene

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
	state = GameState.PLAYING
	get_tree().change_scene_to_packed(ship_scene)


func enter_hill() -> void:
	state = GameState.PLAYING
	get_tree().change_scene_to_packed(hill_scene)

func enter_snow() -> void:
	state = GameState.PLAYING
	get_tree().change_scene_to_packed(snow_scene)

func enter_bridge() -> void:
	state = GameState.PLAYING
	get_tree().change_scene_to_packed(bridge_scene)


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
	return state == GameState.PLAYING
