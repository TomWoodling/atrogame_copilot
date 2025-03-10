extends Node

signal message_shown(message: String, type: String)
signal message_hidden

var hud_scene: PackedScene = preload("res://scenes/ui/hud.tscn")
var message_scene: PackedScene = preload("res://scenes/ui/message_display.tscn")
var poi_marker_scene: PackedScene = preload("res://scenes/ui/poi_marker.tscn")

var is_initialized: bool = false
var current_hud: Control
var message_container: Control
var poi_container: Control
var active_pois: Dictionary = {}

# Define message types with their colors and durations
const MESSAGE_TYPES = {
	"INFO": {"color": Color.WHITE, "duration": 3.0},
	"WARNING": {"color": Color.YELLOW, "duration": 5.0},
	"ERROR": {"color": Color.RED, "duration": 5.0},
	"SUCCESS": {"color": Color.GREEN, "duration": 3.0}
}

func initialize() -> void:
	if is_initialized:
		return
		
	# Instance the HUD
	current_hud = hud_scene.instantiate()
	get_tree().root.add_child(current_hud)
	
	# Get references to containers
	message_container = current_hud.get_node("ui_messages")
	poi_container = current_hud.get_node("ui_pois")  # Fixed node path
	
	if !message_container or !poi_container:
		push_error("Failed to get UI containers")
		return
		
	is_initialized = true

func show_message(text: String, type: String = "INFO") -> void:
	if not is_initialized:
		push_error("HUDManager not initialized")
		return
		
	# Remove any existing messages
	for child in message_container.get_children():
		if child.is_in_group("ui_messages"):
			child.queue_free()
	
	# Create message data
	var message_type = MESSAGE_TYPES[type] if MESSAGE_TYPES.has(type) else MESSAGE_TYPES["INFO"]
	var message_data = {
		"text": text,
		"color": message_type["color"],
		"duration": message_type["duration"]
	}
	
	# Create new message
	var message = message_scene.instantiate()
	message_container.add_child(message)
	
	# Ensure the message instance is valid and has the required method
	if message.has_method("display_message"):
		message.display_message(message_data)
		emit_signal("message_shown", text, type)
	else:
		push_error("Message instance missing display_message method")
		message.queue_free()

func add_poi(target: Node3D, poi_type: String, icon: Texture2D, label: String = "") -> void:
	if not is_initialized or not target or target in active_pois:
		return
		
	var marker = poi_marker_scene.instantiate()
	poi_container.add_child(marker)
	marker.setup(target, icon, label)
	active_pois[target] = marker
	
	# Connect to target's tree_exiting signal to auto-cleanup
	target.tree_exiting.connect(
		func(): remove_poi(target)
	)

func remove_poi(target: Node3D) -> void:
	if target in active_pois:
		if is_instance_valid(active_pois[target]):
			active_pois[target].queue_free()
		active_pois.erase(target)

func clear_all_pois() -> void:
	for marker in active_pois.values():
		if is_instance_valid(marker):
			marker.queue_free()
	active_pois.clear()

# Called when the node exits the scene tree
func _exit_tree() -> void:
	clear_all_pois()
	if is_instance_valid(current_hud):
		current_hud.queue_free()
