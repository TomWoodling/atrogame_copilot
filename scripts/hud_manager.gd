extends Node

signal message_shown(message_data: Dictionary)
signal message_hidden

@onready var message_scene: PackedScene = preload("res://scenes/ui/message_display.tscn")
@onready var poi_marker_scene: PackedScene = preload("res://scenes/ui/poi_marker.tscn")

var is_initialized: bool = false
var current_hud: Control
var message_container: Control
var poi_container: Control
var active_pois: Dictionary = {}

# We maintain the existing functionality while ensuring message_container points to the right node
func _ready() -> void:
	message_container = $HUD/ui_messages
	poi_container = $HUD/ui_pois
	if message_container and poi_container:
		is_initialized = true
	else:
		push_error("HUD containers not found. Check scene structure.")

func show_message(message_data: Dictionary) -> void:
	if not is_initialized:
		push_error("HUD Manager not properly initialized")
		return
	
	# Clear existing messages
	for child in message_container.get_children():
		if child.is_in_group("ui_messages"):
			child.queue_free()
	
	# Instance and add the message scene
	var message = message_scene.instantiate()
	message_container.add_child(message)
	message.display_message(message_data)
	emit_signal("message_shown", message_data)

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
