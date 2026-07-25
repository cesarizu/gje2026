class_name ControllerDetectionConfig
extends Resource

# Order matters: first match wins.
@export var controller_match_order: Array[String] = []

@export var controller_match_substrings: Dictionary[String, PackedStringArray] = {}

@export var controller_fallbacks: Dictionary[String, String] = {}

# Maps InputManager.GamepadType key names to icon prefixes.
@export var gamepad_type_prefixes: Dictionary[String, String] = {
	"UNKNOWN": "xbox",
	"XBOX": "xbox",
	"PLAYSTATION": "playstation"
}
