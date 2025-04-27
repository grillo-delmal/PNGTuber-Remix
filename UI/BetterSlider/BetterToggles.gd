extends Button
class_name BetterToggles

var should_change : bool = false
@export var sp_type : String = "Null"
@export var value_to_update : String = "position"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.reinfo.connect(enable)
	Global.deselect.connect(nullfy)
	nullfy()
	toggle_mode = true
	toggled.connect(on_toggle)

func enable():
	should_change = false
	if sp_type == "Null":
		disabled = true
		#button_pressed = Global.held_sprite.sprite_data[value_to_update]
	
	else:
		for i in Global.held_sprites:
			if sp_type == i.sprite_type:
				disabled = false
				button_pressed = i.sprite_data[value_to_update]
				
			elif sp_type == "":
				disabled = false
				button_pressed = i.sprite_data[value_to_update]
	should_change = true

func nullfy():
	disabled = true

func on_toggle(toggle : bool):
	if should_change:
		if sp_type != "Null":
			for i in Global.held_sprites:
				if sp_type == i.sprite_type:
					i.sprite_data[value_to_update] = toggle
					i.save_state(Global.current_state)
				elif sp_type == "":
					i.sprite_data[value_to_update] = toggle
					i.save_state(Global.current_state)
