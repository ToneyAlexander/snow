extends Control

@onready var l_sound := $left
@onready var r_sound := $right

# FEAT 017: discrete vs continuous sounds

var L_ONOMATOPOEIA := ["*cronch*", "*crunch*", "*scrunch*", "*crinch*"] # ["*crinch*", "*crunch*", "*scrinch*"]
var R_ONOMATOPOEIA := ["*cronch*", "*crunch*", "*scrunch*", "*crinch*"]

func _ready() -> void:
	l_sound.pivot_offset = l_sound.size/2
	r_sound.pivot_offset = r_sound.size/2

var t = 0
var c = 0

@export var do_others := true


func _process(delta: float) -> void:
	if do_others:
		t += delta
		c += delta
		if t > 5:
			t = 0
			var intensity = 50
			var label1 := SoundLabel.create("*zmzmzmr*", Vector3(13.647, 9, -4.352), intensity, 1)
			discrete_sound(label1, 4, 0)
			var label2 := SoundLabel.create("*zmzmzmr*", Vector3(-1, 9, -5), intensity, 1)
			discrete_sound(label2, 4, 0)
			
		if c > 1:
			c = 0
			var clabel := SoundLabel.create("*chrip*", Vector3(11.076, 1.35, -7.553), 20, 20)
			discrete_sound(clabel, .75, 0)

# POLISH 015: Better offscreen indicator
# FEAT 014: signals :)
func discrete_sound(sound_label: SoundLabel, duration: float, delay: float = 0.0):
	add_child(sound_label)
	await get_tree().create_timer(delay).timeout
	sound_label.activate()
	await get_tree().create_timer(duration).timeout
	sound_label.deactivate()
	# POLISH 011: when should I free these? make them poolable by caller or... someone? me?
	sound_label.queue_free()


# offset is percent of screen height
func left_start(duration: float, delay: float = 0.0, y_offset: float = 0.0):
	l_sound.offset_left = randf_range(-50, 50) - l_sound.size.x / 2
	l_sound.offset_top = randf_range(-50, 50) + self.size.y * y_offset - l_sound.size.y / 2
	l_sound.rotation_degrees = randf_range(0, 20)
	if l_sound is RichTextLabel:
		l_sound.text = "[i]" + L_ONOMATOPOEIA.pick_random() + "[/i]"
	else:
		l_sound.text = L_ONOMATOPOEIA.pick_random()
	await get_tree().create_timer(delay).timeout
	l_sound.visible = true
	await get_tree().create_timer(duration).timeout
	left_stop()

# offset is percent of screen height
func right_start(duration: float, delay: float = 0.0, y_offset: float = 0.0):
	r_sound.offset_left = randf_range(-50, 50) - r_sound.size.x / 2
	r_sound.offset_top = randf_range(-50, 50) + self.size.y * y_offset - r_sound.size.y / 2
	r_sound.rotation_degrees = randf_range(-20, 0)
	if r_sound is RichTextLabel:
		r_sound.text = "[i]" + R_ONOMATOPOEIA.pick_random() + "[/i]"
	else:
		r_sound.text = R_ONOMATOPOEIA.pick_random()
	await get_tree().create_timer(delay).timeout
	r_sound.visible = true
	await get_tree().create_timer(duration).timeout
	right_stop()
	
func left_stop():
	l_sound.visible = false

func right_stop():
	r_sound.visible = false
