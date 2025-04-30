extends Node


func get_conversation(partner: String):
	if partner == "them":
		pass
	return build()

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
