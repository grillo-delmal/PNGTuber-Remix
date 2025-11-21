extends Control

@export var double_h_slider: DoubleHSliderGd
@export var lower_v: Label
@export var upper_v: Label

func _ready():
	double_h_slider.ds_values_changed.connect(_on_double_slider_value_changed)	
	double_h_slider.lower_value_changed.connect(_on_lower_value_changed)
	double_h_slider.upper_value_changed.connect(_on_upper_value_changed)

func _on_double_slider_value_changed(lower: float, upper: float):
	lower_v.text = str(lower)
	upper_v.text = str(upper)
	print(lower)
	
func _on_lower_value_changed(lower:float):
	print(lower)
	
func _on_upper_value_changed(upper:float):
	print(upper)
	
