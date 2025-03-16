extends Node

signal message_shown(message_data: Dictionary)
signal message_hidden

@onready var message_scene: PackedScene = preload("res://scenes/ui/message_display.tscn")
@onready var scanner_display_scene: PackedScene = preload("res://scenes/ui/scanner_display.tscn")
@onready var inventory_scene: PackedScene = preload("res://scenes/ui/inventory.tscn")
@onready var poi_marker_scene: PackedScene = preload("res://scenes/ui/poi_marker.tscn")
@onready var hud_scene: PackedScene = preload("res://scenes/ui/hud.tscn")

var message_container: Control
var scanner_display: Control
var inventory_ui: Control
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
	
	# Connect to necessary signals
	ScannerManager.scan_started.connect(_on_scan_started)
	ScannerManager.scan_completed.connect(_on_scan_completed)
	ScannerManager.scan_failed.connect(_on_scan_failed)
	InventoryManager.collection_updated.connect(_on_collection_updated)
	GameManager.inventory_state_changed.connect(_on_inventory_state_changed)
	GameManager.game_state_changed.connect(_on_game_state_changed)

# Message Display
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
	message_shown.emit(message_data)

# Scanner Display
func _on_scan_started(target: Node3D) -> void:
	if not scanner_display:
		scanner_display = scanner_display_scene.instantiate()
		# Since our scanner is now a HUDElement, we should add it to the HUD
		add_child(scanner_display)
		# Get the actual scanner display component
		var display = scanner_display.get_node("ScannerDisplay")
		if display:
			display._on_scan_started(target)
	else:
		var display = scanner_display.get_node("ScannerDisplay")
		if display:
			display._on_scan_started(target)

func _on_scan_completed(target: Node3D, data: Dictionary) -> void:
	if scanner_display:
		var display = scanner_display.get_node("ScannerDisplay")
		if display:
			display._on_scan_completed(target, data)

func _on_scan_failed(reason: String) -> void:
	if scanner_display:
		var display = scanner_display.get_node("ScannerDisplay")
		if display:
			display._on_scan_failed(reason)
			
		# Also show the failure message
		show_message({
			"text": reason,
			"color": Color(0.9, 0.2, 0.2),
			"duration": 2.0
		})

# Collection Update
func _on_collection_updated(category: String, item_id: String, count: int) -> void:
	show_message({
		"text": "Added to %s collection: %s (Total: %d)" % [category, item_id, count],
		"color": Color(0.2, 0.8, 0.2),
		"duration": 2.0
	})

# Inventory Display
func _on_inventory_state_changed(is_open: bool) -> void:
	if is_open:
		show_inventory()
	else:
		hide_inventory()

func show_inventory() -> void:
	if not inventory_ui:
		inventory_ui = inventory_scene.instantiate()
		add_child(inventory_ui)
	inventory_ui.show()

func hide_inventory() -> void:
	if inventory_ui:
		inventory_ui.hide()

# POI Management
func add_poi(target: Node3D, poi_type: String, icon: Texture2D, label: String = "") -> void:
	if not poi_container or not target or target in active_pois:
		return
		
	var marker = poi_marker_scene.instantiate()
	poi_container.add_child(marker)
	marker.setup(target, icon, label)
	active_pois[target] = marker
	
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

# Game State Handling
func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.PAUSED:
			# Handle pause state UI changes if needed
			pass
		GameManager.GameState.PLAYING:
			# Handle resume state UI changes if needed
			pass

func _exit_tree() -> void:
	clear_all_pois()
