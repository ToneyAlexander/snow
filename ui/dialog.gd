extends Control

@onready var exit: Button = $exit
@onready var logContainer: VBoxContainer = $logScroll/logContainer
@onready var scrollContainer: ScrollContainer = $logScroll

@onready var buttonBox: HFlowContainer = $options

var conversation = []

var dialog_tree: DialogState
var current_partner = ""

var thoughts_control = preload("res://ui/thoughts_control.tscn")
var thoughts_scene
	
	
func clear_children(node):
	for n in node.get_children():
		node.remove_child(n)
		n.queue_free()
	
func _ready() -> void:
	self.thoughts_scene = thoughts_control.instantiate()
	get_tree().root.add_child(thoughts_scene)
	
	SignalBus.connect("_conversation", recieve_conversing_event)
	exit.pressed.connect(_exit_pressed)
	
	#_render_choices()


func _render_choices():
	for choice in dialog_tree.choices.keys():
		var btn = Button.new()
		btn.pressed.connect(func(): _dialog_selected(btn))
		btn.text = choice
		buttonBox.add_child(btn)
	
	for d in dialog_tree.directions:
		SignalBus._think.emit(d)
	
	
func _dialog_selected(button: Button):
	#print("Pressed:", button.name)
	# remove the old buttons
	clear_children(buttonBox)
	# remove the old thoughts
	for d in dialog_tree.directions:
		SignalBus._think.emit(d)
	var choice = button.text
	# based on path, pick edge
	var edge = dialog_tree.choose(choice)
	# show edge response
	add_me(edge.response)
	# wait, show edge they say
	await get_tree().create_timer(1).timeout
	add_you(edge.they_say)
	# transition to next dialog state
	dialog_tree = edge.destination
	# if null, end, otherwise
	if dialog_tree != null:
		_render_choices()


func recieve_conversing_event(conversing: bool, partner: String):
	self.visible = conversing
	if conversing:
		current_partner = partner
		self.dialog_tree = WorldState.get_conversation(partner)
		self.conversation = []
		_render_choices()
	
func _exit_pressed():
	clear_children(buttonBox)
	clear_children(logContainer)
	get_tree().root.remove_child(thoughts_scene)
	thoughts_scene.queue_free()
	SignalBus._conversation.emit(false, current_partner)
	self.queue_free()

func bottom_scroll():
	call_deferred("bottom_scroll_def")
	#scrollContainer.scroll_vertical = scrollContainer.get_v_scroll_bar().max_value
	
func bottom_scroll_def():
	# double defferral
	# https://forum.godotengine.org/t/how-to-get-scrollbar-to-automatically-scroll-to-bottom/74013/7
	scrollContainer.scroll_vertical = scrollContainer.get_v_scroll_bar().max_value

func add_line(text: String, alignment: HBoxContainer.AlignmentMode):
	var ta = "left" if alignment == 0 else "right"
	var l = 0
	var r = 0
	if alignment == 0:
		r = 200
	else:
		l = 200
		
	conversation.append(text)
	var element = RichTextLabel.new()
	element.bbcode_enabled = true
	var box = HBoxContainer.new()
	var margin = MarginContainer.new()
	var margin_value = 20

	margin.add_theme_constant_override("margin_left", margin_value + l)
	margin.add_theme_constant_override("margin_bottom", margin_value)
	margin.add_theme_constant_override("margin_right", margin_value + r)

	box.alignment = alignment
	element.add_theme_constant_override("outline_size", 18)
	element.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	element.fit_content = true
	margin.custom_minimum_size = Vector2(scrollContainer.size.x - 10, 0)
	box.custom_minimum_size = Vector2(scrollContainer.size.x - 10, 0)
	
	element.append_text("[" + ta + "]" + text + "[/" + ta + "]")
	margin.add_child(element)
	box.add_child(margin)
	logContainer.add_child(box)
	call_deferred("bottom_scroll")

func add_me(text: String):
	add_line(text, BoxContainer.ALIGNMENT_END)
	
func add_you(text: String):
	add_line(text, BoxContainer.ALIGNMENT_BEGIN)
