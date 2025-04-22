extends Area3D

@export var target_teleporter: NodePath
@export var cooldown_time: float = 1.0

var can_teleport: bool = true

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	if body.is_in_group("player") and can_teleport:
		var target = get_node_or_null(target_teleporter)
		if target:
			# Teleport the player
			body.global_position = target.global_position
			
			# Prevent fall-through by ensuring Y velocity is reset
			body.velocity.y = 0
			
			# Disable teleporting on both teleporters
			can_teleport = false
			target.can_teleport = false
			
			# Start cooldown timer
			get_tree().create_timer(cooldown_time).timeout.connect(
				func():
					can_teleport = true
					target.can_teleport = true
			)
