@tool
class_name DialogBox extends Control

const dialog_box: PackedScene = preload("res://ui/dialog_box.tscn")

var margin: MarginContainer
var speech: RichTextLabel

var base_size = 15

@export var alignment: HBoxContainer.AlignmentMode :
	set(value):
		alignment = value
		_update_fields()

var align_bbcode = {
	0: "left",
	1: "center",
	2: "right",
}

@export var text: String = "Default Text" :
	set(value):
		text = value
		_update_fields()

func _ready():
	_update_fields()
	get_viewport().size_changed.connect(screen_size_changed)
	screen_size_changed()


func screen_size_changed():
	if speech and not Engine.is_editor_hint():
		self.speech.add_theme_font_size_override("normal_font_size", int(15 * Util.get_composite_text_scale()))


func _update_fields():
	if not is_inside_tree():
		return

	margin = get_node_or_null("margin")
	speech = get_node_or_null("margin/speech")
	if speech:
		var ta = align_bbcode.get(alignment)
		speech.clear()
		speech.append_text("[" + ta + "]" + text + "[/" + ta + "]")

		var l = 200
		var r = 200
		if alignment == 0:
			l = 0
		elif alignment == 2:
			r = 0

		margin.add_theme_constant_override("margin_left", l + 20)
		margin.add_theme_constant_override("margin_right", r + 20)

		var sx = get_parent().size.x

		self.custom_minimum_size = Vector2(sx - 10, 0)
		margin.custom_minimum_size = Vector2(sx - 10, 0)
