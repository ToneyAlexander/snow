extends Node

func line(pos1: Vector3, pos2: Vector3, persist_s = 3, color = Color.WHITE_SMOKE):
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()
	
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	get_tree().get_root().add_child(mesh_instance)
	if persist_s:
		await get_tree().create_timer(persist_s).timeout
		mesh_instance.queue_free()
	else:
		return mesh_instance
#func self_line(vector, color):
#	Util.line(global_position, global_position + vector * 10, 1, color)

func dg(tag: String, value, truncate: bool = true):
	if typeof(value) == TYPE_FLOAT and truncate:
		value = "%.3f" % value
	SignalBus._debug_display.emit(tag, value)

#Util.dg("g_pos", self.position.round())
