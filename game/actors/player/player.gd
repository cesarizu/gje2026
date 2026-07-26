class_name Player
extends CharacterBody2D

const SPEED = 300.0
var last_direction: Vector2 = Vector2.RIGHT
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var flashlight_light: Node2D = %FlashlightPivote

var flashlight_on: bool = false

signal flashlight_changed(enabled: bool)

func _ready() -> void:

	if get_tree().current_scene.name == "Ship":
		Dialogic.start("player_dialog")

func _physics_process(_delta: float) -> void:
	process_movement()
	process_animation()
	move_and_slide()
	var direction := Input.get_vector(
		"player_move_left",
		"player_move_right",
		"player_move_up",
		"player_move_down"
	)
	#if direction != Vector2.ZERO:
		#update_flashlight_direction(direction)

func process_movement() -> void:
	var direction = Input.get_vector("player_move_left", "player_move_right", "player_move_up", "player_move_down")

	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
	else:
		velocity = Vector2.ZERO

func process_animation()-> void:
	if velocity != Vector2.ZERO:
		play_animation("run", last_direction)
	else:
		play_animation("idle", last_direction)

func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down")

func set_flashlight_enabled(enabled: bool) -> void:
	flashlight_on = enabled
	flashlight_light.visible = enabled

func toggle_flashlight() -> void:
	set_flashlight_enabled(not flashlight_on)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("player_use_object"):
		if RunInventory.has_item("flashlight"):
			toggle_flashlight()

#func update_flashlight_direction(direction: Vector2) -> void:
	#if direction == Vector2.ZERO:
		#return
#
	#if abs(direction.x) > abs(direction.y):
		#if direction.x > 0:
			#flashlight_light.rotation_degrees = -90
		#else:
			#flashlight_light.rotation_degrees = 90
	#else:
		#if direction.y > 0:
			#flashlight_light.rotation_degrees = 0
		#else:
			#flashlight_light.rotation_degrees = 180

func _on_exit_area_interacted() -> void:
	pass # Replace with function body.
