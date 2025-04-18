extends Node
class_name StateUI

var state_button  = preload("res://UI/StateButton/state_button.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.delete_states.connect(delete_all_states)
	Global.remake_states.connect(update_states)
	Global.reset_states.connect(initial_state)
	delete_all_states()
	initial_state()

func initial_state():
		
	add_state()

func _on_delete_state_pressed():
	if Global.settings_dict.states.size() > 1:
		
		var state_btn  = get_tree().get_nodes_in_group("StateButtons")
		
		InputMap.erase_action(state_btn[Global.current_state].input_key)
		
		
		state_btn[Global.current_state].queue_free()
		
		Global.settings_dict.saved_inputs.remove_at(Global.current_state)
		Global.settings_dict.states.remove_at(Global.current_state)
		Global.settings_dict.light_states.remove_at(Global.current_state)
		
		
		
		var sprites = get_tree().get_nodes_in_group("Sprites")
		for i in sprites:
			i.states.remove_at(Global.current_state)
		
		Global.current_state = 0
		Global.load_sprite_states(Global.current_state)
		
	update_state_numbering()

func update_state_numbering():
	
	await get_tree().create_timer(0.08).timeout
	
	var id = 0

	id = 0
	for i in get_tree().get_nodes_in_group("StateRemapButton"):
		if is_instance_valid(i):
			i.get_parent().get_node("State").text = "State " + str(id + 1)
		#	print(i.action)
			i.update_stuff()
			id += 1
			
			
	for i in get_tree().get_nodes_in_group("StateButtons"):
		if is_instance_valid(i):
			i.text = str(i.get_index() + 1)
			i.state = i.get_index()
		#	print(i.get_index())

func _on_add_state_pressed():
	add_state()
	Global.current_state = Global.settings_dict.states.size() - 1
	Global.load_sprite_states(Global.current_state)

func delete_all_states():
	Global.settings_dict.saved_inputs.clear()
	var state_remap = get_tree().get_nodes_in_group("StateRemapButton")
	var state_btn  = get_tree().get_nodes_in_group("StateButtons")
		
	for i in state_remap:
		if InputMap.has_action(i.action):
			InputMap.erase_action(i.action)
		i.get_parent().queue_free()
		
	for i in state_btn:
		i.queue_free()
		
	Global.settings_dict.states = []
	Global.settings_dict.light_states = [{}]
	

func add_state():
	var button = state_button.instantiate()
	var state_count = Global.settings_dict.states.size()
	button.state = state_count
	button.text = str(state_count + 1) 
	%StateButtons.add_child(button)
	InputMap.add_action(button.input_key)
	
	Global.settings_dict.states.append({
	mouth_closed = 0,
	mouth_open = 3,
	current_mc_anim = "Idle",
	current_mo_anim = "One Bounce",
	})
	
	Global.settings_dict.light_states.append({})
	
	state_count = get_tree().get_nodes_in_group("StateButtons").size()
	for i in get_tree().get_nodes_in_group("Sprites"):
		if i.states.size() != state_count:
			for l in abs(i.states.size() - state_count):
				i.states.append({})
	
	Global.settings_dict.saved_inputs.resize(Global.settings_dict.states.size())

func update_states(states):
	var states_size = states.size()
	for l in states_size:
		var button = state_button.instantiate()
		button.state = l 
		button.text = str(l + 1)
		%StateButtons.add_child(button)
		InputMap.add_action(button.input_key)
		var state_count = get_tree().get_nodes_in_group("StateButtons").size()
		for i in get_tree().get_nodes_in_group("Sprites"):
			if i.states.size() != state_count:
				for h in abs(i.states.size() - state_count):
					i.states.append({})

func _on_duplicate_state_pressed() -> void:
	var button = state_button.instantiate()
	var state_count = Global.settings_dict.states.size()
	button.state = state_count
	button.text = str(state_count + 1) 
	%StateButtons.add_child(button)
	InputMap.add_action(button.input_key)
	
	Global.settings_dict.states.append(Global.settings_dict.states[Global.current_state].duplicate())
	
	Global.settings_dict.light_states.append(Global.settings_dict.light_states[Global.current_state].duplicate())
	
	state_count = get_tree().get_nodes_in_group("StateButtons").size()
	for i in get_tree().get_nodes_in_group("Sprites"):
		if i.states.size() != state_count:
			for l in abs(i.states.size() - state_count):
				i.states.append(i.states[Global.current_state].duplicate())
	
	Global.settings_dict.saved_inputs.resize(Global.settings_dict.states.size())
