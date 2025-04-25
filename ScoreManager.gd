# score_manager.gd
extends Node

signal score_changed(new_score: int)
signal purchase_failed

var current_score: int = 500  # Start with 500 points

func _ready() -> void:
	# Emit initial score
	score_changed.emit(current_score)
	print("ScoreManager initialized with score: ", current_score)

func add_score(points: int) -> void:
	current_score += points
	score_changed.emit(current_score)
	print("Score changed by ", points, ". New score: ", current_score)

func get_score() -> int:
	return current_score

func has_enough_points(cost: int) -> bool:
	return current_score >= cost

func purchase_turret(cost: int) -> bool:
	if has_enough_points(cost):
		add_score(-cost)  # Deduct the cost
		print("Turret purchased for ", cost, " points")
		return true
	else:
		purchase_failed.emit()
		print("Purchase failed: Not enough points")
		return false
