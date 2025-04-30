extends Control

func _ready() -> void:
	SignalBus.connect("_conversation", recieve_event) 

func recieve_event(conversing: bool, partner: String):
	self.visible = !conversing
