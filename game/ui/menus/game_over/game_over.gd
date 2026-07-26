extends Menu

@onready var retry_button: Button = %RetryButton
@onready var exit_button: Button = %ExitButton


func _ready() -> void:
	if get_tree().current_scene == self:
		show()
		retry_button.grab_focus.call_deferred()
		return

	super()


func _on_retry_button_pressed() -> void:
	_disable_buttons()
	Core.game.start_game()


func _on_exit_button_pressed() -> void:
	_disable_buttons()
	Core.game.quit_game()


func _disable_buttons() -> void:
	retry_button.disabled = true
	exit_button.disabled = true
