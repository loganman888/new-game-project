extends Control

# Reference to the GridContainer holding shop buttons
@onready var grid_container = $Panel/GridContainer

# Will hold a reference to our pickup_system node for telling it to start placement mode
var pickup_system: Node

# Costs for all purchasable shop items
const BASIC_TURRET_COST = 50
const RAPID_TURRET_COST = 75
const SLOW_TURRET_COST = 100
const DOT_TURRET_COST = 120
const PLATFORM_COST = 80

# Dictionary listing all purchasable items in the shop
# Each item needs a scene, cost, and type (turret or platform)
var turret_types = {
	"Basic Turret": {
		"scene": preload("res://turret.tscn"),
		"cost": BASIC_TURRET_COST,
		"type": "turret"
	},
	"Rapid Turret": {
		"scene": preload("res://rapid_turret.tscn"),
		"cost": RAPID_TURRET_COST,
		"type": "turret"
	},
	"Slow Turret": {
		"scene": preload("res://slow_turret.tscn"),
		"cost": SLOW_TURRET_COST,
		"type": "turret"
	},
	"DOT Turret": {
		"scene": preload("res://dot_turret.tscn"),
		"cost": DOT_TURRET_COST,
		"type": "turret"
	},
	"Platform": {
		"scene": preload("res://turret_platform.tscn"),
		"cost": PLATFORM_COST,
		"type": "platform"
	}
}

func _ready():
	# Hide the menu at game start
	visible = false
	# Find the pickup system node (only needed once at start)
	pickup_system = get_tree().get_first_node_in_group("pickup_system")
	# Fill grid_container with shop buttons
	setup_turret_buttons()

func _input(event):
	# Listen for player input to (un)show the menu
	if event.is_action_pressed("open_turret_menu"):
		toggle_menu()

# Re/creates all shop buttons for each item in the shop
func setup_turret_buttons():
	# Remove all previous children (buttons) from the container
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()
	# Now add a button for every item in turret_types
	for name in turret_types:
		var data = turret_types[name]
		var button = Button.new()
		# Label shows item name and price
		button.text = "%s (%d pts)" % [name, data.cost]
		# Make the button small
		button.custom_minimum_size = Vector2(80, 32)
		# When this button is pressed, call our handler with the item name as argument
		button.pressed.connect(_on_item_button_pressed.bind(name))
		# Add to the shop grid
		grid_container.add_child(button)

# Called when the player clicks a buy button
func _on_item_button_pressed(item_name: String):
	var data = turret_types[item_name]
	# --- BUG FIX: Prevent buying if a turret or platform is already being held ---
	if pickup_system.current_turret or pickup_system.current_platform:
		print("You're already holding a placement item! Place or cancel it before buying another.")
		# Optionally: Show error message to player here
		return
	# Only proceed if enough points AND not holding a placement item
	if ScoreManager.purchase_turret(data.cost):
		if pickup_system:
			var new_item = data.scene.instantiate()
			get_tree().get_root().add_child(new_item)
			if data.type == "turret":
				pickup_system.pickup_turret(new_item, data.type, data.cost)
			elif data.type == "platform":
				pickup_system.pickup_platform(new_item, data.cost)
			toggle_menu()

# Open/close the menu and set mouse control appropriately
func toggle_menu():
	visible = !visible
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
