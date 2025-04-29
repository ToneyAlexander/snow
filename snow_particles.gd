extends GPUParticles3D

var da: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var data = []
	for i in range(self.amount):
		var random_angle = randf_range(-0.5, 0.5) # Small variation
		var normal = Vector3(0*sin(random_angle), 0*cos(random_angle), 1+0*sin(random_angle))
		data.append(Vector4(normal.x, normal.y, normal.z, 0))
	self.process_material.set("custom_data", data)
	self.emitting = true



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	da += delta
	# POLISH 003: get this variation working, set a value
	self.speed_scale = 0.05#(sin(da/5) + 1.01)/10
	#var camera = get_viewport().get_camera_3d()
	#if camera:
		#var inv_view_matrix = camera.global_transform
		#print("Inverse View Matrix:\n", inv_view_matrix)
