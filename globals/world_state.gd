extends Node


var all_trees = preload("res://dialog/SCRIPT.tres")


func get_conversation(partner: String):
	if partner in all_trees.trees:
		return all_trees.trees[partner]
	return null
