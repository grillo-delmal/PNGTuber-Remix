extends Node
class_name GlobalCalculations

static func is_nan_or_inf(value, should_be_one = false):
	if (value is int) or (value is float):
		if is_inf(value):
			if should_be_one:
				value = 1.0
			else:
				value = 0.0
		if is_nan(value):
			if should_be_one:
				value = 1.0
			else:
				value = 0.0
		return value
		
	elif (value is Vector2) or (value is Vector2i):
		if is_inf(value.x):
			if should_be_one:
				value.x = 1.0
			else:
				value.x = 0.0
		if is_nan(value.x):
			if should_be_one:
				value.x = 1.0
			else:
				value.x = 0.0
		if is_inf(value.y):
			if should_be_one:
				value.y = 1.0
			else:
				value.y = 0.0
		if is_nan(value.y):
			if should_be_one:
				value.y = 1.0
			else:
				value.y = 0.0
		return value
	else:
		return value

static func clamp_angle(value: float, min_angle: float, max_angle: float, rest: float = 0.0) -> float:
	var v = value + rest
	var n = min_angle + rest
	var m = max_angle + rest
	if n <= m:
		if v < n: return n
		if v > m: return m
		return v
	else:
		if v > m and v < n:
			var dist_min = abs(_get_distance(v, n))
			var dist_max = abs(_get_distance(v, m))
			return n if dist_min < dist_max else m
		return v

static func _get_distance(a: float, b: float) -> float:
	return a - b

static func some_keyboard_calc_wasd(type_name : String = "follow_type", actor : Node = null) -> Vector2:
	var normal = Vector2(0.0, 0.0)
	if actor.get_value(type_name) in [3,4,5]:
		var ws : Vector2 = Vector2.ZERO
		var ad : Vector2 = Vector2.ZERO
		if InputMap.action_get_events("KeyMovementW")[0].as_text() in GlobalInputCapture.already_input_keys:
			ws.y = 1.0
		if InputMap.action_get_events("KeyMovementS")[0].as_text() in GlobalInputCapture.already_input_keys:
			ws.x = 1.0
		if InputMap.action_get_events("KeyMovementA")[0].as_text() in GlobalInputCapture.already_input_keys:
			ad.y = 1.0
		if InputMap.action_get_events("KeyMovementD")[0].as_text() in GlobalInputCapture.already_input_keys:
			ad.x = 1.0
		
		if actor.get_value(type_name) == 3:
			normal = Vector2(ws.x - ws.y, ws.x - ws.y)
		elif actor.get_value(type_name) == 4:
			normal = Vector2(ad.x - ad.y, ad.x - ad.y)
		elif actor.get_value(type_name) == 5:
			normal = Vector2(ad.x - ad.y, ws.x - ws.y)
	
	elif actor.get_value(type_name) in [6,7,8]:
		var ws : Vector2 = Vector2.ZERO
		var ad : Vector2 = Vector2.ZERO
		if InputMap.action_get_events("KeyMovementW")[1].as_text() in GlobalInputCapture.already_input_keys:
			ws.y = 1.0
		if InputMap.action_get_events("KeyMovementS")[1].as_text() in GlobalInputCapture.already_input_keys:
			ws.x = 1.0
		if InputMap.action_get_events("KeyMovementA")[1].as_text() in GlobalInputCapture.already_input_keys:
			ad.y = 1.0
		if InputMap.action_get_events("KeyMovementD")[1].as_text() in GlobalInputCapture.already_input_keys:
			ad.x = 1.0

		if actor.get_value(type_name) == 6:
			normal = Vector2(ws.x - ws.y, ws.x - ws.y)
		elif actor.get_value(type_name) == 7:
			normal = Vector2(ad.x - ad.y, ad.x - ad.y)
		elif actor.get_value(type_name) == 8:
			normal = Vector2(ad.x - ad.y, ws.x - ws.y)

	return normal

static func follow_type_helper(type_name : String = "follow_type", actor : Node = null, type : String = "position", axis_left : Vector2 = Vector2.ZERO, axis_right: Vector2 = Vector2.ZERO):
	var dist : float = 0.0
	var selected_axis = Vector2.ZERO
	if type == "position":
		if actor.get_value(type_name) == 1:
			if actor.get_value("snap_pos"):
				if axis_left.x != 0:
					actor.target_x = lerp(actor.target_x, axis_left.x * actor.get_value("look_at_mouse_pos"),actor.get_value("mouse_delay"))
				if axis_left.y != 0 && actor.get_value("snap_pos"):
					actor.target_y = lerp(actor.target_y, axis_left.y * actor.get_value("look_at_mouse_pos_y"), actor.get_value("mouse_delay"))
			else:
				actor.target_x = actor.axis_left.x * actor.get_value("look_at_mouse_pos")
				actor.target_y = actor.axis_left.y * actor.get_value("look_at_mouse_pos_y")
			dist = Vector2(actor.target_x, actor.target_y).length()
			selected_axis = axis_left
		if actor.get_value(type_name) == 2:
			if actor.get_value("snap_pos"):
				if axis_right.x != 0:
					actor.target_x = lerp(actor.target_x, axis_right.x * actor.get_value("look_at_mouse_pos"),actor.get_value("mouse_delay"))
				if axis_right.y != 0 && actor.get_value("snap_pos"):
					actor.target_y = lerp(actor.target_y, axis_right.y * actor.get_value("look_at_mouse_pos_y"), actor.get_value("mouse_delay"))
			else:
				actor.target_x = actor.axis_right.x * actor.get_value("look_at_mouse_pos")
				actor.target_y = actor.axis_right.y * actor.get_value("look_at_mouse_pos_y")
			dist = Vector2(actor.target_x, actor.target_y).length()
			selected_axis = axis_right
		
		return {axis = selected_axis, dist = dist}

	if type == "angle":
		if actor.get_value(type_name) == 1:
			if actor.get_value("snap_rot"):
				if !axis_left.is_zero_approx():
					actor.target_rotation_axis = actor.target_rotation_axis.lerp(axis_left, 0.15)
			else:
				actor.target_rotation_axis = axis_left
			selected_axis = axis_left
		if actor.get_value(type_name) == 2:
			if actor.get_value("snap_rot"):
				if !axis_right.is_zero_approx():
					actor.target_rotation_axis = actor.target_rotation_axis.lerp(axis_right, 0.15)
			else:
				actor.target_rotation_axis = axis_right
			selected_axis = axis_right

	if type == "scale":
		if actor.get_value(type_name) == 1:
			if actor.get_value("snap_scale"):
				if axis_left.is_zero_approx():
					actor.target_scale_axis = actor.target_scale_axis.lerp(axis_left, 0.15)
			else:
				actor.target_scale_axis = axis_left
			selected_axis = axis_left
		if actor.get_value(type_name) == 2:
			if actor.get_value("snap_scale"):
				if axis_right.is_zero_approx():
					actor.target_scale_axis = actor.target_scale_axis.lerp(axis_right, 0.15)
			else:
				actor.target_scale_axis = axis_left
			selected_axis = axis_right
