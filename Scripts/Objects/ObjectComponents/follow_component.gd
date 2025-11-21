extends Node

@export var actor: SpriteObject
@export var modifier: Node2D

# --- Internal state ---
var last_mouse_position := Vector2.ZERO
var smoothed_dir := Vector2.ZERO
var vel := Vector2.ZERO
var last_dist := Vector2.ZERO

var frame_h := 0.0
var frame_v := 0.0

var target_x := 0.0
var target_y := 0.0
var target_rotation := Vector2.ZERO
var target_scale := Vector2.ONE

var rest := false

func _ready() -> void:
	pass
	#Global.update_mouse_vel_pos.connect(mouse_delay)

func _physics_process(delta: float) -> void:
	if Global.static_view and actor.rest_mode == 5:
		return

	if actor.rest_mode in [1,3] and rest:
		reset_modifier()
	else:
		process_follow(delta)

	last_mouse_position = actor.get_local_mouse_position()

func reset_modifier() -> void:
	modifier.position = Vector2.ZERO
	modifier.rotation = 0.0
	modifier.scale = Vector2.ONE

# --- Main follow loop ---
func process_follow(delta: float) -> void:
	var mouse_pos = get_mouse_position_local()
	var dist_vec = mouse_pos
	var dist_len = dist_vec.length()
	var dir = Vector2.ZERO
	if dist_len > 0.00001:
		dir = dist_vec / dist_len

	update_velocity(delta, mouse_pos, dist_vec)
	update_controller_inputs()
	update_position(dir, dist_len, delta)
	update_rotation(dir, delta)
	update_scale(dir, delta)
	update_sprite_animation(dir, dist_len, delta)

# --- Mouse input ---
func get_mouse_position_local() -> Vector2:
	var main_marker = Global.main.get_node("%Marker")
	var mouse_coords : Vector2 = Vector2.ZERO
	if main_marker.current_screen != main_marker.ALL_SCREENS:
		if !main_marker.mouse_in_current_screen() && Global.settings_dict.snap_out_of_bounds:
			mouse_coords = Vector2.ZERO
		else:
			var viewport_size = actor.get_viewport().size
			var origin = actor.sprite_object.get_global_transform_with_canvas().origin
			var x_per = 1.0 - origin.x/float(viewport_size.x)
			var y_per = 1.0 - origin.y/float(viewport_size.y)
			var offset = Vector2( x_per, y_per)
			var mouse_pos = actor.sprite_object.get_local_mouse_position()
			mouse_coords = Vector2(mouse_pos - Vector2(DisplayServer.screen_get_position(main_marker.current_screen))) + offset 
	else:
		mouse_coords = actor.sprite_object.get_local_mouse_position()
	return mouse_coords

func update_velocity(_delta: float, mouse_pos: Vector2, dist_vec: Vector2) -> void:
	if !actor.get_value("follow_mouse_velocity"):
		return
	var mouse_delta = mouse_pos - last_mouse_position
	if mouse_delta.length() < 0.5:
		return
	var look = Vector2(actor.get_value("look_at_mouse_pos"), actor.get_value("look_at_mouse_pos_y"))
	vel = lerp(vel, -look * dist_vec, 0.15)
	var vel_len = vel.length()
	if vel_len > 0.001:
		var dir_vel = vel / vel_len
		var dist_vel = min(vel_len, look.length())
		last_dist = dir_vel * dist_vel
		smoothed_dir = dir_vel

# --- Controller / keyboard input ---
var axis_left := Vector2.ZERO
var axis_right := Vector2.ZERO
var axis_shoulderl := Vector2.ZERO
var axis_shoulderr := Vector2.ZERO
var axis_lr_3 := Vector2.ZERO

func update_controller_inputs() -> void:
	axis_left = Input.get_vector("ControllerLeft", "ControllerRight", "ControllerUp", "ControllerDown")
	axis_right = Input.get_vector("ControllerFour", "ControllerTwo", "ControllerOne", "ControllerThree")
	axis_shoulderl = Input.get_vector("ShoulderL1", "ShoulderR1", "ShoulderL1", "ShoulderR1")
	axis_shoulderr = Input.get_vector("ShoulderL2", "ShoulderR2", "ShoulderL2", "ShoulderR2")
	axis_lr_3 = Input.get_vector("L3", "R3", "L3", "R3")

func update_position(dir: Vector2, dist: float, _delta: float) -> void:
	var target_pos = Vector2.ZERO
	var follow_type = actor.get_value("follow_type")
	var keyboard_axis := Vector2.ZERO

	if follow_type in [3,4,5,6,7,8]:
		keyboard_axis = GlobalCalculations.some_keyboard_calc_wasd("follow_type", actor)

	if follow_type == 0:
		if actor.get_value("follow_mouse_velocity"):
			target_pos = last_dist
		else:
			target_pos = Vector2(dir.x * min(dist, actor.get_value("look_at_mouse_pos")),dir.y * min(dist, actor.get_value("look_at_mouse_pos_y")))
	elif follow_type == 1:
		target_pos = Vector2(axis_left.x * actor.get_value("look_at_mouse_pos"),axis_left.y * actor.get_value("look_at_mouse_pos_y"))
	elif follow_type == 2:
		target_pos = Vector2(axis_right.x * actor.get_value("look_at_mouse_pos"),axis_right.y * actor.get_value("look_at_mouse_pos_y"))
	elif follow_type == 10:
		target_pos = Vector2(axis_shoulderl.x * actor.get_value("look_at_mouse_pos"),axis_shoulderl.y * actor.get_value("look_at_mouse_pos_y"))
	elif follow_type == 11:
		target_pos = Vector2(axis_shoulderr.x * actor.get_value("look_at_mouse_pos"),axis_shoulderr.y * actor.get_value("look_at_mouse_pos_y"))
	elif follow_type == 12:
		target_pos = Vector2(axis_lr_3.x * actor.get_value("look_at_mouse_pos"),axis_lr_3.y * actor.get_value("look_at_mouse_pos_y"))
	elif follow_type in [3,4,5,6,7,8]:
		if actor.get_value("snap_pos"):
			if keyboard_axis.x != 0:
				target_x = lerp(target_x, keyboard_axis.x * actor.get_value("look_at_mouse_pos"), actor.get_value("mouse_delay"))
			if keyboard_axis.y != 0:
				target_y = lerp(target_y, keyboard_axis.y * actor.get_value("look_at_mouse_pos_y"), actor.get_value("mouse_delay"))
		else:
			target_x = keyboard_axis.x * actor.get_value("look_at_mouse_pos")
			target_y = keyboard_axis.y * actor.get_value("look_at_mouse_pos_y")
		target_pos = Vector2(target_x, target_y)
	else:
		target_pos = Vector2(dir.x * min(dist, actor.get_value("look_at_mouse_pos")),dir.y * min(dist, actor.get_value("look_at_mouse_pos_y")))

	modifier.position.x = GlobalCalculations.is_nan_or_inf(lerp(modifier.position.x, target_pos.x, actor.get_value("mouse_delay")))
	modifier.position.y = GlobalCalculations.is_nan_or_inf(lerp(modifier.position.y, target_pos.y, actor.get_value("mouse_delay")))


func update_rotation(dir: Vector2, delta: float) -> void:
	var target_rot = 0.0
	var follow_type2 = actor.get_value("follow_type2")
	var keyboard_axis := Vector2.ZERO

	if follow_type2 in [3,4,5,6,7,8]:
		keyboard_axis = GlobalCalculations.some_keyboard_calc_wasd("follow_type2", actor)
		if actor.get_value("snap_rot") and not keyboard_axis.is_zero_approx():
			target_rotation = target_rotation.lerp(keyboard_axis, 0.15)
		else:
			target_rotation = keyboard_axis

	if follow_type2 == 0:
		var normalized_mouse = clamp(-smoothed_dir.x / 2.0, -1.0, 1.0)
		if smoothed_dir.length() < 0.1:
			normalized_mouse = clamp(dir.x, -1.0, 1.0)
		var rotation_factor = lerp(actor.get_value("mouse_rotation"), actor.get_value("mouse_rotation_max"), max(abs(normalized_mouse), 0.01))
		var safe_rot_min = clamp(actor.get_value("rLimitMin"), -360, 360)
		var safe_rot_max = clamp(actor.get_value("rLimitMax"), -360, 360)
		target_rot = clamp(normalized_mouse * rotation_factor * deg_to_rad(90), deg_to_rad(safe_rot_min), deg_to_rad(safe_rot_max))
		
	elif follow_type2 == 1:
		target_rot = lerp(actor.get_value("mouse_rotation"), actor.get_value("mouse_rotation_max"), abs(axis_left.x))
	elif follow_type2 == 2:
		target_rot = lerp(actor.get_value("mouse_rotation"), actor.get_value("mouse_rotation_max"), abs(axis_right.x))
	elif follow_type2 == 10:
		target_rot = lerp(actor.get_value("mouse_rotation"), actor.get_value("mouse_rotation_max"), abs(axis_shoulderl.x))
	elif follow_type2 == 11:
		target_rot = lerp(actor.get_value("mouse_rotation"), actor.get_value("mouse_rotation_max"), abs(axis_shoulderr.x))
	elif follow_type2 == 12:
		target_rot = lerp(actor.get_value("mouse_rotation"), actor.get_value("mouse_rotation_max"), abs(axis_lr_3.x))
	elif follow_type2 in [3,4,5,6,7,8]:
		target_rot = lerp(actor.get_value("mouse_rotation"), actor.get_value("mouse_rotation_max"), abs(target_rotation.x))
	else:
		target_rot = lerp(actor.get_value("mouse_rotation"), actor.get_value("mouse_rotation_max"), abs(dir.x))

	var rot_min = deg_to_rad(clamp(actor.get_value("rLimitMin"), -360, 360))
	var rot_max = deg_to_rad(clamp(actor.get_value("rLimitMax"), -360, 360))
	target_rot = clamp(target_rot, rot_min, rot_max)
	modifier.rotation = lerp_angle(modifier.rotation, target_rot, 1.0 - pow(1.0 - actor.get_value("mouse_delay"), delta * 60.0))




func update_scale(dir: Vector2, delta: float) -> void:
	var x_val = abs(dir.x)
	var y_val = abs(dir.y)
	var follow_type3 = actor.get_value("follow_type3")
	var keyboard_axis := Vector2.ZERO

	if follow_type3 in [3,4,5,6,7,8]:
		keyboard_axis = GlobalCalculations.some_keyboard_calc_wasd("follow_type3", actor)
		if actor.get_value("snap_scale") and not keyboard_axis.is_zero_approx():
			target_scale = target_scale.lerp(keyboard_axis, 0.15)
		else:
			target_scale = keyboard_axis

	if follow_type3 == 0:
		x_val = abs(dir.x)
		y_val = abs(dir.y)
	elif follow_type3 == 1:
		x_val = abs(axis_left.x)
		y_val = abs(axis_left.y)
	elif follow_type3 == 2:
		x_val = abs(axis_right.x)
		y_val = abs(axis_right.y)
	elif follow_type3 == 10:
		x_val = abs(axis_shoulderl.x)
		y_val = abs(axis_shoulderl.y)
	elif follow_type3 == 11:
		x_val = abs(axis_shoulderr.x)
		y_val = abs(axis_shoulderr.y)
	elif follow_type3 == 12:
		x_val = abs(axis_lr_3.x)
		y_val = abs(axis_lr_3.y)
	elif follow_type3 in [3,4,5,6,7,8]:
		x_val = abs(target_scale.x)
		y_val = abs(target_scale.y)

	var target_sx = lerp(1.0, 1.0 - actor.get_value("mouse_scale_x"), x_val)
	var target_sy = lerp(1.0, 1.0 - actor.get_value("mouse_scale_y"), y_val)
	var t = 1.0 - pow(1.0 - actor.get_value("mouse_delay"), delta * 60.0)
	modifier.scale.x = lerp(modifier.scale.x, target_sx, t)
	modifier.scale.y = lerp(modifier.scale.y, target_sy, t)

func update_sprite_animation(dir: Vector2, dist: float, _delta: float) -> void:
	if actor.sprite_type != "Sprite2D" or not actor.get_value("non_animated_sheet") or not actor.get_value("animate_to_mouse"):
		return
	var dist_x = dir.x * min(dist, actor.get_value("look_at_mouse_pos"))
	var dist_y = dir.y * min(dist, actor.get_value("look_at_mouse_pos_y"))
	var hframes = %Sprite2D.hframes
	var vframes = %Sprite2D.vframes
	var normalized_x = (dist_x / (2.0 * actor.get_value("look_at_mouse_pos"))) + 0.5
	var normalized_y = (dist_y / (2.0 * actor.get_value("look_at_mouse_pos_y"))) + 0.5
	var frame_x = clamp(floor(normalized_x * hframes), 0, hframes - 1)
	var frame_y = clamp(floor(normalized_y * vframes), 0, vframes - 1)
	frame_h = move_toward(frame_h, frame_x, actor.get_value("animate_to_mouse_speed"))
	frame_v = move_toward(frame_v, frame_y, actor.get_value("animate_to_mouse_speed"))
	%Sprite2D.frame_coords.x = floor(frame_h)
	%Sprite2D.frame_coords.y = floor(frame_v)
