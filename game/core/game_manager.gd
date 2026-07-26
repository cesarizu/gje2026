class_name GameManager
extends Node

signal state_changed(new_state: GameState)
signal lifes_changed()

const MAX_LIFES := 3

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

var lifes := MAX_LIFES:
	set(value):
		if lifes != value:
			var do_emit := lifes > value
			lifes = max(0, value)
			if do_emit:
				lifes_changed.emit()
			if lifes == 0:
				end_game()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"go_full_screen"):
		toggle_full_screen()
		get_viewport().set_input_as_handled()


func toggle_full_screen() -> void:
	var window := get_window()
	if window.mode == Window.MODE_FULLSCREEN or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		window.mode = Window.MODE_WINDOWED
	else:
		window.mode = Window.MODE_FULLSCREEN


func go_to_start_menu() -> void:
	state = GameState.NOT_STARTED
	await UI.fade_out()
	UI.reset_to_start_menu()
	await UI.fade_in()


func start_game() -> void:
	lifes = MAX_LIFES
	enter_ship()


func enter_ship() -> void:
	await UI.fade_out()
	state = GameState.PLAYING
	get_tree().change_scene_to_packed(ship_scene)


func enter_hill() -> void:
	await UI.fade_out()
	state = GameState.PLAYING
	get_tree().change_scene_to_packed(hill_scene)


func enter_snow() -> void:
	await UI.fade_out()
	state = GameState.PLAYING
	get_tree().change_scene_to_packed(snow_scene)


func enter_bridge() -> void:
	await UI.fade_out()
	state = GameState.PLAYING
	get_tree().change_scene_to_packed(bridge_scene)


func enter_pod() -> void:
	await UI.fade_out()
	state = GameState.PLAYING
	get_tree().change_scene_to_packed(pod_scene)


func end_game() -> void:
	if not is_playing():
		return

	await get_tree().create_timer(2).timeout
	state = GameState.GAME_OVER
	UI.push_game_over()


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


func hit() -> void:
	lifes = lifes - 1
