extends Control

func _ready() -> void:
	# Set volume slider range
	$MarginContainer/VBoxContainer/Volume.min_value = -80   # All the way left (mute)
	$MarginContainer/VBoxContainer/Volume.max_value = -20   # All the way right (somewhat quiet)
	$MarginContainer/VBoxContainer/Volume.step = 0.1        # For smoothness
	
	# Set the mute checkbox to reflect the current mute status
	$MarginContainer/VBoxContainer/Mute.button_pressed = AudioServer.is_bus_mute(0)
	
	# Set the volume slider to reflect the current volume, clamped to this range
	var db = AudioServer.get_bus_volume_db(0)
	db = clamp(db, -80, -20)
	$MarginContainer/VBoxContainer/Volume.value = db

func _on_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, value)

func _on_mute_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(0, toggled_on)

func _on_resolutions_item_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920,1080))
		1:
			DisplayServer.window_set_size(Vector2i(1600,900))
		2:
			DisplayServer.window_set_size(Vector2i(1280,960))

func _on_back_button_pressed() -> void:
	queue_free()
