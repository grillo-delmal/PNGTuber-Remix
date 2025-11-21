@icon("res://UI/BetterSlider/BetSIcon .png")
extends BoxContainer
class_name BetterSliderRange

enum Type {
	
	Both,
	Spin,
	Slide,
	NoLabel,
	NoLabelSpin,

}

var should_change : bool = false
@export var sp_type : String = "Null"
@export var label_text : String = "placeholder"
@export var mini_value : float
@export var max_value : float
@export var step : float
@export var value : float
@export var ui_type : Type
@export var value_min_update : String = "position": get = get_value_min
@export var value_max_update : String = "position": get = get_value_max
@export var has_alt_values := false

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.reinfo.connect(enable)
	Global.deselect.connect(nullfy)
	Global.editing_for_changed.connect(enable)
	nullfy()
	
	%DoubleHSliderGd.ds_min_value = mini_value
	%DoubleHSliderGd.ds_max_value = max_value
	%DoubleHSliderGd.ds_step = step
	%DoubleHSliderGd.value = value
	%BetterSliderLabel.text = label_text
	ready_type(ui_type)

func ready_type(typ):
	match typ:
		Type.Both:
			pass
		Type.Spin:
			pass
		Type.NoLabel:
			%BetterSliderLabel.hide()
		Type.NoLabelSpin:
			%BetterSliderLabel.hide()


func get_value_min() -> String:
	if !has_alt_values:
		return value_min_update
	
	match Global.editing_for:
		Global.Mouth.Open:
			return "mo_" + value_min_update
		Global.Mouth.Screaming:
			return "scream_" + value_min_update
	
	return value_min_update

func get_value_max() -> String:
	if !has_alt_values:
		return value_max_update
	
	match Global.editing_for:
		Global.Mouth.Open:
			return "mo_" + value_max_update
		Global.Mouth.Screaming:
			return "scream_" + value_max_update
	return value_max_update

func release():
	Global.spinbox_held = false

func f_entered():
	Global.spinbox_held = true

func nullfy():
	%DoubleHSliderGd.enabled = false

func enable():
	should_change = false
	%DoubleHSliderGd.enabled = false
	for i in Global.held_sprites:
		if i.sprite_type == sp_type:
			%DoubleHSliderGd.enabled = true
			%DoubleHSliderGd.lower_value = i.sprite_data[value_min_update]
			%DoubleHSliderGd.upper_value = i.sprite_data[value_max_update]
			%BetterSliderLabel.text = label_text + "(" + str(%DoubleHSliderGd.lower_value) + "," + str(%DoubleHSliderGd.upper_value) + ")" + " :"
			
		if sp_type == "":
			%DoubleHSliderGd.enabled = true
			%DoubleHSliderGd.lower_value = i.sprite_data[value_min_update]
			%DoubleHSliderGd.upper_value = i.sprite_data[value_max_update]
			%BetterSliderLabel.text = label_text + "(" + str(%DoubleHSliderGd.lower_value) + "," + str(%DoubleHSliderGd.upper_value) + ")" + " :"
			
	should_change = true

func _on_double_h_slider_gd_ds_values_changed(lower: float, upper: float) -> void:
	if should_change:
		if  sp_type != "Null":
			var undo_redo_data : Array = []
			for i in Global.held_sprites:
				var og_val = i.sprite_data.duplicate()
				i.sprite_data[value_min_update] = lower
				i.sprite_data[value_max_update] = upper
				if i.sprite_type == "WiggleApp" && sp_type == "WiggleApp":
					i.update_wiggle_parts()
				i.save_state(Global.current_state)
				undo_redo_data.append({sprite_object = i, 
				data = i.sprite_data.duplicate(), 
				og_data = og_val,
				data_type = "sprite_data", 
				state = Global.current_state})
	
	%BetterSliderLabel.text = label_text + "(" + str(lower) + "," + str(upper) + ")" + " :"
