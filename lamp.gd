extends Node3D


@export var velocity_source: Player
@export_range(0.0, 4.0, 0.1) var sparkle_override: float

@onready var scrollingTexture: MeshInstance3D = $scrollingTex

func _physics_process(delta: float) -> void:
	# Shader version is buggy but maybe more performant
	#vec2 base_uv = UV + 1.0f * TIME * .01f;
	
	# Adjust sparkle in range 1-4 based on mex velocity
	# Doesn't account for other kinds of speed (jump)
	# POLISH 004: Check performance impact - maybe do this more lazily?
	var sparkle = (3*velocity_source.velocity.length()/velocity_source.speed)+1
	scrollingTexture.rotate(Vector3.UP, sparkle*delta/20)
