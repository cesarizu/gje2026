class_name GameManager
extends Node

signal state_changed(new_state: GameState)

enum GameState {
	NONE,
	NOT_STARTED,
	PLAYING,
	GAME_OVER,
}

const BOOT_SCENE := "res://game/scenes/boot.tscn"
const WORLD_SCENE := "res://game/scenes/world.tscn"

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
	state = GameState.PLAYING
	get_tree().change_scene_to_file(WORLD_SCENE)


func end_game() -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.GAME_OVER
	UI.push_game_over()


func restart_game() -> void:
	state = GameState.PLAYING
	get_tree().change_scene_to_file(WORLD_SCENE)


func return_to_start_menu() -> void:
	state = GameState.NOT_STARTED
	get_tree().change_scene_to_file(BOOT_SCENE)


func quit_game() -> void:
	state = GameState.NONE
	get_tree().quit()


func is_playing() -> bool:
	return state == GameState.PLAYING
