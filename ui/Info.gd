extends Label

@export var registered_order = ["TT1", "bbb"]
var registered_set = {}
var registered_data = {}

var unregistered_order = []
var unregistered_data = {}

var base_size = 15

func _ready() -> void:
	for item in registered_order:
		registered_set[item] = null
	SignalBus.connect("_debug_display", recieve_event)
	get_viewport().size_changed.connect(screen_size_changed)
	screen_size_changed()


func screen_size_changed():
	self.label_settings.font_size = int(base_size * Util.get_composite_text_scale())
	refresh()


func recieve_event(tag: String, input_value):
	var value = str(input_value)
	if registered_set.has(tag):
		registered_data[tag] = value
	else:
		if not unregistered_data.has(tag):
			unregistered_order.append(tag)
			unregistered_order.sort()
		unregistered_data[tag] = value
	refresh()
	

func refresh():
	var result = ""
	for tag in registered_order:
		if registered_data.has(tag):
			result += tag + ": " + registered_data[tag] + "\n"
	for tag in unregistered_order:
		result += tag + ": " + unregistered_data[tag] + "\n"
	self.text = result
