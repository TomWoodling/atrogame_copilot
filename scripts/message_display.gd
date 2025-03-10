extends HUDElement
class_name MessageDisplay

@onready var label: Label = $Label
@onready var panel: Panel = $Panel

var hide_timer: SceneTreeTimer

func _ready() -> void:
	# Ensure we start hidden
	hide_element()

func display_message(message_data: Dictionary) -> void:
	# Validate message data
	if not message_data.has_all(["text", "color", "duration"]):
		push_error("Invalid message data format")
		return
		
	if hide_timer and hide_timer.time_left > 0:
		hide_timer.timeout.disconnect(hide_element)
		
	# Set up the message
	label.text = message_data.text
	label.add_theme_color_override("font_color", message_data.color)
	
	show_element()
	
	# Set up auto-hide timer
	hide_timer = get_tree().create_timer(message_data.duration)
	hide_timer.timeout.connect(hide_element)

func hide_element() -> void:
	if hide_timer and hide_timer.timeout.is_connected(hide_element):
		hide_timer.timeout.disconnect(hide_element)
	super.hide_element()
