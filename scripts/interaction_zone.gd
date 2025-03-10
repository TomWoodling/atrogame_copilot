extends Area3D

@export var auto_interact: bool = false
@export_enum("info", "collection", "npc", "challenge") var encounter_type: String = "info"
@export_multiline var custom_message: String = ""  # Multiline for easier editing

var player_in_range: bool = false

func _ready() -> void:
	# Validate exported values
	if encounter_type.is_empty():
		push_warning("No encounter type set, defaulting to INFO")
		encounter_type = "info"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_in_range:
		trigger_interaction()

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
		
	player_in_range = true
	print("entered")
	print(self.global_transform.origin)
	if auto_interact:
		trigger_interaction()
	else:
		HUDManager.show_message({
			"text": "Press E to interact",
			"color": Color.WHITE,
			"duration": 1.0
		})

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func trigger_interaction() -> void:
	var type = EncounterManager.get_type_from_string(encounter_type)
	EncounterManager.start_encounter(type, custom_message)
