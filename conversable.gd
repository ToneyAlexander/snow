class_name Conversable extends StaticBody3D


func get_person_name() -> String:
	return "Nameless"


func trigger():
	pass
	#self.transform


func camera_position():
	return self.global_position


func lerp_look(pos: Vector3):
	var xform := transform # your transform
	xform = xform.looking_at(pos, Vector3.UP)
	transform = transform.interpolate_with(xform, .1)