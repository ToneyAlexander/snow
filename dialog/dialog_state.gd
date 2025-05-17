extends Resource
class_name DialogState

@export var speaker: String
@export var directions: Array[String] = []

@export var choices: Array[String] = []
@export var short_choices: Array[String] = []
@export var states: Array[DialogState] = []

@export var side_effects: Array[Variant] = []

var history = [] # Array[Tuple[String, String]]

static func create(
	_speaker: String,
	_directions: Array[String] = [],
	_short_choices: Array[String] = [],
	_choices: Array[String] = [],
	_states: Array[DialogState] = [],
	_side_effects: Array[Variant] = [],
) -> DialogState:
	var n: DialogState = DialogState.new()
	n.speaker = _speaker
	n.directions = _directions
	n.choices = _choices
	n.short_choices = _short_choices
	n.states = _states
	n.side_effects = _side_effects
	return n
	
