# dialog_display.gd
extends HUDElement
class_name DialogDisplay

signal dialog_completed
signal dialog_advanced(current_index: int)
signal mood_changed(mood: String)

@export var speaker_label: Label
@export var text_label: Label
@export var dialog_panel: Panel
@export var next_indicator: TextureRect
@export var character_display_time: float = 0.03  # Time per character for text reveal

var current_dialog: DialogContainer
var current_index: int = 0
var is_text_revealing: bool = false
var dialog_text: String = ""
var revealed_text: String = ""
var dialog_tween: Tween

func _ready() -> void:
	next_indicator.visible = false
	# Hide initially
	dialog_panel.modulate.a = 0
	visible = false

func _input(event) -> void:
	# Only process input when dialog is active and visible
	if not visible or modulate.a < 0.5:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_advance_dialog()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_on_advance_dialog()

func start_dialog(dialog: DialogContainer) -> void:
	if not dialog or dialog.dialog_entries.size() == 0:
		return
		
	current_dialog = dialog
	current_index = 0
	
	show_element()
	display_current_entry()

func display_current_entry() -> void:
	var entry = current_dialog.get_entry(current_index)
	if not entry:
		complete_dialog()
		return
	
	# Signal mood change
	emit_signal("mood_changed", entry.mood)
	
	# Setup display
	speaker_label.text = entry.speaker if entry.speaker else ""
	speaker_label.visible = not entry.speaker.is_empty()
	
	# Start text reveal animation
	dialog_text = entry.text
	revealed_text = ""
	next_indicator.visible = false
	
	# Cancel any existing tweens
	if dialog_tween:
		dialog_tween.kill()
	
	# Start revealing text
	is_text_revealing = true
	reveal_text()

func reveal_text() -> void:
	text_label.text = ""
	revealed_text = ""
	
	dialog_tween = create_tween()
	
	# For each character in the dialog text
	for i in range(dialog_text.length()):
		# Add function to show next character
		dialog_tween.tween_callback(func():
			revealed_text += dialog_text[revealed_text.length()]
			text_label.text = revealed_text
		)
		dialog_tween.tween_interval(character_display_time)
	
	# When all characters are revealed
	dialog_tween.tween_callback(func():
		is_text_revealing = false
		next_indicator.visible = true
	)

func _on_advance_dialog() -> void:
	# If text is still revealing, show all text immediately
	if is_text_revealing:
		if dialog_tween:
			dialog_tween.kill()
		text_label.text = dialog_text
		revealed_text = dialog_text
		is_text_revealing = false
		next_indicator.visible = true
		return
	
	# Advance to next dialog entry
	current_index += 1
	emit_signal("dialog_advanced", current_index)
	
	if current_index >= current_dialog.dialog_entries.size():
		complete_dialog()
	else:
		display_current_entry()

func complete_dialog() -> void:
	hide_element()
	emit_signal("dialog_completed")
	
	# Reset
	current_dialog = null
	current_index = 0
	text_label.text = ""
	speaker_label.text = ""
