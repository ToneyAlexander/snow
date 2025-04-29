extends Control

var thoughts: Dictionary[String, Control] = {}

func _ready() -> void:
	SignalBus.connect("_think", _think)

# FEAT 001
# thoughts float around
# fade out the value instead of removing
# Fade in and out in dialog
# fade in and out statically
# finer tuned control - keeping thoughts across nodes
func _think(thought: String):
	if thought in thoughts:
		
		self.remove_child(thoughts[thought])
		thoughts.erase(thought)
	else:
		var lbl = Label.new()
		lbl.text = thought
		lbl.set_position(Vector2(randf_range(self.position.x, self.size.x), randf_range(self.position.y, self.size.y)))
		lbl.add_theme_constant_override("outline_size", 18)
		self.add_child(lbl)
		thoughts[thought] = lbl
		
		
	
