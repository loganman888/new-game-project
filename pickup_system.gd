# pickup_system.gd - Working version
extends Node3D

@onready var camera = $"../Head/Camera3D"

var current_turret: Node3D = null
var placement_valid: bool = false
const PLACEMENT_HEIGHT_OFFSET: float = 1.0
const MIN_PLACEMENT_DISTANCE: float = 2.0
const MAX_PLACEMENT_DISTANCE: float = 10.0

# Preview materials
var preview_material_valid: StandardMaterial3D
var preview_material_invalid: StandardMaterial3D

func _ready() -> void:
	add_to_group("pickup_system")
	
	# Setup preview materials
	preview_material_valid = StandardMaterial3D.new()
	preview_material_valid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	preview_material_valid.albedo_color = Color(0, 1, 0, 0.5)  # Green for valid placement
	preview_material_valid.emission_enabled = true
	preview_material_valid.emission = Color(0, 1, 0, 0.5)
	
	preview_material_invalid = StandardMaterial3D.new()
	preview_material_invalid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	preview_material_invalid.albedo_color = Color(1, 0, 0, 0.5)  # Red for invalid placement
	preview_material_invalid.emission_enabled = true
	preview_material_invalid.emission = Color(1, 0, 0, 0.5)

func _process(_delta: float) -> void:
	if current_turret:
		update_placement_position()
		handle_placement_input()

func update_placement_position() -> void:
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = MAX_PLACEMENT_DISTANCE
	
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [current_turret, get_parent()]  # Exclude the turret and player
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	if result:
		var placement_position = result.position
		placement_position.y += PLACEMENT_HEIGHT_OFFSET
		
		# Check placement validity
		placement_valid = check_placement_validity(placement_position, result.normal)
		
		# Update turret position and rotation
		current_turret.global_position = placement_position
		
		# Align turret with surface normal
		if placement_valid:
			align_turret_with_surface(result.normal)
			current_turret.update_preview_material(preview_material_valid)
		else:
			current_turret.update_preview_material(preview_material_invalid)
		
		current_turret.visible = true
	else:
		placement_valid = false
		current_turret.visible = false

func check_placement_validity(position: Vector3, normal: Vector3) -> bool:
	# Check distance from player
	var distance_to_player = position.distance_to(get_parent().global_position)
	if distance_to_player < MIN_PLACEMENT_DISTANCE or distance_to_player > MAX_PLACEMENT_DISTANCE:
		return false
	
	# Check surface angle (prevent placement on steep surfaces)
	var up_dot = normal.dot(Vector3.UP)
	if up_dot < 0.7: # About 45 degrees max slope
		return false
	
	# Check for nearby turrets
	var nearby_turrets = get_tree().get_nodes_in_group("turrets")
	for turret in nearby_turrets:
		if turret != current_turret and position.distance_to(turret.global_position) < 2.0:
			return false
	
	return true

func align_turret_with_surface(normal: Vector3) -> void:
	# Create a basis with the up vector aligned to the surface normal
	var up = normal
	var forward = Vector3.FORWARD
	if up.is_equal_approx(Vector3.UP):
		forward = Vector3.FORWARD
	else:
		forward = Vector3.UP.cross(up).normalized()
	var right = up.cross(forward).normalized()
	
	var alignment_basis = Basis(right, up, forward)
	current_turret.global_transform.basis = alignment_basis

func pickup_turret(turret: Node3D) -> void:
	if current_turret:
		return
	
	current_turret = turret
	current_turret.set_preview(true)
	current_turret.update_preview_material(preview_material_valid)

func place_turret() -> void:
	if !current_turret or !placement_valid:
		return
	
	current_turret.set_preview(false)
	current_turret.set_active(true)
	current_turret = null

func handle_placement_input() -> void:
	if Input.is_action_just_pressed("mouse_left") and placement_valid:
		place_turret()
	elif Input.is_action_just_pressed("mouse_right"):
		cancel_placement()

func cancel_placement() -> void:
	if current_turret:
		current_turret.queue_free()
		current_turret = null
