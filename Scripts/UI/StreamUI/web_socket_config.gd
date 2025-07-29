extends VBoxContainer


func _ready() -> void:
	%PortValue.value = WebsocketHandler.port
	WebsocketHandler.port_state.connect(disable_spinbox)
	%StopButton.disabled = true
	await get_tree().create_timer(0.1).timeout
	check_websocket()

func disable_spinbox(toggle : bool):
	%PortValue.editable = !toggle
	%StartButton.disabled = toggle
	%StopButton.disabled = !toggle

func _on_start_button_pressed() -> void:
	WebsocketHandler.start_websocket_server()

func _on_stop_button_pressed() -> void:
	WebsocketHandler.stop()

func _on_port_value_value_changed(value: float) -> void:
	WebsocketHandler.port = int(value)

func check_websocket():
	%PortValue.value = int(Settings.theme_settings.websocket_id)
	WebsocketHandler.port = int(Settings.theme_settings.websocket_id)
	if Settings.theme_settings.auto_activate_websocket:
		WebsocketHandler.start_websocket_server()
		disable_spinbox(true)
	else:
		disable_spinbox(false)
