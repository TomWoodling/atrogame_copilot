extends Area3D

@export var auto_interact: bool = false
var encounter_type: String = "info"
var custom_message: String = ""
var player_in_range: bool = false
var interaction_count: int = 0

func configure(config: Dictionary) -> void:
	encounter_type = config.type
	
	# Set appropriate collision shape size based on type
	var shape: BoxShape3D = $CollisionShape3D.shape as BoxShape3D
	if shape:
		match encounter_type:
			"npc": shape.size = Vector3(2.0, 1.5, 2.0)
			"collection": shape.size = Vector3(1.5, 1.0, 1.5)
			"info": shape.size = Vector3(1.0, 1.0, 1.0)

	# Set custom message based on location or type if needed
	custom_message = _get_contextual_message(config)

func _get_contextual_message(config: Dictionary) -> String:
	# Example of contextual messages based on terrain or position
	var height : float = config.terrain_height
	if height > 3.0:
		return "The view from up here is breathtaking!"
	elif height < -2.0:
		return "Be careful in these low areas..."
	
	# Default type-based messages
	match encounter_type:
		"info": return "Press E to learn more"
		"npc": return "A fellow astronaut waves at you"
		"collection": return "Valuable resources detected"
		_: return ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or not event.is_action_pressed("interact"):
		return
		
	handle_interaction()

func handle_interaction() -> void:
	match encounter_type:
		"info":
			_handle_info_interaction()
		"npc":
			_handle_npc_interaction()
		"collection":
			_handle_collection_interaction()

func _handle_info_interaction() -> void:
	# Info encounters are one-shot
	if interaction_count == 0:
		EncounterManager.start_encounter(EncounterManager.EncounterType.INFO, custom_message)
		interaction_count += 1
	else:
		EncounterManager.complete_encounter()

func _handle_npc_interaction() -> void:
	# NPCs have a two-step interaction: initiate dialog, then complete
	if interaction_count == 0:
		EncounterManager.start_encounter(EncounterManager.EncounterType.NPC, custom_message)
		interaction_count += 1
		HUDManager.show_message({
			"text": "Press E to continue dialog",
			"color": Color.WHITE,
			"duration": 2.0
		})
	else:
		EncounterManager.complete_encounter()
		# Reset for potential future interactions
		interaction_count = 0

func _handle_collection_interaction() -> void:
	# Collection is one-shot but might need confirmation
	if interaction_count == 0:
		EncounterManager.start_encounter(EncounterManager.EncounterType.COLLECTION)
		interaction_count += 1
		HUDManager.show_message({
			"text": "Press E to collect",
			"color": Color.WHITE,
			"duration": 2.0
		})
	else:
		EncounterManager.complete_encounter()
		get_parent().cleanup()  # This will remove the collectable

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
		
	player_in_range = true
	
	if auto_interact:
		handle_interaction()
	else:
		HUDManager.show_message({
			"text": "Press E to interact",
			"color": Color.WHITE,
			"duration": 1.0
		})

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
