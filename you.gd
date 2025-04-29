class_name Player extends CharacterBody3D

@export_category("Player")
@export_range(1, 35, 1) var speed: float = 2 # m/s humans walk at like 1.4
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2

@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 * 3 # m
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1

var jumping: bool = false
var mouse_captured: bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

@onready var camera: Camera3D = $Camera

@onready var snowstep_l: AudioStreamPlayer3D = $snowstep_l
@onready var snowstep_r: AudioStreamPlayer3D = $snowstep_r

@onready var eye_ray: RayCast3D = $Camera/eyes

@onready var model: MeshInstance3D = $model

@onready var camera_placeholder: Node3D = $camera_pos


@export var sound_ui: Control



var camera_pos_offset: Vector3 = Vector3.ZERO
var camera_rot_offset: Vector3 = Vector3.ZERO

var next_camera_rot_offset: Vector3 = Vector3.ZERO

var delta_tracker: float = 0
var moving_delta_tracker: float = 0

var camera_true_y: float = 0


var look_accumulator: float = 0


@export_range(0.0, 5.0, 0.1) var dizzy: float = 1.0
@export_range(0.0, 2.0, 0.1) var limp: float = 0.9 # 0.8
@export_range(0.0, 2.0, 0.1) var step_bob: float = 0.8 #1.20 #* 2


var n = 0

var step: String = "none"
var holding: bool = false
var holdpos: Vector2 = Vector2.ZERO

var touch_environment: bool = false
var touch_accumulator: float = 0




var eyepos: Vector3 = Vector3(0, 0.441, 0)

var conversing: bool = false
var conversing_camera_transform



var dialog_scene = preload("res://dialog_control.tscn")


func _ready() -> void:
	capture_mouse()
	SignalBus.connect("_conversation", _conversation)


# snow curve?
# turn on turbulence
# up the FPS by a ton

func _conversation(is_conversing: bool):
	self.conversing = is_conversing
	if !self.conversing:
		capture_mouse()
		# POLISH 020: lerpy
		camera.transform = camera_placeholder.transform
		#camera.look_at(self.global_position + eyepos)
		#collider.trigger()


func recieve_event(is_conversing: bool):
	self.visible = is_conversing
	
func _exit_pressed():
	SignalBus._conversation.emit(false)


func capture_mouse() -> void:
	if conversing:
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true
	
func _process(_delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if conversing:
		return
		
	var collider = eye_ray.get_collider()
	Util.dg("lookin_at", collider)
	if eye_ray.is_colliding() and is_instance_of(collider, StaticBody3D) and (collider.name == "them"):
		look_accumulator += delta
		Util.dg("lk_accum", look_accumulator)
		if look_accumulator > .5:
			collider.lerp_look(self.global_position)
		if look_accumulator > 1 and not conversing:
			SignalBus._conversation.emit(true)
			release_mouse()
			#conversing_camera_transform = collider.get_transform()
			#	bool has_method( String arg0 ) const
			# POLISH 020: lerpy
			look_accumulator = 0
			camera.global_position = collider.camera_position()
			camera_placeholder.look_at(collider.camera_position())
			camera.look_at(self.global_position + eyepos)
			conversing = true
			
			
			var dialog = dialog_scene.instantiate()
			get_tree().root.add_child(dialog)
			
			# huh?? what is this
			collider.trigger()
	else:
		look_accumulator = 0
	
	
	
	if conversing:
		return

	if mouse_captured: _handle_joypad_camera_rotation(delta)
	velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	
	delta_tracker = delta_tracker + delta

		

	var vel = Vector3(velocity)
	vel.y = 0; #0 out y (up) component for xz velocity only
	var vel_mag = vel.length()

	if !is_on_floor():
		move_and_slide()
		return
	
	# Swaying in place
	if(vel_mag <= 0.000001):
		snowstep_l.stop()
		snowstep_r.stop()
		sound_ui.left_stop()
		sound_ui.right_stop()
		
		step = "none"
		moving_delta_tracker = 0
		var cycle_scale = 1
		
		var time_to_sway = .5
		if delta_tracker > time_to_sway:
			next_camera_rot_offset.z = dizzy * .5 * .04 * cos((delta_tracker-time_to_sway) * cycle_scale * PI / 4)
			
			# Smooths the transition from standing to swaying - cosine
			# Ratio approaches 1 as we near entering the regular cycle
			if delta_tracker-time_to_sway < 2.0/cycle_scale:
				var ratio = (delta_tracker-time_to_sway)/(2.0/cycle_scale)
				next_camera_rot_offset.z = lerp(camera_rot_offset.z, next_camera_rot_offset.z, lerp(0.0, ratio, .1))
			camera_pos_offset.x = dizzy * -2 * .04 * sin((delta_tracker-time_to_sway) * cycle_scale * PI / 4)
			camera_pos_offset.y = dizzy * -1 * .04 * sin((delta_tracker-time_to_sway) * cycle_scale * PI / 2)
		else:
			next_camera_rot_offset.z = lerp(camera_rot_offset.z, 0.0, .25)
			camera_pos_offset.x = lerp(camera_pos_offset.x, 0.0, .25)
			camera_pos_offset.y = lerp(camera_pos_offset.y, 0.0, .25)
	# Walking bob
	else:
		delta_tracker = 0
		if step == "none":
			step = "rpass"
		# 110 steps in 60 s
		# 55 steps in 30s
		# 11 steps in 6 s
		# Now we need to plug it into some sort of oscillating function, we'll stick with sine.
		moving_delta_tracker += delta
		# 2 * t * 4 * pi / 2 is like 12 steps in 6s!
		
		# left and right backwards????
		# look up how trig functions work again
		# full step body - one cycle will complete after two steps
		# one step body - one cycle will complete per step
		
		var one_c = speed * 4 * PI / 2
		var full_c = speed * 4 * PI / 4
		
		var bobOscillate = sin(one_c * moving_delta_tracker)
		var bobOscillate4 = sin(full_c * moving_delta_tracker)
		
		var period = 2 * PI / full_c # 1
		
		var stage = fmod(moving_delta_tracker, period)
		
		
		camera_pos_offset.x = .1 * step_bob * bobOscillate4
		camera_pos_offset.y = .05 * step_bob * bobOscillate
		next_camera_rot_offset.x = .01 * bobOscillate
		next_camera_rot_offset.z = step_bob * .5 * .04 * bobOscillate4
		

		if stage > period*15/16.0 or stage < period*1/16.0:
			step = "rpass"
		elif stage > period*1/16.0 and stage < period*3/16.0:
			step = "rhigh"
		elif stage > period*3/16.0 and stage < period*5/16.0:
			if step != "rcontact":
				#.85
				snowstep_r.pitch_scale = .85 + randf()/4
				snowstep_r.play()
				
			step = "rcontact"
		elif stage > period*5/16.0 and stage < period*7/16.0:
			if step != "rlow":
				var offset = min(0, self.camera.rotation_degrees.x)/450
				sound_ui.right_start(.60, .10, offset)
			step = "rlow"
		elif stage > period*7/16.0 and stage < period*9/16.0:
			step = "lpass"
		elif stage > period*9/16.0 and stage < period*11/16.0:
			step = "lhigh"
		elif stage > period*11/16.0 and stage < period*13/16.0:
			if step != "lcontact":
				#1.15
				snowstep_l.pitch_scale = 1.15 + randf()/4
				snowstep_l.play()
				
			step = "lcontact"
		elif stage > period*13/16.0 and stage < period*15/16.0:
			if step != "llow":
				var offset = min(0, self.camera.rotation_degrees.x)/450
				sound_ui.left_start(.37, .1, offset)
			step = "llow"


			
			
		if step.begins_with("l"):
			next_camera_rot_offset *= limp*2
			camera_pos_offset *= limp*1.5
			

	camera.transform.origin = camera.transform.basis * camera_pos_offset
	camera.rotation += (next_camera_rot_offset-camera_rot_offset)
	camera_rot_offset = next_camera_rot_offset
	
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.001
		if mouse_captured: _rotate_camera()
	if Input.is_action_just_pressed("ui_accept"): jumping = true
	if Input.is_action_just_pressed("ui_cancel"): release_mouse()
	if Input.is_action_just_pressed("click_screen"): capture_mouse()

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _rotate_camera(sens_mod: float = 1.0) -> void:
	camera.rotation.y -= look_dir.x * camera_sens * sens_mod
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens * sens_mod, -1.5, 1.5)
	model.rotation.y = camera.rotation.y
	

func _handle_joypad_camera_rotation(delta: float, sens_mod: float = 1.0) -> void:
	var joypad_dir: Vector2 = Input.get_vector("look_left","look_right","look_up","look_down")
	if joypad_dir.length() > 0:
		look_dir += joypad_dir * delta
		_rotate_camera(sens_mod)
		look_dir = Vector2.ZERO

func _walk(delta: float) -> Vector3:
	move_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if touch_environment:
		# should be Vector2.UP but equality doesn't quite work
		if move_dir.length() < .9:
			touch_accumulator = 0
			return Vector3.ZERO
		else:
			touch_accumulator += delta
			if touch_accumulator < .9:
				return Vector3.ZERO
		

	var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	return walk_vel

func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel

func _jump(delta: float) -> Vector3:
	if jumping:
		if is_on_floor(): jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
		jumping = false
		return jump_vel
	jump_vel = Vector3.ZERO if is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	return jump_vel
	
	
func _input(event):
	if event is InputEventScreenTouch:
		touch_environment = true
		if event.pressed:
			pass
			holdpos = event.position
	elif event is InputEventScreenDrag:
		touch_environment = true
	#Util.dg("touch?", touch_environment)
