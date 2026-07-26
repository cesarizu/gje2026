class_name Pod
extends Node2D

static var instance: Pod


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	UI.reset_to_hud()
