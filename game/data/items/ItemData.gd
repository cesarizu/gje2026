extends Resource
class_name ItemData

@export_group("Información")
@export var id: StringName = ""
@export var item_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Inventario")
@export_range(1, 3) var width: int = 1
@export_range(1, 3) var height: int = 1
@export var can_rotate: bool = true

@export_group("Uso")
@export var uses_charges: bool = true
@export var max_charges: int = 1
@export var use_text: String = ""
