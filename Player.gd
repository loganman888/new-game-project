extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.005

#BOB variables
const BOB_FREQ = 2.8
const BOB_AMP = 0.02
var t_bob = 0.0

#fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var health_lbl: Label = $HealthLbl
@onready var health_component: Node = $HealthComponent
@onready var pickup_system = $PickupSystem

var gravity = 9.8

func _ready():
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("Player initialized")

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(60))
	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if Input.is_action_just_pressed("open_turret_menu"):
		var menu = get_tree().get_first_node_in_group("turret_menu")
		if menu:
			menu.toggle_menu()

func _process(_delta: float) -> void:
	health_lbl.text = str(health_component.health)
	check_turret_interaction()

func check_turret_interaction() -> void:
	if Input.is_action_just_pressed("interact"):
		print("\n=== Checking Turret Interaction ===")
		var space_state = get_world_3d().direct_space_state
		var start_pos = camera.global_position
		var end_pos = camera.global_position + camera.global_transform.basis.z * 10.0
		
		var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
		query.collision_mask = 32  # Layer 6 (Pickup)
		query.exclude = [self]
		query.collide_with_areas = true
		query.collide_with_bodies = false
		query.hit_from_inside = true
		
		print("Raycast from: ", start_pos)
		print("Raycast to: ", end_pos)
		
		# Debug all turrets in scene
		var all_turrets = get_tree().get_nodes_in_group("turrets")
		print("All turrets in scene: ", all_turrets)
		for turret in all_turrets:
			print("Turret position: ", turret.global_position)
			print("Distance to turret: ", global_position.distance_to(turret.global_position))
			
			if turret.has_node("PickupDetectionArea"):
				var area = turret.get_node("PickupDetectionArea")
				print("Pickup area layers: ", area.collision_layer)
				print("Pickup area mask: ", area.collision_mask)
		
		var result = space_state.intersect_ray(query)
		if result:
			print("Hit something: ", result.collider)
			if result.collider.get_parent().is_in_group("turrets"):
				print("Found turret, attempting pickup")
				pickup_system.pickup_turret(result.collider.get_parent())
		else:
			print("No hit detected")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += calculate_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction: Vector3 = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)

	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func on_death() -> void:
	get_tree().quit()

func calculate_gravity() -> Vector3:
	return Vector3(0, -gravity, 0)
