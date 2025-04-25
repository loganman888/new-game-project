extends Control

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Allow menu to work while paused

func _input(event):
	if event.is_action_pressed("escape"):
		toggle_menu()

func toggle_menu():
	visible = !visible
	if visible:
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_resume_pressed() -> void:
	toggle_menu()

func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_settings_button_pressed() -> void:
	var settings = preload("res://settings.tscn").instantiate()
	add_child(settings)
	
	
