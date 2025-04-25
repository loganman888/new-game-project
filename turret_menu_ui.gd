extends Control

@onready var grid_container = $Panel/GridContainer
var pickup_system: Node

const BASIC_TURRET_COST = 50
const RAPID_TURRET_COST = 75
const SLOW_TURRET_COST = 100
const DOT_TURRET_COST = 120 # Add cost for DOT turret

var turret_types = {
	"Basic Turret": {
		"scene": preload("res://turret.tscn"),
		"cost": BASIC_TURRET_COST
	},
	"Rapid Turret": {
		"scene": preload("res://rapid_turret.tscn"),
		"cost": RAPID_TURRET_COST
	},
	"Slow Turret": {
		"scene": preload("res://slow_turret.tscn"),
		"cost": SLOW_TURRET_COST
	},
	"DOT Turret": { # Add DOT turret entry
		"scene": preload("res://dot_turret.tscn"),  # <--- SET THIS PATH CORRECTLY!
		"cost": DOT_TURRET_COST
	}
}

func _ready():
	visible = false
	pickup_system = get_tree().get_first_node_in_group("pickup_system")
	setup_turret_buttons()

func _input(event):
	if event.is_action_pressed("open_turret_menu"):
		toggle_menu()

func setup_turret_buttons():
	for turret_name in turret_types:
		var button = Button.new()
		button.text = "%s (%d pts)" % [turret_name, turret_types[turret_name].cost]
		button.custom_minimum_size = Vector2(100, 50)
		button.pressed.connect(_on_turret_button_pressed.bind(turret_name))
		grid_container.add_child(button)

func _on_turret_button_pressed(turret_name: String):
	var turret_data = turret_types[turret_name]
	
	if ScoreManager.purchase_turret(turret_data.cost):
		if pickup_system:
			var new_turret = turret_data.scene.instantiate()
			get_tree().get_root().add_child(new_turret)
			pickup_system.pickup_turret(new_turret)
			toggle_menu()

func toggle_menu():
	visible = !visible
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
