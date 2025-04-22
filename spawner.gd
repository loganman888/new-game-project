extends Node3D

@export var enemy_scenes: Array[PackedScene]
@export var spawn_interval: float = .5
@export var max_enemies: int = 10
@export var target: Node3D
@export var spawn_radius: float = 5.0
@export var initial_spawn_delay: float = 3.0  # Delay before spawning starts

var spawn_timer: Timer
var delay_timer: Timer

func _ready() -> void:
	print("\n=== Spawner Initialization ===")
	print("Spawner position: ", global_position)
	
	# First check enemy scenes
	if enemy_scenes.is_empty():
		push_error("No enemy scenes assigned to spawner!")
		return
	
	# Try to find target if not assigned
	if !target:
		target = get_tree().get_first_node_in_group("dummy")
		if !target:
			push_error("No target assigned to spawner!")
			return
	
	# Create and setup spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	# Create and setup delay timer
	delay_timer = Timer.new()
	delay_timer.wait_time = initial_spawn_delay
	delay_timer.one_shot = true
	delay_timer.timeout.connect(_start_spawning)
	add_child(delay_timer)
	
	# Start delay timer
	delay_timer.start()

func _start_spawning() -> void:
	spawn_timer.start()
	_try_spawn_enemy()

func _on_spawn_timer_timeout() -> void:
	_try_spawn_enemy()

func _try_spawn_enemy() -> void:
	if !target:
		push_error("No target available for enemies!")
		return
		
	var current_enemies = get_tree().get_nodes_in_group("enemies").size()
	if current_enemies >= max_enemies:
		return
	
	var scene = enemy_scenes[randi() % enemy_scenes.size()]
	if !scene:
		push_error("Invalid enemy scene!")
		return
	
	var enemy = scene.instantiate()
	if !enemy:
		push_error("Failed to instantiate enemy!")
		return
	
	# Calculate spawn position
	var spawn_angle = randf() * TAU
	var spawn_distance = spawn_radius
	var spawn_offset = Vector3(
		cos(spawn_angle) * spawn_distance,
		0.0,
		sin(spawn_angle) * spawn_distance
	)
	
	# Add enemy to scene
	add_child(enemy)
	
	# Set position and target
	enemy.global_position = global_position + spawn_offset
	enemy.target = target
