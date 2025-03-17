extends Node

signal inventory_opened
signal inventory_closed
signal item_collected(item_id: String, current_count: int, target_count: int)
signal collection_updated(category: String, item_id: String, count: int)

@export var is_mission_active : bool = false

enum InventoryTab { MISSIONS, COLLECTIONS, ENCOUNTERS, ACHIEVEMENTS }

# Collection categories match scannable object types
var collections: Dictionary = {
	"EXOBIOLOGY": {},
	"EXOBOTANY": {},
	"EXOGEOLOGY": {},
	"ARTIFACTS": {}
}

var npc_encounters: Dictionary = {}
var achievements: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("gameplay_pause")
	GameManager.inventory_state_changed.connect(_on_inventory_state_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if GameManager.current_state == GameManager.GameState.PLAYING:
			GameManager.toggle_inventory()

func _on_inventory_state_changed(is_open: bool) -> void:
	if is_open:
		emit_signal("inventory_opened")
	else:
		emit_signal("inventory_closed")

# Collection Management
# New method to handle collection_data from scannable objects
# New fixed version of add_collected_item
# Modified version of add_collected_item to include icon_path and rarity_tier
func add_collected_item(collection_data: Dictionary) -> void:
	var category_enum = collection_data.get("category", 0)
	var item_id = collection_data.get("id", "")
	
	# Convert category_enum (int) to category string
	var category = ""
	match category_enum:
		0: category = "EXOBIOLOGY"
		1: category = "EXOBOTANY" 
		2: category = "EXOGEOLOGY"
		3: category = "ARTIFACTS"
	
	if not collections.has(category) or str(item_id).is_empty():
		push_warning("Invalid collection data received: category=%s, id=%s" % [category, item_id])
		return
		
	# Convert item_id to string if it's coming from CollectionItemData
	var item_id_str = str(item_id)
	
	if not collections[category].has(item_id_str):
		collections[category][item_id_str] = {
			"count": 0,
			"first_found": Time.get_unix_time_from_system(),
			"description": collection_data.get("description", _get_item_description(item_id_str)),
			"label": collection_data.get("label", item_id_str),
			"icon_path": collection_data.get("icon_path", ""),
			"rarity_tier": collection_data.get("rarity_tier", 1)
		}
	
	collections[category][item_id_str].count += 1
	collection_updated.emit(category, item_id_str, collections[category][item_id_str].count)
	_check_collection_achievements(category)

# Kept for backward compatibility with other systems
func add_scanned_item(item_id: String, category: String) -> void:
	add_collected_item({
		"id": item_id,
		"category": category,
		"description": _get_item_description(item_id),
		"label": item_id
	})

# Data Access
func get_collection_data(category: String) -> Dictionary:
	return collections.get(category, {})

func get_collection_progress(category: String) -> Dictionary:
	var data = collections.get(category, {})
	var total_items = data.size()
	var items_found = 0
	
	for item in data.values():
		if item.count > 0:
			items_found += 1
			
	return {
		"total": total_items,
		"found": items_found,
		"percentage": float(items_found) / float(total_items) if total_items > 0 else 0.0
	}

# Achievement Checking
func _check_collection_achievements(category: String) -> void:
	var progress = get_collection_progress(category)
	if progress.percentage >= 1.0:
		# Future: Implement achievement system
		pass

# Helper Functions
func _get_item_description(item_id: String) -> String:
	# Future: Load from configuration
	return "A mysterious %s" % item_id

func get_collection_categories() -> Array:
	return collections.keys()

# New helper function to check if an item exists in a collection
func has_collected_item(category: String, item_id: String) -> bool:
	return collections.has(category) and collections[category].has(item_id) and collections[category][item_id].count > 0

# New helper function to get specific item data
func get_item_data(category: String, item_id: String) -> Dictionary:
	if not collections.has(category) or not collections[category].has(item_id):
		return {}
	return collections[category][item_id]
