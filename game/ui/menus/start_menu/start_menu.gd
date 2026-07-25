extends Menu


func _on_start_button_pressed() -> void:
	Core.game.start_game()


func _on_exit_button_pressed() -> void:
	get_tree().quit()
