extends Node

@export var actor: SpriteObject

var glob: Vector2 = Vector2.ZERO
var vel = Vector2.ZERO
var distance: Vector2 = Vector2.ZERO
var applied_pos = Vector2.ZERO
var applied_rotation = 0.0
var applied_scale = Vector2.ONE
var placeholder_position: Vector2 = Vector2.ZERO
var prev_smoothed_pos: Vector2 = Vector2.ZERO
var has_prev = false
var rot_drag: float = 0.0
var follow_point_rot: float = 0.0
var biased: float = 0.0
var strength = 0.0
var _b: float = 0.0
var dragger_global := Vector2.ZERO
var last_wobble_pos := Vector2.ZERO
var paused_wobble := Vector2.ZERO
var paused_rotation: float = 0.0
var last_rot: float = 0.0
var rest: bool = false
var should_rot_rotation : float = 0.0

func _ready() -> void:
	# Initialize placeholder and applied positions
	placeholder_position = %Modifier1.global_position
	dragger_global = placeholder_position
	applied_pos = placeholder_position
	applied_rotation = 0.0
	applied_scale = Vector2.ONE
	%Modifier.rotation = 0.0
	%Modifier.scale = Vector2.ONE
	%Modifier.modulate = actor.get_value("tint")

func _physics_process(delta: float) -> void:
	applied_pos = %Modifier1.global_position
	applied_rotation = 0.0
	applied_scale = Vector2.ONE

	if not Global.static_view:
		if actor.rest_mode != 5:
			if (actor.rest_mode == 2 or actor.rest_mode == 3) and rest:
				pass
			else:
				if actor.get_value("should_rotate"):
					auto_rotate()
				else:
					should_rot_rotation = 0.0
				rainbow(delta)
				movements(delta)
		else:
			rest_mode_movements(delta)
	else:
		static_prev()

	follow_wiggle(delta)
	if not Global.static_view:
		var final_rot = applied_rotation + rot_drag + follow_point_rot + should_rot_rotation
		%Modifier.rotation = GlobalCalculations.is_nan_or_inf(final_rot)
		%Modifier.global_position = GlobalCalculations.is_nan_or_inf(applied_pos)
	placeholder_position = %Modifier1.global_position

func movements(delta):
	if Global.static_view:
		return
	drag(delta)
	wobble(delta)
	var effective_pos = dragger_global + last_wobble_pos
	if !actor.get_value("ignore_bounce"):
		effective_pos -= Vector2(Global.sprite_container.bounceChange, Global.sprite_container.bounceChange)
	var length = (effective_pos.x - dragger_global.x) + (effective_pos.y - dragger_global.y)
	if actor.get_value("physics"):
		if is_instance_valid(actor_get_parent()) and (actor_get_parent() is Sprite2D or actor_get_parent() is WigglyAppendage2D):
			var parent_node = actor_get_parent().owner
			if parent_node != null and is_instance_valid(parent_node):
				var parent_mov = parent_node.get_node("%Movements")
				var c_len_y = parent_mov.glob.y - parent_node.get_node("%Modifier1").global_position.y
				var c_len_x = parent_mov.glob.x - parent_node.get_node("%Modifier1").global_position.x
				length += c_len_y + c_len_x
	rotationalDrag(length, delta)
	stretch(length)

func rest_mode_movements(delta):
	if Global.static_view:
		return
	drag(delta)
	var effective_pos = dragger_global + last_wobble_pos
	if !actor.get_value("ignore_bounce"):
		effective_pos -= Vector2(Global.sprite_container.bounceChange, Global.sprite_container.bounceChange)
	var length = (effective_pos.x - dragger_global.x) + (effective_pos.y - dragger_global.y)
	if actor.get_value("physics"):
		if is_instance_valid(actor_get_parent()) and (actor_get_parent() is Sprite2D or actor_get_parent() is WigglyAppendage2D):
			var parent_node = actor_get_parent().owner
			if parent_node != null and is_instance_valid(parent_node):
				var parent_mov = parent_node.get_node("%Movements")
				var c_len_y = parent_mov.glob.y - parent_node.get_node("%Modifier1").global_position.y
				var c_len_x = parent_mov.glob.x - parent_node.get_node("%Modifier1").global_position.x
				length += c_len_y + c_len_x
	rotationalDrag(length, delta)
	stretch(length)


func drag(_delta):
	var target = placeholder_position
	var parent = actor_get_parent()
	if parent is Sprite2D or parent is WigglyAppendage2D:
		target += parent.applied_pos

	if actor.get_value("dragSpeed") == 0:
		dragger_global = %Modifier.global_position
	else:
		var t = 1.0 / max(actor.get_value("dragSpeed"), 1.0)
		dragger_global = dragger_global.lerp(target, t)
		applied_pos += dragger_global - placeholder_position

func wobble(_delta: float) -> void:
	if actor.get_value("pause_movement"):
		last_wobble_pos = Vector2.ZERO
	else:
		last_wobble_pos.x = sin((Global.tick - paused_wobble.x) * actor.get_value("xFrq")) * actor.get_value("xAmp")
		last_wobble_pos.y = sin((Global.tick - paused_wobble.y) * actor.get_value("yFrq")) * actor.get_value("yAmp")
	applied_pos += last_wobble_pos


func rotationalDrag(length, delta: float):
	if actor.is_default("rot_frq"):
		if actor.get_value("pause_movement"):
			if actor.is_all_default("rot_frq"):
				last_rot = 0
			else:
				paused_rotation += delta if Global.settings_dict.should_delta else 1.
		else:
			last_rot = sin((Global.tick-paused_rotation) * actor.get_value("rot_frq"))
			last_rot *= deg_to_rad(actor.get_value("rdragStr"))
	else:
		last_rot = sin((Global.tick-paused_rotation) * actor.get_value("rot_frq"))
		last_rot *= deg_to_rad(actor.get_value("rdragStr"))
	
	applied_rotation = lerp_angle(applied_rotation, last_rot, 0.15)
	
	var yvel = ((length * actor.get_value("rdragStr"))* 0.5)
	yvel = clamp(yvel,actor.get_value("rLimitMin"),actor.get_value("rLimitMax"))
	
	rot_drag = GlobalCalculations.is_nan_or_inf(lerp_angle(rot_drag,deg_to_rad(yvel),0.15))


func stretch(length):
	var yvel = length * actor.get_value("stretchAmount") * 0.01
	var target = Vector2(1.0 - yvel, 1.0 + yvel)
	%Modifier.scale = lerp(%Modifier.scale, target, 0.15)

func static_prev():
	%Modifier.position = Vector2.ZERO
	%Modifier.rotation = 0.0
	%Modifier.scale = Vector2.ONE
	%Modifier.modulate = actor.get_value("tint")
	dragger_global = %Modifier.global_position

func follow_wiggle(delta: float) -> void:
	if not actor.get_value("follow_wa_tip"):
		follow_point_rot = 0.0
		return
	var parent = actor_get_parent()
	if !is_instance_valid(parent) or not parent.has_method("get_points"):
		follow_point_rot = 0.0
		return

	var points = parent.get_points()
	var tip_index = clamp(actor.get_value("tip_point"), 0, points.size() - 1)
	var raw_tip: Vector2 = points[tip_index]
	var rest_angle: float = parent.get_rest_direction_angle() if parent.has_method("get_rest_direction_angle") else 0.0

	var smoothed_pos = %Modifier.position.lerp(raw_tip, 0.9)
	%Modifier.position = smoothed_pos

	var base_length: float = 1.0
	if points.size() > 1:
		base_length = max(points[0].distance_to(points[-1]), 0.001)

	if has_prev:
		var movement = smoothed_pos - prev_smoothed_pos
		var raw_strength = movement.length() / (base_length * max(delta, 0.0001))
		strength = lerp(strength, clamp(raw_strength, 0.0, 1.0), 0.1)

	prev_smoothed_pos = smoothed_pos
	has_prev = true

	var dir = prev_smoothed_pos - raw_tip
	var min_angle = deg_to_rad(actor.get_value("follow_wa_mini"))
	var max_angle = deg_to_rad(actor.get_value("follow_wa_max"))
	var dir_angle = atan2(dir.y, dir.x)

	if dir.length() > actor.get_value("rotation_threshold"):
		if actor.get_value("anchor_id") == null:
			if actor.get_value("follow_range"):
				var rel_angle = wrapf(dir_angle - rest_angle, -PI, PI)
				var target_rel: float = rel_angle * strength
				var target_ang: float = rest_angle + target_rel
				min_angle += rest_angle
				max_angle += rest_angle
				_b = target_ang
			else:
				var rel_angle = wrapf(dir_angle, -PI, PI)
				var target_rel: float = rel_angle * strength
				var target_ang: float = target_rel
				_b = target_ang

	biased = lerp(biased, _b, actor.get_value("follow_strength"))
	follow_point_rot = GlobalCalculations.clamp_angle(biased, min_angle, max_angle)

func rainbow(delta):
	if actor.get_value("hidden_item") && Global.mode != 0:
		%Sprite2D.self_modulate.a = 0.0
	else:
		if actor.get_value("rainbow"):
			if not actor.get_value("rainbow_self"):
				%Sprite2D.self_modulate.s = 0
				%Modifier.modulate.s = 1
				%Modifier.modulate.h = wrap(%Modifier.modulate.h + (actor.get_value("rainbow_speed")*delta), 0, 1)
			else:
				%Modifier.modulate.s = 0
				%Sprite2D.self_modulate.s = 1
				%Sprite2D.self_modulate.h = wrap(%Sprite2D.self_modulate.h + (actor.get_value("rainbow_speed")*delta), 0, 1)
		else:
			%Sprite2D.self_modulate = actor.get_value("tint")
			%Modifier.modulate.s = 0

func auto_rotate():
	should_rot_rotation += actor.get_value("should_rot_speed")

func actor_get_parent():
	return get_parent()

func _frame_lerp(delta: float, base_t := 0.15) -> float:
	var fps = max(30.0, Engine.max_fps)
	var per_second_k = -log(1.0 - clamp(base_t, 0.001, 0.999)) * fps
	var t := 1.0 - exp(-per_second_k * clamp(delta, 0.0, 1.0))
	return clamp(t, 0.0, 1.0)

func _on_sprite_object_visibility_changed() -> void:
	rest = !actor.is_visible_in_tree()
