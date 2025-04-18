extends VBoxContainer


func _ready() -> void:
	%PortValue.value = WebsocketHandler.port
	WebsocketHandler.port_state.connect(disable_spinbox)
	%StopButton.disabled = true

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
