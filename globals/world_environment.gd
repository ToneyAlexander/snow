extends WorldEnvironment

# bgcolor
#2e2e2e

# POLISH 002
# go lower for more vibrant snow pruples?
# clear color is gray snow
# tune this with direcvtional ligth and fog for effects
# pick important components to adjust and test
# Change source to background... kind of interesting

@export var enabled := true

var environment_scene = preload("res://worldenv.tres")

func _ready() -> void:
	if enabled:
		self.environment = environment_scene
		self.environment.fog_enabled = true
	else:
		self.environment = null
