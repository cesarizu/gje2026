class_name InteractiveArea
extends Area2D

signal interacted

@export var show_hide: Array[Node] = []

var _player: Player


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	for node in show_hide:
		node.hide()


func _shortcut_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and _player:
		interacted.emit()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player = body as Player
		for node in show_hide:
			node.show()


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		for node in show_hide:
			node.hide()
