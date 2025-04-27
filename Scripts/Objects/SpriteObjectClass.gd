extends Node2D
class_name SpriteObject


@export var sprite_object : Node2D

#Movement
var heldTicks = 0
#Wobble
var squish = 1
var currently_speaking : bool = false
# Misc
var treeitem = null
var visb
var sprite_name : String = ""
@export var states : Array = [{}]
var coord
var dragging : bool = false
var of = Vector2(0,0)

var sprite_id : float
var parent_id : float = 0
var physics_effect = 1
var glob

@export var sprite_type : String = "WiggleApp"

var anim_texture 
var anim_texture_normal 
var img_animated : bool = false
var is_plus_first_import : bool = false
var image_data : PackedByteArray = []
var normal_data : PackedByteArray = []


var is_apng : bool = false
var is_collapsed : bool = false
var played_once : bool = false


@onready var og_glob = global_position

var dt = 0.0
var frames : Array[AImgIOFrame] = []
var frames2 : Array[AImgIOFrame] = []
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

var selected : bool = false


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
			var og_pos = global_position
			reparent(i.sprite_object)
			global_position = og_pos
