extends Node

signal inventory_opened
signal inventory_closed
signal item_collected(item_id: int, current_count: int, target_count: int)
signal mission_completed(mission_id: int)
signal achievement_unlocked(achievement_id: int)

enum InventoryTab { MISSIONS, COLLECTIONS, ENCOUNTERS, ACHIEVEMENTS }

# Mission tracking with numeric IDs
var current_mission_id: int = 0
var current_mission_items: Dictionary = {}  # {item_id: {current: int, target: int}}
var is_mission_active: bool = false

# Collections using numeric IDs and matching ScannerManager categories
var collections: Dictionary = {
	"EXOBIOLOGY": {},  # {item_id: CollectionData}
	"EXOBOTANY": {},
	"EXOGEOLOGY": {},
	"ARTIFACTS": {}
}

# Achievement tracking with numeric IDs
var achievements: Dictionary = {}  # {achievement_id: AchievementData}

# Category achievement thresholds
const ACHIEVEMENT_TIERS := {
	"NOVICE": 5,
	"EXPERIENCED": 15,
	"MASTER": 25
}

const TOTAL_COLLECTION_TIERS := {
	"BEGINNER": 10,
	"ADVANCED": 50,
	"ELITE": 100
}

# Achievement IDs (ensures consistent reference)
const ACHIEVEMENT_IDS := {
	"NOVICE_EXOBIOLOGY": 1001,
	"EXPERIENCED_EXOBIOLOGY": 1002,
	"MASTER_EXOBIOLOGY": 1003,
	"NOVICE_EXOBOTANY": 1004,
	"EXPERIENCED_EXOBOTANY": 1005,
	"MASTER_EXOBOTANY": 1006,
	"NOVICE_EXOGEOLOGY": 1007,
	"EXPERIENCED_EXOGEOLOGY": 1008,
	"MASTER_EXOGEOLOGY": 1009,
	"NOVICE_ARTIFACTS": 1010,
	"EXPERIENCED_ARTIFACTS": 1011,
	"MASTER_ARTIFACTS": 1012,
	"BEGINNER_COLLECTOR": 1013,
	"ADVANCED_COLLECTOR": 1014,
	"ELITE_COLLECTOR": 1015
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("gameplay_pause")
	GameManager.inventory_state_changed.connect(_on_inventory_state_changed)
	ScannerManager.scan_completed.connect(_on_scan_completed)

func _on_scan_completed(_target: Node3D, scan_data: Dictionary) -> void:
	var category = ScannerManager.ScanCategory.keys()[scan_data.category]
	var item_id: int = scan_data.id
	
	if not collections[category].has(item_id):
		# First time collection
		collections[category][item_id] = {
			"count": 0,
			"first_found": scan_data.timestamp,
			"last_found": scan_data.timestamp,
			"label": scan_data.label,
			"description": scan_data.description,
			"locations": [],
			"rarity_tier": scan_data.rarity_tier
		}
		
		_check_collection_achievements(category)
	
	# Update existing entry
	var item = collections[category][item_id]
	item.count += 1
	item.last_found = scan_data.timestamp
	item.locations.append(scan_data.location)
	
	# Mission check using numeric ID
	if is_mission_active and current_mission_items.has(item_id):
		collect_mission_item(item_id)
	
	# Update HUD
	HUDManager.show_collection_notification({
		"label": "New Discovery: %s" % scan_data.label if item.count == 1 else "%s collected" % scan_data.label,
		"category": category,
		"rarity_tier": scan_data.rarity_tier
	})

func _check_collection_achievements(category: String) -> void:
	var category_count = collections[category].size()
	
	# Check category-specific achievements
	for tier in ACHIEVEMENT_TIERS:
		if category_count == ACHIEVEMENT_TIERS[tier]:
			var achievement_id = ACHIEVEMENT_IDS["%s_%s" % [tier, category]]
			_unlock_achievement(achievement_id)
	
	# Check total collection achievements
	var total_items = 0
	for cat in collections:
		total_items += collections[cat].size()
	
	for tier_name in TOTAL_COLLECTION_TIERS:
		if total_items == TOTAL_COLLECTION_TIERS[tier_name]:
			var achievement_id = ACHIEVEMENT_IDS["%s_COLLECTOR" % tier_name]
			_unlock_achievement(achievement_id)

func _unlock_achievement(achievement_id: int) -> void:
	if not achievements.has(achievement_id) or not achievements[achievement_id].unlocked:
		achievements[achievement_id] = {
			"unlocked": true,
			"timestamp": Time.get_unix_time_from_system()
		}
		achievement_unlocked.emit(achievement_id)

# Mission Management
func start_collection_mission(mission_id: int, item_id: int, target_count: int) -> void:
	if is_mission_active:
		return
		
	current_mission_id = mission_id
	current_mission_items[item_id] = {
		"current": 0,
		"target": target_count
	}
	is_mission_active = true
	
	# Get item label from collections if available
	var item_label = "Unknown Item"
	for category in collections:
		if collections[category].has(item_id):
			item_label = collections[category][item_id].label
			break
	
	EncounterManager.report_mission_status("Mission started: Collect %d %s" % [
		target_count, 
		item_label
	])

func collect_mission_item(item_id: int) -> void:
	if not is_mission_active or not current_mission_items.has(item_id):
		return
		
	var mission_item = current_mission_items[item_id]
	mission_item.current += 1
	
	item_collected.emit(item_id, mission_item.current, mission_item.target)
	
	if mission_item.current >= mission_item.target:
		_complete_mission()

func _complete_mission() -> void:
	mission_completed.emit(current_mission_id)
	EncounterManager.report_mission_status("Mission Complete!")
	
	current_mission_id = 0
	current_mission_items.clear()
	is_mission_active = false

# Add these functions to the existing inventory_manager.gd

func _on_inventory_state_changed(is_open: bool) -> void:
	if is_open:
		# Show inventory UI
		HUDManager.show_inventory_panel(get_current_inventory_data())
		inventory_opened.emit()
	else:
		HUDManager.hide_inventory_panel()
		inventory_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if GameManager.current_state == GameManager.GameState.PLAYING:
			GameManager.toggle_inventory()

# Helper function to get formatted inventory data for UI
func get_current_inventory_data() -> Dictionary:
	var data := {
		"missions": _get_active_mission_data(),
		"collections": _format_collections_for_display(),
		"achievements": _format_achievements_for_display()
	}
	return data

func _get_active_mission_data() -> Dictionary:
	if not is_mission_active:
		return {}
		
	var mission_data := {}
	for item_id in current_mission_items:
		var mission_item = current_mission_items[item_id]
		var item_label = "Unknown Item"
		var category = ""
		
		# Find item details in collections if available
		for cat in collections:
			if collections[cat].has(item_id):
				item_label = collections[cat][item_id].label
				category = cat
				break
				
		mission_data[item_id] = {
			"label": item_label,
			"category": category,
			"current": mission_item.current,
			"target": mission_item.target,
			"progress": float(mission_item.current) / float(mission_item.target)
		}
	
	return mission_data

func _format_collections_for_display() -> Dictionary:
	var formatted := {}
	for category in collections:
		formatted[category] = {}
		for item_id in collections[category]:
			var item = collections[category][item_id]
			formatted[category][item_id] = {
				"label": item.label,
				"count": item.count,
				"description": item.description,
				"first_found": item.first_found,
				"last_found": item.last_found,
				"rarity_tier": item.rarity_tier
			}
	return formatted

func _format_achievements_for_display() -> Dictionary:
	var formatted := {}
	
	# Add all possible achievements (unlocked or not)
	for achievement_name in ACHIEVEMENT_IDS:
		var id = ACHIEVEMENT_IDS[achievement_name]
		formatted[id] = {
			"label": _get_achievement_label(achievement_name),
			"unlocked": achievements.has(id) and achievements[id].unlocked,
			"timestamp": achievements[id].timestamp if achievements.has(id) else 0
		}
	
	return formatted

func _get_achievement_label(achievement_name: String) -> String:
	# Convert achievement ID to display text
	# Example: "NOVICE_EXOBIOLOGY" -> "Novice Exobiologist"
	var parts = achievement_name.split("_")
	
	match parts[0]:
		"NOVICE":
			return "Novice " + _format_category_title(parts[1])
		"EXPERIENCED":
			return "Experienced " + _format_category_title(parts[1])
		"MASTER":
			return "Master " + _format_category_title(parts[1])
		"BEGINNER":
			return "Beginner Collector"
		"ADVANCED":
			return "Advanced Collector"
		"ELITE":
			return "Elite Collector"
		_:
			return achievement_name.capitalize()

func _format_category_title(category: String) -> String:
	match category:
		"EXOBIOLOGY":
			return "Exobiologist"
		"EXOBOTANY":
			return "Exobotanist"
		"EXOGEOLOGY":
			return "Exogeologist"
		"ARTIFACTS":
			return "Archaeologist"
		_:
			return category.capitalize()
