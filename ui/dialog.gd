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

func execute_tree():
	if dialog_tree == null || dialog_tree.choices.size() == 0 || dialog_tree.speaker == "TERMINUS":
		return

	if dialog_tree.speaker == current_partner:
		for i in range(dialog_tree.short_choices.size()):
			var btn = Button.new()
			btn.pressed.connect(func(): _dialog_selected(i))
			btn.text = dialog_tree.short_choices[i]
			buttonBox.add_child(btn)
		
		for d in dialog_tree.directions:
			SignalBus._think.emit(d)
	else:
		await get_tree().create_timer(1).timeout
		var i = randi_range(0, dialog_tree.choices.size() - 1)
		add_speech(dialog_tree.speaker, dialog_tree.choices[i])
		dialog_tree = dialog_tree.states[i]
		execute_tree()
	
	
func _dialog_selected(index: int):
	# remove the old buttons
	clear_children(buttonBox)
	# remove the old thoughts
	for d in dialog_tree.directions:
		SignalBus._think.emit(d)
	# show selected option
	add_speech(dialog_tree.speaker, dialog_tree.choices[index])
	# advance the tree
	if dialog_tree.states.size() == 0:
		return
	dialog_tree = dialog_tree.states[index]

	execute_tree()


func recieve_conversing_event(conversing: bool, partner: String):
	self.visible = conversing
	if conversing:
		# Partner is the person who was looked at
		# AKA not Eucl
		current_partner = partner
		self.dialog_tree = WorldState.get_conversation(partner)
		if self.dialog_tree == null:
			clear_ui()
		else:
			for entry in self.dialog_tree.history:
				add_speech(entry[0], entry[1])
			execute_tree()
	
func _exit_pressed():
	# Store conversation history in the node, or add a TERMINUS node for storage
	if self.dialog_tree == null:
		self.dialog_tree = DialogState.create("TERMINUS")
	self.dialog_tree.history = conversation
	WorldState.all_trees.trees[current_partner] = self.dialog_tree
	clear_ui()

func clear_ui():
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


func add_speech(speaker: String, text: String):
	conversation.append([speaker, text])
	if speaker == current_partner:
		add_line(text, BoxContainer.ALIGNMENT_END)
	else:
		add_line(text, BoxContainer.ALIGNMENT_BEGIN)

func add_line(text: String, alignment: HBoxContainer.AlignmentMode):
	var ta = "left" if alignment == 0 else "right"
	var l = 0
	var r = 0
	if alignment == 0:
		r = 200
	else:
		l = 200
		
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
