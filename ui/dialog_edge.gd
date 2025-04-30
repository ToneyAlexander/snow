class_name DialogEdge extends RefCounted

var response: String
var they_say: String
var destination: DialogState

func _init(p_response, p_they_say, p_destination):
	self.response = p_response
	self.they_say = p_they_say
	self.destination = p_destination
