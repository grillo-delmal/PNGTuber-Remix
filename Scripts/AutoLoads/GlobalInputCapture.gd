extends BackgroundInputCapture

var keys : Array = []
var already_input_keys : Array = []

func _ready() -> void:
	bg_key_pressed.connect(_on_background_input_capture_bg_key_pressed)

func _on_background_input_capture_bg_key_pressed(_node, keys_pressed : Dictionary):
	if Global.settings_dict.checkinput:
		var keyStrings = []
		var costumeKeys = []
		
		for l in get_tree().get_nodes_in_group("StateButtons"):
			if InputMap.action_get_events(l.input_key).size() > 0:
				costumeKeys.append(InputMap.action_get_events(l.input_key)[0].as_text())
				
		for l in Global.settings_dict.cycles:
			if l.toggle != null:
				costumeKeys.append(l.toggle.as_text())
			if l.forward != null:
				costumeKeys.append(l.forward.as_text())
				
			if l.backward != null:
				costumeKeys.append(l.backward.as_text())
				
				
		for l in get_tree().get_nodes_in_group("Sprites"):
			if InputMap.action_get_events(str(l.sprite_id)).size() > 0:
				costumeKeys.append(InputMap.action_get_events(str(l.sprite_id))[0].as_text())
			for j in l.saved_keys:
				costumeKeys.append(j)
		
		for i in keys_pressed:
			if keys_pressed[i]:
				if OS.get_keycode_string(i) not in already_input_keys:
					keyStrings.append(OS.get_keycode_string(i))
					
		
		already_input_keys = keyStrings
		
		if Global.file_dialog != null && is_instance_valid(Global.file_dialog):
			if Global.file_dialog.visible:
				return
			
		
		for key in keyStrings:
			var e = InputEventKey.new()
			e.keycode = OS.find_keycode_from_string(key)
			e.alt_pressed = keys_pressed.get(KEY_ALT, false)
			e.shift_pressed = keys_pressed.get(KEY_SHIFT, false)
			e.ctrl_pressed = keys_pressed.get(KEY_CTRL, false)
			e.meta_pressed = keys_pressed.get(KEY_META, false)
			var i = costumeKeys.find(e.as_text())
			if i >= 0:
				if costumeKeys[i] not in keys:
				#	print(keys)
				#	print(costumeKeys[i])
					Global.key_pressed.emit(costumeKeys[i])
					keys.append(costumeKeys[i])
	
	keys = []
