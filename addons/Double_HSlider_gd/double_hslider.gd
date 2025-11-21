@tool
@icon("res://addons/Double_HSlider_gd/icon.png")
class_name DoubleHSliderGd
extends Range

#region 主题属性
@export_group("Range Settings")
@export var ds_min_value: float = 0.0:
	get: return _ds_min_value
	set(value):
		value = snapped(value, ds_step) if ds_step > 0 else value
		_ds_min_value = minf(value, ds_max_value - ds_step)
		_validate_values()
		queue_redraw()

@export var ds_max_value: float = 10.0:
	get: return _ds_max_value
	set(value):
		value = snapped(value, ds_step) if ds_step > 0 else value
		_ds_max_value = maxf(ds_min_value + ds_step, value)
		_validate_values()
		queue_redraw()

@export var ds_step: float = 0.1:
	get: return _ds_step
	set(value):
		_ds_step = maxf(0, value)
		_validate_values()
		queue_redraw()

@export_group("Value")
@export var lower_value: float = 2.0:
	get: return _lower_value
	set(value):
		var new_val = snapped(clampf(value, ds_min_value, upper_value), ds_step)
		if _lower_value != new_val:
			_lower_value = new_val
			queue_redraw()
			lower_value_changed.emit(new_val)
			ds_values_changed.emit(_lower_value, _upper_value)

@export var upper_value: float = 7.0:
	get: return _upper_value
	set(value):
		var new_val = snapped(clampf(value, lower_value, ds_max_value), ds_step)
		if _upper_value != new_val:
			_upper_value = new_val
			queue_redraw()
			upper_value_changed.emit(new_val)
			ds_values_changed.emit(_lower_value, _upper_value)

@export_group("Appearance")
@export var slider_color := Color(0.176, 0.176, 0.176):
	set(value):
		if slider_color != value:
			slider_color = value
			queue_redraw()
@export var range_color := Color(0.2, 0.6, 1.0):
	set(value):
		if range_color != value:
			range_color = value
			queue_redraw()
@export var hover_range_color := Color(0.2, 0.8, 1.0):  # 悬停时的高亮颜色
	set(value):
		if hover_range_color != value:
			hover_range_color = value
			queue_redraw()
@export var grabber_color := Color(0.792, 0.792, 0.792):
	set(value):
		if grabber_color != value:
			grabber_color = value
			queue_redraw()

@export var grabber_color_disabled := Color(0.792, 0.792, 0.792):
	set(value):
		if grabber_color_disabled != value:
			grabber_color_disabled = value
			queue_redraw()


@export var grabber_size: float = 10.0:
	set(value):
		_grabber_size = maxf(2.0, value)
		custom_minimum_size.y = _grabber_size * 2 + _slider_height
		queue_redraw()
	get: return _grabber_size

@export var slider_height: float = 4.0:
	set(value):
		_slider_height = maxf(1.0, value)
		custom_minimum_size.y = _grabber_size * 2 + _slider_height
		queue_redraw()
	get: return _slider_height
@export_range(0,1,0.1) var hover_sensitivity: float = 0.8 # 悬停检测灵敏度 (0-1)

@export_group("Tooltip")
@export var show_tooltip: bool = false
@export var tooltip_offset: float = 5.0
@export var tooltip_font_size: int = 16:  # 新增字体大小属性
	set(value):
		tooltip_font_size = max(8, value)  # 最小8像素
		queue_redraw()
@export var tooltip_color:=Color.WHITE

#endregion

@export_group("Settings")
@export var enabled: bool = true:
	set(value):
		_enabled = value
		queue_redraw()
	get:
		return _enabled
var _enabled := true

#region 信号
signal drag_started()
signal drag_ended()
signal ds_values_changed(lower: float, upper: float)
signal lower_value_changed(value: float)
signal upper_value_changed(value: float)
#endregion

#region 私有变量
var _ds_min_value := 0.0
var _ds_max_value := 10.0
var _ds_step := 0.1
var _lower_value := 2.0
var _upper_value := 7.0
var _slider_height := 4.0
var _grabber_size := 10.0

var _dragging_lower := false
var _dragging_upper := false
var _hovered_grabber := -1  # -1: 无, 0: 左滑块, 1: 右滑块
var _tooltip_visible := false
var _last_click_pos := Vector2.ZERO
#endregion


func _init():
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(100, _grabber_size * 2 + _slider_height)

func _ready():
	_validate_values()
	if not Engine.is_editor_hint():
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _validate_values():
	_lower_value = clamp(snapped(_lower_value, ds_step), _ds_min_value, _upper_value)
	_lower_value = clamp(_lower_value,_ds_min_value,_ds_max_value)
	_upper_value = clamp(snapped(_upper_value, ds_step), _lower_value, _ds_max_value)
	_upper_value = clamp(_upper_value,_ds_min_value,_ds_max_value)


func _gui_input(event: InputEvent):
	if not is_visible_in_tree() or !enabled:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		return
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var mouse_pos = _get_adjusted_mouse_pos(event)
	var is_mouse_inside = Rect2(Vector2.ZERO, size).has_point(mouse_pos)

	# 鼠标按下事件
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and is_mouse_inside:
			get_viewport().set_input_as_handled()
			grab_focus()
			_last_click_pos = mouse_pos
			
			var lower_pos = _get_grabber_position(true)
			var upper_pos = _get_grabber_position(false)
			var lower_dist = mouse_pos.distance_to(lower_pos)
			var upper_dist = mouse_pos.distance_to(upper_pos)
			
			# 使用更严格的悬停检测范围
			var hover_threshold = _grabber_size * hover_sensitivity
			
			if lower_dist <= upper_dist and lower_dist <= hover_threshold:
				_dragging_lower = true
				_hovered_grabber = 0
			elif upper_dist <= hover_threshold:
				_dragging_upper = true
				_hovered_grabber = 1
			else:
				# 点击轨道时，移动最近的滑块
				var click_value = _get_value_from_position(mouse_pos.x)
				var lower_diff = abs(click_value - lower_value)
				var upper_diff = abs(click_value - upper_value)
				
				if lower_diff <= upper_diff:
					_dragging_lower = true
					_hovered_grabber = 0
					lower_value = click_value
				else:
					_dragging_upper = true
					_hovered_grabber = 1
					upper_value = click_value

			if _dragging_lower or _dragging_upper:
				_tooltip_visible = true
				drag_started.emit()
				queue_redraw()

		elif _dragging_lower or _dragging_upper:
			_dragging_lower = false
			_dragging_upper = false
			_tooltip_visible = false
			drag_ended.emit()
			queue_redraw()

	# 鼠标移动事件
	elif event is InputEventMouseMotion:
		if _dragging_lower or _dragging_upper:
			var value = _get_value_from_position(mouse_pos.x)
			if _dragging_lower:
				lower_value = clamp(value, ds_min_value, upper_value)
			else:
				upper_value = clamp(value, lower_value, ds_max_value)
			queue_redraw()
		elif is_mouse_inside:
			# 使用更严格的悬停检测
			var new_hover = _get_hovered_grabber(mouse_pos)
			if _hovered_grabber != new_hover:
				_hovered_grabber = new_hover
				_tooltip_visible = new_hover != -1
				queue_redraw()
		elif _hovered_grabber != -1:
			_hovered_grabber = -1
			_tooltip_visible = false
			queue_redraw()

func _get_adjusted_mouse_pos(event: InputEvent) -> Vector2:
	if event is InputEventMouse:
		var global_mouse = get_global_mouse_position()
		return get_global_transform().affine_inverse() * global_mouse
	elif event is InputEventScreenTouch:
		return make_input_local(event).position
	return Vector2.ZERO

func _get_position_from_value(value: float) -> float:
	return (value - ds_min_value) / (ds_max_value - ds_min_value) * size.x

func _get_value_from_position(pos_x: float) -> float:
	var normalized = clampf(pos_x / size.x, 0.0, 1.0)
	return snapped(ds_min_value + normalized * (ds_max_value - ds_min_value), ds_step)


func _get_grabber_position(is_lower: bool) -> Vector2:
	var value = lower_value if is_lower else upper_value
	return Vector2(_get_position_from_value(value), size.y / 2)


func _get_hovered_grabber(mouse_pos: Vector2) -> int:
	var lower_pos = _get_grabber_position(true)
	var upper_pos = _get_grabber_position(false)
	var lower_dist = mouse_pos.distance_to(lower_pos)
	var upper_dist = mouse_pos.distance_to(upper_pos)
	
	# 使用更严格的悬停检测范围
	var hover_threshold = _grabber_size * hover_sensitivity
	
	if lower_dist <= hover_threshold and upper_dist <= hover_threshold:
		return 0 if lower_dist <= upper_dist else 1
	elif lower_dist <= hover_threshold:
		return 0
	elif upper_dist <= hover_threshold:
		return 1
	
	return -1

func _draw():
	var center_y = size.y / 2

	# 绘制滑轨
	draw_rect(Rect2(0, center_y - _slider_height / 2, size.x, _slider_height), slider_color)

	# 绘制选中范围 (悬停时高亮)
	var lower_pos = _get_position_from_value(lower_value)
	var upper_pos = _get_position_from_value(upper_value)
	var current_range_color = hover_range_color if _hovered_grabber != -1 else range_color
	draw_rect(
		Rect2(
			lower_pos, 
			center_y - _slider_height / 2, 
			upper_pos - lower_pos, 
			_slider_height
		), 
		current_range_color
	)

	# 绘制滑块
	if _enabled:
		draw_circle(_get_grabber_position(true), _grabber_size, grabber_color)
		draw_circle(_get_grabber_position(false), _grabber_size, grabber_color)
	else:
		draw_circle(_get_grabber_position(true), _grabber_size, grabber_color_disabled)
		draw_circle(_get_grabber_position(false), _grabber_size, grabber_color_disabled)

	# 绘制工具提示
	if show_tooltip and _tooltip_visible:
		_draw_tooltip(_hovered_grabber)

func _draw_tooltip(grabber_index: int):
	var value = lower_value if grabber_index == 0 else upper_value
	var pos_x = _get_position_from_value(value)
	var font = get_theme_default_font()
	
	# 格式化数值
	var text = _format_value(value)
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, tooltip_font_size)
	
	# 计算位置（确保不超出边界）
	var tip_x = clamp(pos_x - text_size.x / 2, 0, size.x - text_size.x)
	var tip_y = size.y / 2 - _grabber_size - tooltip_offset - text_size.y
	
	# 绘制文字
	draw_string(
		font,
		Vector2(tip_x, tip_y + text_size.y),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		tooltip_font_size,
		tooltip_color
	)

# 辅助方法：格式化数值
func _format_value(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return "%d" % round(value)
	return str(value).replace(".0", "").rstrip("0").rstrip(".")
