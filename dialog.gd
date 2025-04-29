extends Control

@onready var exit: Button = $exit
@onready var logContainer: VBoxContainer = $logScroll/logContainer
@onready var scrollContainer: ScrollContainer = $logScroll

@onready var buttonBox: HFlowContainer = $options
@onready var op1: Button = $options/op1
@onready var op2: Button = $options/op2

var conversation = []

var dialog_tree: DialogState

var thoughts_control = preload("res://thoughts_control.tscn")
var thoughts_scene


class DialogState extends RefCounted:
	var you: bool = true
	var directions: Array[String] = []
	var choices: Dictionary[String, DialogEdge] = {}
	
	func _init(p_directions: Array[String], p_choices: Dictionary[String, DialogEdge], p_you = true):
		self.you = p_you
		self.directions = p_directions
		self.choices = p_choices
		
	func choose(choice: String) -> DialogEdge:
		return self.choices.get(choice)
	
class DialogEdge:
	var response: String
	var they_say: String
	var destination: DialogState
	
	func _init(p_response, p_they_say, p_destination):
		self.response = p_response
		self.they_say = p_they_say
		self.destination = p_destination
	
	
func clear_children(node):
	for n in node.get_children():
		node.remove_child(n)
		n.queue_free()
	
func _ready() -> void:
	self.thoughts_scene = thoughts_control.instantiate()
	get_tree().root.add_child(thoughts_scene)
	
	SignalBus.connect("_conversation", recieve_event)
	exit.pressed.connect(_exit_pressed)
	
	dialog_tree = build()
	_render_choices()


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


func recieve_event(conversing: bool):
	self.visible = conversing
	if conversing:
		self.dialog_tree = build()
		self.conversation = []
		_render_choices()
	
func _exit_pressed():
	clear_children(buttonBox)
	clear_children(logContainer)
	get_tree().root.remove_child(thoughts_scene)
	thoughts_scene.queue_free()
	SignalBus._conversation.emit(false)
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
	margin.custom_minimum_size = Vector2(scrollContainer.size.x-10, 0)
	box.custom_minimum_size = Vector2(scrollContainer.size.x-10, 0)
	
	element.append_text("[" + ta + "]" + text + "[/" + ta + "]")
	margin.add_child(element)
	box.add_child(margin)
	logContainer.add_child(box)
	call_deferred("bottom_scroll")

func add_me(text: String):
	add_line(text, BoxContainer.ALIGNMENT_END)
	
func add_you(text: String):
	add_line(text, BoxContainer.ALIGNMENT_BEGIN)
	

func build() -> DialogState:
	var branch1 = DialogState.new(["dir1", "dir2"], {
		"short a": DialogEdge.new(
			"A EXPANDED", "A RESPONSE", null
		), "short b": DialogEdge.new(
			"B EXPANDED", "B RESPONSE", null
		)
	})
	
	var branch2 = DialogState.new(["all roads lead to rome?", "tu ne cede malis..."], {
		"Duis aute": DialogEdge.new(
			"Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.", "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.", branch1
		)
	})
	
	var root = DialogState.new(["🤔", "chilly", "Thea..."], {
		"opta": DialogEdge.new(
			"opta long response", "all roads lead to rome", branch1
		), "Lorem ipsum dolor...": DialogEdge.new(
			"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.", "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.", branch2
		)
	})
	return root


	
