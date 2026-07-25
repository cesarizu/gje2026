extends CharacterBody2D
@onready var animated_sprite_2d = $AnimatedSprite2D

const SPEED = 300.0
var facing := "down"

func _physics_process(_delta: float) -> void:
	process_movement()
	move_and_slide()
	
func process_movement() -> void:
	var direction = Input.get_vector("player_move_left", "player_move_right", "player_move_up", "player_move_down")
	
	velocity = direction * SPEED
	play_animation(direction)
	
func play_animation(dir: Vector2) -> void:
	if dir.x > 0:
		facing = "right"
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play("run_right")
	elif dir.x < 0:
		facing = "left"
		animated_sprite_2d.flip_h = true
		animated_sprite_2d.play("run_right")
	elif dir.y > 0:
		facing = "down"
		animated_sprite_2d.play("run_down")
	elif dir.y < 0:
		facing = "up"
		animated_sprite_2d.play("run_up")
	else:
		match facing:
			"right":
				animated_sprite_2d.flip_h = false
				animated_sprite_2d.play("idle_right")
			"left":
				animated_sprite_2d.flip_h = true
				animated_sprite_2d.play("idle_right")
			"up":
				animated_sprite_2d.play("idle_up")
			"down":
				animated_sprite_2d.play("idle_down")
