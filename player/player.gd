class_name Player
extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export_category("Dash")
@export var dash_speed: float = 20.0
@export var max_dash_distance: float = 10.0

@export_category("Camera")
@export var mouse_sensitivity := 700.0
@export var camera_responsiveness := 80.0
@export var vertical_angle_limit := 90.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = %Camera3D
@onready var target_detector: TargetDetector = %TargetDetector
@onready var state_chart: StateChart = $StateChart

var current_target: DashTarget
var dash_target: DashTarget

# Dash
var last_dash_time: float
var dash_dir: Vector3
var dash_start: Vector3
var dash_end: Vector3
var dash_time: float
var can_slow: bool = false
var did_slow_this_dash: bool = false
var slow_enter_time: float


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		var mouse_input = event.relative / mouse_sensitivity
		head.rotation.x -= mouse_input.y
		rotation.y -= mouse_input.x
		var angle_limit = deg_to_rad(vertical_angle_limit)
		rotation.x = clamp(rotation.x, -angle_limit, angle_limit)
	if event.is_action_pressed("primary_action"):
		if current_target:
			var target_dir = (current_target.global_position - camera.global_position).normalized()
			var t_dot = (-camera.global_basis.z).dot(target_dir)
			dash(current_target)
			print("target: %s, dot: %s" % [current_target.name, t_dot])
	if event.is_action_pressed("secondary_action"):
		Engine.time_scale = 0.25
	elif event.is_action_released("secondary_action"):
		Engine.time_scale = 1.0


func _process(delta):
	var look_dir = -camera.global_basis.z
	var target = target_detector.get_target_by_dot(look_dir, camera.global_position)
	if target != current_target:
		if current_target:
			current_target.is_hovered = false
		current_target = target
		if current_target:
			current_target.is_hovered = true


func dash(target: DashTarget):
	if not target:
		return
	state_chart.send_event("dash")


func _on_idle_state_physics_processing(delta: float):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func _on_dash_state_entered():
	dash_target = current_target
	last_dash_time = G.get_time()
	dash_dir = camera.global_position.direction_to(dash_target.global_position)
	var dash_dist = min(
		global_position.distance_to(dash_target.global_position) + 1.0, max_dash_distance
	)
	var col = G.do_raycast(global_position, dash_dir, max_dash_distance)
	if col:
		if is_on_floor():
			var target_pos = dash_target.global_position
			target_pos.y = global_position.y
			dash_dir = global_position.direction_to(target_pos)
		else:
			dash_dist = global_position.distance_to(col.position)
	dash_start = global_position
	dash_end = dash_start + dash_dir * dash_dist
	dash_time = dash_dist / dash_speed
	var target_dist = camera.global_position.distance_to(dash_target.global_position)
	print("target_dist: %s" % target_dist)
	can_slow = target_dist > 1.5
	did_slow_this_dash = false


func _on_dash_state_processing(delta: float):
	# if G.get_time() - last_dash_time > dash_time:
	# 	state_chart.send_event("idle")
	pass


func _on_dash_state_physics_processing(delta: float):
	# global_position = lerp(dash_start, dash_end, (G.get_time() - last_dash_time) / dash_time)
	var collision = move_and_collide(dash_dir * dash_speed * delta)

	if can_slow:
		var target_dist = camera.global_position.distance_to(dash_target.global_position)
		if target_dist < 1.5 and not did_slow_this_dash:
			slow_enter_time = G.get_time()
			did_slow_this_dash = true
			Engine.time_scale = 0.01
		elif did_slow_this_dash and G.get_time() - slow_enter_time > 0.75:
			Engine.time_scale = 1.0
	if global_position.distance_to(dash_start) >= dash_end.distance_to(dash_start):
		state_chart.send_event("idle")

	# if collision:
	# 	print(collision)
	# 	state_chart.send_event("idle")


func _on_dash_state_exited():
	velocity = Vector3.ZERO
	dash_target = null
	Engine.time_scale = 1.0
	pass  # Replace with function body.
