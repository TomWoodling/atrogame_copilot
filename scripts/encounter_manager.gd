extends Node

signal encounter_started(type: EncounterType)
signal encounter_completed(type: EncounterType)

enum EncounterType { INFO, COLLECTION, NPC }

# Store messages that can be reused throughout the game
const MESSAGES = {
	"tutorial_movement": "Use WASD to move and Space to jump",
	"tutorial_interact": "Press E to interact with objects",
	"low_oxygen": "Warning: Oxygen levels critical in this area!",
	"resource_rich": "Scanners detect valuable resources nearby"
}

var current_encounter: EncounterType = EncounterType.INFO
var is_encounter_active: bool = false

func start_encounter(type: EncounterType, custom_message: String = "") -> void:
	if is_encounter_active:
		return
		
	current_encounter = type
	is_encounter_active = true
	
	match type:
		EncounterType.INFO:
			_show_info_message(custom_message)
		EncounterType.NPC:
			_start_npc_encounter(custom_message)
		EncounterType.COLLECTION:
			_start_collection_encounter()
	
	emit_signal("encounter_started", type)

func complete_encounter() -> void:
	if not is_encounter_active:
		return
	
	match current_encounter:
		EncounterType.COLLECTION:
			HUDManager.show_message({
				"text": "Item collected!",
				"color": Color.GREEN,
				"duration": 1.0
			})
		EncounterType.NPC:
			HUDManager.show_message({
				"text": "Conversation complete",
				"color": Color.GREEN,
				"duration": 1.0
			})
	
	is_encounter_active = false
	emit_signal("encounter_completed", current_encounter)
	current_encounter = EncounterType.INFO

func _show_info_message(message: String) -> void:
	HUDManager.show_message({
		"text": message if message else "No message provided",
		"color": Color(0.9, 0.9, 0.2),
		"duration": 3.0
	})

func _start_npc_encounter(dialog: String) -> void:
	HUDManager.show_message({
		"text": dialog if dialog else "Hello, fellow astronaut!",
		"color": Color(0.2, 0.7, 0.9),
		"duration": 3.0
	})

func _start_collection_encounter() -> void:
	HUDManager.show_message({
		"text": "Valuable resource detected",
		"color": Color(0.2, 0.9, 0.2),
		"duration": 2.0
	})

func report_mission_status(message: String) -> void:
	HUDManager.show_message({
		"text": message,
		"color": Color.YELLOW,
		"duration": 2.0
	})
