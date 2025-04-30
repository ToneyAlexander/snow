class_name DialogState extends RefCounted

var you: bool = true
var directions: Array[String] = []
var choices: Dictionary[String, DialogEdge] = {}

func _init(p_directions: Array[String], p_choices: Dictionary[String, DialogEdge], p_you = true):
	self.you = p_you
	self.directions = p_directions
	self.choices = p_choices
	
func choose(choice: String) -> DialogEdge:
	return self.choices.get(choice)
