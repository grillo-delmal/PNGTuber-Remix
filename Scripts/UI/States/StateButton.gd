extends Button
class_name StateButton

@export var state : int 
@export var input_key : String = str(randi())
var saved_event : InputEvent
var state_name : String 
static var selected_state : Button = null

func _ready():
	if state_name.is_empty():
		state_name = str(state+1)
	text = state_name
	if state == 0:
		select_state()
	Global.key_pressed.connect(bg_key_pressed)

func _on_pressed():
	select_state()
	Global.get_sprite_states(state)
#	print(state)

func initial_update():
	Global.get_sprite_states(state)

func select_state():
	if selected_state != null && is_instance_valid(selected_state):
		selected_state.get_node("%Selected").hide()
	selected_state = self
	%Selected.show()


func _input(event):
	if input_key != "Null" or input_key != "":
		if InputMap.has_action(input_key):
			if event.is_action_pressed(input_key):
				select_state()
				Global.get_sprite_states(state)

func bg_key_pressed(key):
	if InputMap.action_get_events(input_key).size() > 0:
		var inputs = InputMap.action_get_events(input_key)[0]
		if key == inputs.as_text():
			select_state()
			Global.get_sprite_states(state)

func update_stuff():
	if saved_event != null:
		InputMap.action_erase_events(input_key)
		InputMap.action_add_event(input_key, saved_event)
