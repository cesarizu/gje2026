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
@export var pod_scene: PackedScene

var state: GameState = GameState.NONE:
	set(value):
		if state == value:
			return
		state = value
		state_changed.emit(state)


func go_to_start_menu() -> void:
	state = GameState.NOT_STARTED
	await UI.fade_out()
	UI.reset_to_start_menu()
	await UI.fade_in()


func start_game() -> void:
	enter_ship()


func enter_ship() -> void:
	await UI.fade_out()
	state = GameState.PLAYING
	get_tree().change_scene_to_packed(ship_scene)
	await UI.fade_in()


func enter_hill() -> void:
	await UI.fade_out()
	state = GameState.PLAYING
	get_tree().change_scene_to_packed(hill_scene)
	await UI.fade_in()


func enter_snow() -> void:
	await UI.fade_out()
	state = GameState.PLAYING
	get_tree().change_scene_to_packed(snow_scene)
	await UI.fade_in()


func enter_bridge() -> void:
	await UI.fade_out()
	state = GameState.PLAYING
	get_tree().change_scene_to_packed(bridge_scene)
	await UI.fade_in()


func enter_pod() -> void:
	await UI.fade_out()
	state = GameState.PLAYING
	get_tree().change_scene_to_packed(pod_scene)
	await UI.fade_in()


func end_game() -> void:
	await UI.fade_out()
	if not is_playing():
		return
	state = GameState.GAME_OVER
	UI.push_game_over()
	await UI.fade_in()


func restart_game() -> void:
	await UI.fade_out()
	enter_ship()
	await UI.fade_in()


func return_to_start_menu() -> void:
	await UI.fade_out()
	state = GameState.NOT_STARTED
	get_tree().change_scene_to_packed(boot_scene)
	await UI.fade_in()


func quit_game() -> void:
	await UI.fade_out()
	state = GameState.NONE
	get_tree().quit()


func is_playing() -> bool:
	return state == GameState.PLAYING
