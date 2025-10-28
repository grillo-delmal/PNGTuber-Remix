extends Node2D
class_name SpriteObject

var sprite_data := {}
var cached_defaults := {}
const DEFAULT_DATA := {
	# Use mouth closed movement for all mouth states?
	shared_movement = true,
	editing_for = Global.Mouth.Closed,
	
	# Movement when mouth closed
	xAmp = 0,
	xFrq = 0,
	yAmp = 0,
	yFrq = 0,
	dragSpeed = 0,
	stretchAmount = 0,
	rdragStr = 0,
	rot_frq = 0.0,
	rLimitMin = -180,
	rLimitMax = 180,
	should_rot_speed = 0.01,
	should_rotate = false,
	mouse_delay = 0.1,
	look_at_mouse_pos = 0,
	look_at_mouse_pos_y = 0,
	mouse_rotation = 0.0,
	mouse_rotation_max = 0.0,
	mouse_scale_x = 0.0,
	mouse_scale_y = 0.0,
	drag_snap = 0.0,
	
	# Movement when mouth open
	mo_xAmp = 0,
	mo_xFrq = 0,
	mo_yAmp = 0,
	mo_yFrq = 0,
	mo_dragSpeed = 0,
	mo_stretchAmount = 0,
	mo_rdragStr = 0,
	mo_rot_frq = 0.0,
	mo_rLimitMin = -180,
	mo_rLimitMax = 180,
	mo_should_rot_speed = 0.01,
	mo_should_rotate = false,
	mo_mouse_delay = 0.1,
	mo_look_at_mouse_pos = 0,
	mo_look_at_mouse_pos_y = 0,
	mo_mouse_rotation = 0.0,
	mo_mouse_rotation_max = 0.0,
	mo_mouse_scale_x = 0.0,
	mo_mouse_scale_y = 0.0,
	mo_drag_snap = 0.0,
	
	# Movement when screaming
	scream_xAmp = 0,
	scream_xFrq = 0,
	scream_yAmp = 0,
	scream_yFrq = 0,
	scream_dragSpeed = 0,
	scream_stretchAmount = 0,
	scream_rdragStr = 0,
	scream_rot_frq = 0.0,
	scream_rLimitMin = -180,
	scream_rLimitMax = 180,
	scream_should_rot_speed = 0.01,
	scream_should_rotate = false,
	scream_mouse_delay = 0.1,
	scream_look_at_mouse_pos = 0,
	scream_look_at_mouse_pos_y = 0,
	scream_mouse_rotation = 0.0,
	scream_mouse_rotation_max = 0.0,
	scream_mouse_scale_x = 0.0,
	scream_mouse_scale_y = 0.0,
	scream_drag_snap = 0.0,
	# Other stuff idk
	blend_mode = "Normal",
	visible = true,
	colored = Color.WHITE,
	tint = Color.WHITE,
	z_index = 0,
	open_eyes = true,
	open_mouth = false,
	should_blink = false,
	should_talk =  false,
	animation_speed = 1,
	hframes = 1,
	scale = Vector2(1,1),
	folder = false,
	position = Vector2.ZERO,
	rotation = 0.0,
	offset = Vector2(0,0),
	ignore_bounce = false,
	clip = 0,
	physics = true,
	advanced_lipsync = false,
	should_reset = false,
	should_reset_state = false,
	one_shot = false,
	rainbow = false,
	rainbow_self = false,
	rainbow_speed = 0.01,
	follow_wa_tip = false,
	tip_point = 0,
	follow_wa_mini = -180,
	follow_wa_max = 180,
	follow_mouse_velocity = false,
	static_obj = false,
	is_cycle = false,
	cycle = 0,
	pause_movement = false,
	follow_type = 0,
	follow_type2 = 0,
	follow_type3 = 0,
	snap_pos = false,
	snap_rot = false,
	snap_scale = false,
	
	follow_range = true,
	follow_strength = 0.155,
	rotation_threshold = 0.01,
	hidden_item = false,
	}


@export var sprite_object : Node2D
@export var grab_object : BaseButton
var used_image_id : int = 0
var used_image_id_normal : int = 0
var referenced_data : ImageData = null
var referenced_data_normal : ImageData = null

#Movement
var heldTicks = 0
#Wobble
var squish = 1
# Misc
var treeitem = null
var layer_color : Color = Color.BLACK
var visb
var sprite_name : String = ""
@export var states : Array = [{}]
var coord
var dragging : bool = false
var of = Vector2(0,0)

var sprite_id : float
var parent_id : float = 0
var physics_effect = 1
var glob : Vector2 = Vector2.ZERO

@export var sprite_type : String = "WiggleApp"

var img_animated : bool = false
var is_plus_first_import : bool = false
var rotated : float = 0
var flipped_h : bool = false
var flipped_v : bool = false
var is_collapsed : bool = false
var played_once : bool = false

@onready var og_glob = global_position

var dt = 0.0
var fidx = 0
var saved_event : InputEvent
var is_asset : bool = false
var was_active_before : bool = true
var show_only : bool = false
var should_disappear : bool = false
var saved_keys : Array = []

var last_mouse_position : Vector2 = Vector2(0,0)
var last_dist : Vector2 = Vector2(0,0)
var global
var old_global: Vector2 = Vector2(-999999999999,-9999999999)

var selected : bool = false

func get_default_object_data() -> Dictionary:
	return {}

func _init() -> void:
	cached_defaults = DEFAULT_DATA.merged(get_default_object_data(), true)
	sprite_data = cached_defaults.duplicate()

func does_value_match_default(value: Variant, key: String) -> bool:
	if value is float:
		return is_equal_approx(value, cached_defaults[key])
	
	if value is Vector2:
		return value.is_equal_approx(cached_defaults[key])
	
	return value == cached_defaults[key]

func is_default(key: String, use_alts := true) -> bool:
	if key not in sprite_data:
		return true
	
	if key not in cached_defaults:
		return true
	
	var value = get_value(key) if use_alts else sprite_data[key]
	return does_value_match_default(value, key)

func is_all_default(key: String) -> bool:
	if key not in sprite_data:
		return true
	
	if key not in cached_defaults:
		return true
	
	for prefix: String in ["", "mo_", "scream_"]:
		if prefix and sprite_data.shared_movement:
			break
		
		var new_key := prefix + key
		var value = sprite_data[new_key]
		
		if not does_value_match_default(value, new_key):
			return false
	
	return true

func get_value(key: String) -> Variant:
	if key not in sprite_data:
		return null
	
	var default = sprite_data[key]
	
	if sprite_data.shared_movement:
		return default
	
	var state := Global.editing_for
	
	if state == Global.Mouth.Closed:
		state = Global.mouth
	
	match state:
		Global.Mouth.Closed: pass
		Global.Mouth.Open: key = "mo_" + key
		Global.Mouth.Screaming: key = "scream_" + key
	
	if key in sprite_data:
		return sprite_data[key]
	
	return default

func set_blend(blend):
	match  blend:
		"Normal":
			sprite_object.material.set_shader_parameter("enabled", false)
		"Add":
			sprite_object.material.set_shader_parameter("enabled", true)
			sprite_object.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/add.png"))
		"Subtract":
			sprite_object.material.set_shader_parameter("enabled", true)
			sprite_object.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/exclusion.png"))
		"Multiply":
			sprite_object.material.set_shader_parameter("enabled", true)
			sprite_object.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/multiply.png"))
		"Burn":
			sprite_object.material.set_shader_parameter("enabled", true)
			sprite_object.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/burn.png"))
		"HardMix":
			sprite_object.material.set_shader_parameter("enabled", true)
			sprite_object.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/hardmix.png"))
		"Cursed":
			sprite_object.material.set_shader_parameter("enabled", true)
			sprite_object.material.set_shader_parameter("Blend", preload("res://Misc/EasyBlend/Blends/test1.png"))

func reparent_obj(parent):
	for i in parent:
		if i.sprite_id == parent_id:
			var new_parent = i.sprite_object
			reparent(new_parent)
			break
	

func image_replaced(image_date : ImageData):
	if !get_value("folder"):
		if image_date == referenced_data:
			var texture = ImageTextureLoaderManager.check_flips(image_date.runtime_texture, self)
			sprite_object.texture.diffuse_texture = texture
			ImageTrimmer.set_thumbnail(treeitem)
		if image_date == referenced_data_normal:
			var texture = ImageTextureLoaderManager.check_flips(image_date.runtime_texture, self)
			sprite_object.texture.normal_texture = texture
	else:
		return



func zazaza_reposition(parent):
	for i in parent:
		if i.sprite_id == parent_id:
			for state in states:
				if !state.is_empty():
					var contain = i
					var desired_global = contain.to_global(state.position)
					var desired_local = contain.to_local(desired_global) +Vector2(640, 360)
					state.position = get_parent().to_local(desired_local)
				
