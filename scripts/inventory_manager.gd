extends Node

signal inventory_opened
signal inventory_closed
signal item_collected(item_id: String, current_count: int, target_count: int)
signal mission_completed(mission_id: String)

enum InventoryTab { MISSIONS, COLLECTIONS, ENCOUNTERS, ACHIEVEMENTS }

# Mission tracking
var current_mission_id: String = ""
var current_mission_items: Dictionary = {}  # {item_id: {current: int, target: int}}
var is_mission_active: bool = false

# Collection categories
var collections: Dictionary = {
	"exobiology": {},
	"exobotany": {},
	"exogeology": {},
	"artifacts": {}
}

# NPC encounter records
var npc_encounters: Dictionary = {}

# Achievement tracking
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
		HUDManager.show_inventory()
		emit_signal("inventory_opened")
	else:
		HUDManager.hide_inventory()
		emit_signal("inventory_closed")

func _toggle_inventory() -> void:
	if ProcessManager.current_state == ProcessManager.ProcessState.NORMAL:
		ProcessManager.set_process_state(ProcessManager.ProcessState.DIALOG)
		HUDManager.show_inventory()
		emit_signal("inventory_opened")
	else:
		ProcessManager.set_process_state(ProcessManager.ProcessState.NORMAL)
		HUDManager.hide_inventory()
		emit_signal("inventory_closed")

# Mission Management
func start_collection_mission(mission_id: String, item_id: String, target_count: int) -> void:
	if is_mission_active:
		return
		
	current_mission_id = mission_id
	current_mission_items[item_id] = {
		"current": 0,
		"target": target_count,
		"description": _get_item_description(item_id)
	}
	is_mission_active = true
	
	EncounterManager.report_mission_status("Mission started: Collect %d %s" % [
		target_count, 
		_get_item_name(item_id)
	])

func collect_item(item_id: String) -> void:
	if not is_mission_active or not current_mission_items.has(item_id):
		return
		
	var mission_item = current_mission_items[item_id]
	mission_item.current += 1
	
	# Add to permanent collections
	_add_to_collection(item_id)
	
	emit_signal("item_collected", item_id, mission_item.current, mission_item.target)
	
	if mission_item.current >= mission_item.target:
		_complete_mission()

func _complete_mission() -> void:
	emit_signal("mission_completed", current_mission_id)
	EncounterManager.report_mission_status("Mission Complete!")
	
	current_mission_id = ""
	current_mission_items.clear()
	is_mission_active = false

# Collection Management
func _add_to_collection(item_id: String) -> void:
	var category = _get_item_category(item_id)
	if not collections[category].has(item_id):
		collections[category][item_id] = {
			"count": 0,
			"first_found": Time.get_unix_time_from_system(),
			"description": _get_item_description(item_id)
		}
	collections[category][item_id].count += 1

# NPC Encounter Management
func record_npc_encounter(npc_id: String, dialog_id: String) -> void:
	if not npc_encounters.has(npc_id):
		npc_encounters[npc_id] = {
			"first_met": Time.get_unix_time_from_system(),
			"dialogs": [],
			"missions_given": [],
			"missions_completed": []
		}
	npc_encounters[npc_id].dialogs.append(dialog_id)

# Status Reporting
func get_collection_status(item_id: String) -> String:
	if not is_mission_active or not current_mission_items.has(item_id):
		return ""
		
	var mission_item = current_mission_items[item_id]
	return "%d %s collected, %d remaining" % [
		mission_item.current,
		_get_item_name(item_id),
		mission_item.target - mission_item.current
	]

# Item Information
func _get_item_name(item_id: String) -> String:
	# Future: Load from configuration
	return item_id.capitalize()

func _get_item_description(item_id: String) -> String:
	# Future: Load from configuration
	return "A mysterious %s" % item_id

func _get_item_category(item_id: String) -> String:
	# Future: Load from configuration
	return "artifacts"  # Default category
