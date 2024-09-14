class_name DashTarget
extends Area3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var is_hovered: bool = false:
	set(value):
		is_hovered = value
		_update_visuals()

var mat: StandardMaterial3D
var noise_texture: NoiseTexture2D
var gradient: Gradient

var default_gradient_offset: float
var hovered_tween: Tween


func _ready():
	mat = mesh_instance.get_surface_override_material(0)
	noise_texture = mat.emission_texture
	gradient = noise_texture.color_ramp
	default_gradient_offset = gradient.get_offset(0)
	mat.albedo_texture = noise_texture
	mat.roughness_texture = noise_texture
	_update_visuals()


func _update_visuals():
	if hovered_tween:
		hovered_tween.kill()
	hovered_tween = create_tween()
	var cur_offset = gradient.get_offset(0)
	print(cur_offset)
	var time = 0.15
	# normalize against Engine.time_scale so tween isn't affected by slow motion
	time *= Engine.time_scale
	print(time)
	if is_hovered:
		hovered_tween.tween_method(set_gradient_offset, cur_offset, 0.25, time)
	else:
		hovered_tween.tween_method(set_gradient_offset, cur_offset, default_gradient_offset, time)


func set_gradient_offset(offset: float):
	gradient.set_offset(0, offset)
