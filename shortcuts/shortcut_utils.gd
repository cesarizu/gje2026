class_name ShortcutUtils

## A utility class for processing and simulating shortcut input events.
##
## This class provides static methods to handle shortcut simulation, allowing shortcuts
## to be triggered programmatically. It integrates with MenuStack to ensure shortcuts
## are properly handled by the top menu when available.


## Processes and simulates the input events for a given shortcut.
##
## This method checks if the "clicked" action was just released, then iterates through
## all InputEventAction events in the shortcut. For each event, it creates a duplicate
## with pressed=true and either forwards it to the top menu in MenuStack (if available)
## or parses it directly via Input.parse_input_event().
##
## Note: This is a workaround for https://github.com/godotengine/godot/issues/85984
##
## [param shortcut] The shortcut whose events should be simulated.
## [param owner] The node that owns/triggered the shortcut, used to find the top menu in MenuStack.
static func process_shortcut_input(shortcut: Shortcut, owner: Node) -> void:
	if not shortcut or not Input.is_action_just_released("clicked"):
		return

	for event: InputEvent in shortcut.events:
		if event is InputEventAction:
			var new_event: InputEventAction = event.duplicate()
			new_event.pressed = true

			# HACK: See https://github.com/godotengine/godot/issues/85984
			var top_menu := MenuStack.find_menu(owner)
			if top_menu:
				top_menu._shortcut_input(new_event)
			# ENDHACK

			Input.parse_input_event(new_event)
