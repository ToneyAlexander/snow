class_name Them extends StaticBody3D


func trigger():
	pass
	#self.transform

func camera_position():
	return self.global_position + Vector3(0, .5, 0)

func lerp_look(pos: Vector3):
	var xform := transform # your transform
	xform = xform.looking_at(pos,Vector3.UP)
	transform = transform.interpolate_with(xform,.1)
