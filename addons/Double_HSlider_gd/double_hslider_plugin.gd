@tool
extends EditorPlugin

const DoubleHSlider = preload("res://addons/Double_HSlider_gd/double_hslider.gd")

var double_hslider_icon: Texture2D

func _enter_tree():
	# 加载图标资源
	double_hslider_icon = load("res://addons/Double_HSlider_gd/icon.png")
	
	# 注册自定义控件
	add_custom_type("DoubleHSliderGd", "Range", DoubleHSlider, double_hslider_icon)
	if Engine.is_editor_hint():
		update_configuration_warnings()  # 强制刷新编辑器状态
	
func _exit_tree():
	# 卸载时移除自定义控件
	remove_custom_type("DoubleHSliderGd")
	
