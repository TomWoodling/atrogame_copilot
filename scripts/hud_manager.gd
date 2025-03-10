extends Node

signal message_shown(message_data: Dictionary)
signal message_hidden

@onready var message_scene: PackedScene = preload("res://scenes/ui/message_display.tscn")
@onready var poi_marker_scene: PackedScene = preload("res://scenes/ui/poi_marker.tscn")
@onready var hud_scene: PackedScene = preload("res://scenes/ui/hud.tscn")

var message_container: Control
var poi_container: Control
var active_pois: Dictionary = {}

func _ready() -> void:
	# Instance and add HUD
	var hud = hud_scene.instantiate()
	add_child(hud)
	
	# Get references to containers from the instantiated HUD
	message_container = hud.get_node("ui_messages")
	poi_container = hud.get_node("ui_pois")
	
	if not message_container or not poi_container:
		push_error("Required HUD containers not found in hud.tscn")

func show_message(message_data: Dictionary) -> void:
	if not message_container:
		push_error("Message container not available")
		return
	
	# Clear existing messages
	for child in message_container.get_children():
		child.queue_free()
	
	var message = message_scene.instantiate()
	message_container.add_child(message)
	message.display_message(message_data)
	emit_signal("message_shown", message_data)

func add_poi(target: Node3D, poi_type: String, icon: Texture2D, label: String = "") -> void:
	if not poi_container or not target or target in active_pois:
		return
		
	var marker = poi_marker_scene.instantiate()
	poi_container.add_child(marker)
	marker.setup(target, icon, label)
	active_pois[target] = marker
	
	# Clean single-line connection using callable
	if not target.tree_exiting.is_connected(remove_poi.bind(target)):
		target.tree_exiting.connect(remove_poi.bind(target))

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

func _exit_tree() -> void:
	clear_all_pois()
