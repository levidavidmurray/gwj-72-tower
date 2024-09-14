class_name TargetDetector
extends Area3D

@export var dot_threshold: float = 0.005

var possible_targets: Array[DashTarget] = []


func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func get_target_by_dot(look_dir: Vector3, origin: Vector3) -> DashTarget:
	var best_target: DashTarget = null
	var best_dot = -1.0
	for target in possible_targets:
		var to_target = (target.global_position - origin).normalized()
		var dot = look_dir.dot(to_target)
		if 1.0 - dot > dot_threshold:
			continue
		if dot > best_dot:
			best_dot = dot
			best_target = target
	return best_target


func _on_area_entered(area):
	if area is DashTarget and area not in possible_targets:
		possible_targets.append(area)


func _on_area_exited(area):
	if area is DashTarget:
		possible_targets.erase(area)
