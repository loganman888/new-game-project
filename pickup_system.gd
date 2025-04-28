extends Node3D

@onready var camera = $"../Head/Camera3D"

var current_turret: Node3D = null
var current_platform: Node3D = null
var placement_valid: bool = false
var placement_platform: Node3D = null

# For refunds:
var held_item_type: String = ""  # "turret" or "platform"
var held_item_cost: int = 0

const PLACEMENT_HEIGHT_OFFSET: float = 1.0
const MIN_PLACEMENT_DISTANCE: float = 0.5
const MAX_PLACEMENT_DISTANCE: float = 3.0

# Preview materials (green=valid, red=invalid)
var preview_material_valid: StandardMaterial3D
var preview_material_invalid: StandardMaterial3D

func _ready() -> void:
	add_to_group("pickup_system")

	# Setup preview materials
	preview_material_valid = StandardMaterial3D.new()
	preview_material_valid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	preview_material_valid.albedo_color = Color(0, 1, 0, 0.5)
	preview_material_valid.emission_enabled = true
	preview_material_valid.emission = Color(0, 1, 0, 0.5)

	preview_material_invalid = StandardMaterial3D.new()
	preview_material_invalid.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	preview_material_invalid.albedo_color = Color(1, 0, 0, 0.5)
	preview_material_invalid.emission_enabled = true
	preview_material_invalid.emission = Color(1, 0, 0, 0.5)

func _process(_delta: float) -> void:
	if current_turret:
		update_turret_placement()
		handle_turret_placement_input()
	elif current_platform:
		update_platform_placement()
		handle_platform_placement_input()

# --- Turret Placement ---
func pickup_turret(turret: Node3D, turret_type: String, cost: int) -> void:
	if current_turret or current_platform:
		return
	current_turret = turret
	current_turret.set_preview(true)
	current_turret.update_preview_material(preview_material_valid)
	held_item_type = turret_type
	held_item_cost = cost

func update_turret_placement() -> void:
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = MAX_PLACEMENT_DISTANCE
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [current_turret, get_parent()]
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result = space_state.intersect_ray(query)
	placement_valid = false
	placement_platform = null
	if result:
		var node = result.collider
		while node and not node.is_in_group("turret_platforms"):
			node = node.get_parent()
		if node and node.is_in_group("turret_platforms"):
			var platform = node
			var platform_pos = platform.global_transform.origin + platform.snap_point
			var distance_to_player = platform_pos.distance_to(get_parent().global_position)
			current_turret.global_position = platform_pos
			current_turret.global_rotation = platform.global_rotation
			if not platform.can_place():
				current_turret.update_preview_material(preview_material_invalid)
			elif distance_to_player < MIN_PLACEMENT_DISTANCE or distance_to_player > MAX_PLACEMENT_DISTANCE:
				current_turret.update_preview_material(preview_material_invalid)
			else:
				current_turret.update_preview_material(preview_material_valid)
				placement_valid = true
				placement_platform = platform
		else:
			var preview_pos = result.position
			preview_pos.y += PLACEMENT_HEIGHT_OFFSET
			current_turret.global_position = preview_pos
			current_turret.update_preview_material(preview_material_invalid)
		current_turret.visible = true
	else:
		placement_valid = false
		current_turret.visible = false

func handle_turret_placement_input() -> void:
	if Input.is_action_just_pressed("mouse_left") and placement_valid:
		place_turret()
	elif Input.is_action_just_pressed("mouse_right"):
		cancel_turret_placement()

func place_turret() -> void:
	if !current_turret or !placement_valid or !placement_platform:
		return
	placement_platform.place_turret(current_turret)
	current_turret.platform = placement_platform
	current_turret.set_preview(false)
	current_turret.set_active(true)
	current_turret = null
	placement_platform = null
	held_item_type = ""
	held_item_cost = 0

func cancel_turret_placement() -> void:
	if current_turret:
		if held_item_cost > 0:
			ScoreManager.refund_points(int(held_item_cost * 0.5))
		current_turret.queue_free()
		current_turret = null
		held_item_type = ""
		held_item_cost = 0

# --- Platform Placement ---
func pickup_platform(platform: Node3D, cost: int) -> void:
	if current_platform or current_turret:
		return
	current_platform = platform
	if current_platform.has_method("set_preview"):
		current_platform.set_preview(true)
	if current_platform.has_method("update_preview_material"):
		current_platform.update_preview_material(preview_material_valid)
	held_item_type = "platform"
	held_item_cost = cost

func update_platform_placement() -> void:
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = MAX_PLACEMENT_DISTANCE
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [current_platform, get_parent()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	placement_valid = false
	if result:
		var platform_pos = result.position
		platform_pos.y += PLACEMENT_HEIGHT_OFFSET
		current_platform.global_position = platform_pos
		var distance_to_player = platform_pos.distance_to(get_parent().global_position)
		if distance_to_player < MIN_PLACEMENT_DISTANCE or distance_to_player > MAX_PLACEMENT_DISTANCE:
			if current_platform.has_method("update_preview_material"):
				current_platform.update_preview_material(preview_material_invalid)
			placement_valid = false
		else:
			if current_platform.has_method("update_preview_material"):
				current_platform.update_preview_material(preview_material_valid)
			placement_valid = true
		current_platform.visible = true
	else:
		placement_valid = false
		current_platform.visible = false

func handle_platform_placement_input() -> void:
	if Input.is_action_just_pressed("mouse_left") and placement_valid:
		place_platform()
	elif Input.is_action_just_pressed("mouse_right"):
		cancel_platform_placement()

func place_platform() -> void:
	if not current_platform or not placement_valid:
		return
	if current_platform.has_method("set_preview"):
		current_platform.set_preview(false)
	current_platform = null
	placement_valid = false
	held_item_type = ""
	held_item_cost = 0

func cancel_platform_placement() -> void:
	if current_platform:
		if held_item_cost > 0:
			ScoreManager.refund_points(held_item_cost)
		current_platform.queue_free()
		current_platform = null
		placement_valid = false
		held_item_type = ""
		held_item_cost = 0
