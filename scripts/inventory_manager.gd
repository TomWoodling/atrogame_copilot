extends Node

signal inventory_opened
signal inventory_closed
signal item_collected(item_id: String, current_count: int, target_count: int)
signal collection_updated(category: String, item_id: String, count: int)

enum InventoryTab { MISSIONS, COLLECTIONS, ENCOUNTERS, ACHIEVEMENTS }

# Collection categories match scannable object types
var collections: Dictionary = {
	"exobiology": {},
	"exobotany": {},
	"exogeology": {},
	"artifacts": {}
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
func add_scanned_item(item_id: String, category: String) -> void:
	if not collections.has(category):
		return
		
	if not collections[category].has(item_id):
		collections[category][item_id] = {
			"count": 0,
			"first_found": Time.get_unix_time_from_system(),
			"description": _get_item_description(item_id)
		}
	
	collections[category][item_id].count += 1
	collection_updated.emit(category, item_id, collections[category][item_id].count)
	_check_collection_achievements(category)

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
