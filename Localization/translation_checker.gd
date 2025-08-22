@tool
extends EditorScript

func _run():
	if get_scene() == null:
		print_rich("[color=red]You must open a scene to run the translation checker.[/color]");
		return;
	for node in get_all_children(get_scene()):
		if node is Label:
			var text = node.text;
			if !text.begins_with("TR_"):
				print_rich("- [color=yellow]Label: %s may be untranslated[/color]\n" % node.get_path());

func get_all_children(in_node, children_accumulater = []) -> Array:
	children_accumulater.push_back(in_node);
	for child in in_node.get_children():
		children_accumulater = get_all_children(child, children_accumulater);
	
	return children_accumulater;
