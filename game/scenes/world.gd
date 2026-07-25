class_name World
extends Node2D

static var instance: World


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	UI.reset_to_hud()
