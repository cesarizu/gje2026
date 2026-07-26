class_name Pod
extends Node2D


func _ready() -> void:
	UI.reset_to_hud()
	await UI.fade_in()
