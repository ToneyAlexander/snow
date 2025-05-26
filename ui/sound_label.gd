class_name SoundLabel extends Label


# POLISH 011: reuse these in a pool or something instead of creating
# POLISH 012: decouple from camera bobbing
# FEAT 013: Scrrensize again - scale properly, do it dynamically

const sound_label: PackedScene = preload("res://ui/sound_label.tscn")

var active = false
var track: Vector3

@export var I = 20.0
@export var n = 20.0

var front_color = Color("#f3ec32")
var behind_color = Color.CORNFLOWER_BLUE


static func create(label_text: String, location: Vector3, intensity := 20.0, distance_constant := 20.0) -> SoundLabel:
	var new_label: SoundLabel = sound_label.instantiate()
	new_label.track = location
	new_label.I = intensity
	new_label.n = distance_constant
	new_label.text = label_text
	return new_label


func activate():
	place_label(1.0)
	self.active = true
	
func deactivate():
	self.active = false


func place_label(lerp_rate: float = .5):
	var behind = get_viewport().get_camera_3d().is_position_behind(track)
	var projection = get_viewport().get_camera_3d().unproject_position(track)
	
	var d_square = get_viewport().get_camera_3d().global_position.distance_squared_to(track)
	
	# scale font size on distance instead of object?
	# Scale factor = intensity/(distance_constant + distance_squared)
	var sf = I / (n + d_square)
	
	var SCREEN_X = get_viewport().size.x
	var SCREEN_Y = get_viewport().size.y
	# BUG 009: bug where walking such that something moves from front to back makes it pop into bottom right corner?
	if behind:
		# flip it around
		projection = Vector2(SCREEN_X, SCREEN_Y) - projection
		
		projection -= Vector2(self.size.x, 0)
		
		# Translate this point to the oigin by the other point
		projection = projection - Vector2(SCREEN_X / 2, SCREEN_Y / 2)
		# Scale at the (temporary, new) origin.
		projection = projection * 2
		#Translate back so that the origin goes back to the designated point.
		projection = projection + Vector2(SCREEN_X / 2, SCREEN_Y / 2)
		
		set("theme_override_colors/font_color", behind_color)
		
		self.scale = Vector2(-sf, sf)
		 
		# POLISH 010
		# real bounding box, not a clamp (Container)
		# make clamp work with scaling?
		self.position = lerp(
			self.position,
			projection,
			lerp_rate
		).clamp(
			Vector2(2 * SCREEN_X / 20 + self.size.x * sf, 2 * SCREEN_Y / 20),
			Vector2(16 * SCREEN_X / 20 + self.size.x * sf, 16 * SCREEN_Y / 20)
		)
	else:
		set("theme_override_colors/font_color", front_color)
		
		self.scale = Vector2(sf, sf)
		self.position = self.position.lerp(
			projection,
			lerp_rate
		).clamp(
			Vector2(2 * SCREEN_X / 20, 2 * SCREEN_Y / 20),
			Vector2(16 * SCREEN_X / 20, 16 * SCREEN_Y / 20)
		)
	self.visible = active and sf >= .25

func _physics_process(_delta: float) -> void:
	place_label()
