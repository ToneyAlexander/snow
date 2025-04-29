class_name cricket extends StaticBody3D
@export var rotation_speed: float = .50  # Controls how fast we rotate

var target_quat: Quaternion
var start_quat: Quaternion
var rotation_timer: float = 0.0
var rotation_duration: float = 2.0



func _ready():
	randomize()
	start_quat = global_transform.basis.get_rotation_quaternion()
	_set_new_target_rotation()

func _process(delta):
	if rotate:
		rotation_timer += delta
		var t = rotation_timer / rotation_duration
		t = clamp(t, 0.0, 1.0)

		# Slerp for smooth rotation
		var new_quat = start_quat.slerp(target_quat, t)
		global_transform.basis = Basis(new_quat)

		if t >= 1.0:
			start_quat = target_quat
			_set_new_target_rotation()

func _set_new_target_rotation():
	rotation_timer = 0.0
	rotation_duration = randf_range(2.0, 5.0)

	# Generate a random quaternion rotation
	var axis = Vector3(randf(), randf(), randf()).normalized()
	var angle = randf_range(PI / 4, PI)  # up to 180° rotation
	target_quat = Quaternion(axis, angle) * start_quat
