extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://map.tscn")




func _on_settings_button_pressed() -> void:
	var settings = preload("res://settings.tscn").instantiate()
	add_child(settings)
