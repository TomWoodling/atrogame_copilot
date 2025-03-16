extends Node

signal message_shown(message_data: Dictionary)
signal message_hidden

@onready var message_scene: PackedScene = preload("res://scenes/ui/message_display.tscn")
@onready var poi_marker_scene: PackedScene = preload("res://scenes/ui/poi_marker.tscn")
@onready var hud_scene: PackedScene = preload("res://scenes/ui/hud.tscn")
@onready var inventory_scene: PackedScene = preload("res://scenes/ui/inventory.tscn")
var inventory_ui: Control
@onready var scanner_display_scene: PackedScene = preload("res://scenes/ui/scanner_display.tscn")
var scanner_display: Control

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

func show_inventory() -> void:
	if not inventory_ui:
		inventory_ui = inventory_scene.instantiate()
		add_child(inventory_ui)
	inventory_ui.show()

func hide_inventory() -> void:
	if inventory_ui:
		inventory_ui.hide()

func show_scanner() -> void:
	if not scanner_display:
		scanner_display = scanner_display_scene.instantiate()
		add_child(scanner_display)
	scanner_display.show_element()

func hide_scanner() -> void:
	if scanner_display:
		scanner_display.hide_element()

func show_collection_notification(scan_data: Dictionary) -> void:
	var message_data := {
		"title": "New Discovery!" if scan_data.is_first_find else "Collected",
		"text": scan_data.label,
		"subtext": "Category: %s" % scan_data.category,
		"duration": 3.0,
		"type": "collection",
		"rarity_tier": scan_data.rarity_tier
	}
	show_message(message_data)


# Scanner progress updates - works with existing scanner_display scene
func update_scan_progress(progress: float, target_name: String = "") -> void:
	if scanner_display:
		scanner_display.update_progress(progress)
		if not target_name.is_empty():
			scanner_display.update_target(target_name)
