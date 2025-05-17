class_name Them extends Conversable

@export var person_name := "them"

func get_person_name():
	return person_name

func camera_position():
	return self.global_position + Vector3(0, .5, 0)
