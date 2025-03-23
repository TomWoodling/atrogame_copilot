extends Area3D

signal interaction_available(interactable: Node3D)
signal interaction_unavailable

# Configuration
@export var auto_interact: bool = false
@export var prompt_text: String = "Press E to interact"
@export_node_path("NPController") var npc_path: NodePath
@export var encounter_type: EncounterManager.EncounterType = EncounterManager.EncounterType.INFO
@export var encounter_data: String = ""  # Dialog ID or message text

# Runtime state
var player_in_range: bool = false
var interaction_count: int = 0
var interactable_npc: NPController = null

func _ready() -> void:
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Get NPC reference if provided
	if not npc_path.is_empty():
		interactable_npc = get_node(npc_path)

func configure(config: Dictionary) -> void:
	# Set appropriate collision shape size based on type
	var shape_node := $CollisionShape3D
	if shape_node:
		var shape : BoxShape3D = shape_node.shape
		if shape:
			# Create a unique copy of the shape
			var unique_shape := shape.duplicate() as BoxShape3D
			shape_node.shape = unique_shape
			
			match encounter_type:
				EncounterManager.EncounterType.NPC: 
					unique_shape.size = Vector3(2.0, 1.5, 2.0)
				EncounterManager.EncounterType.COLLECTION: 
					unique_shape.size = Vector3(1.5, 1.0, 1.5)
				EncounterManager.EncounterType.INFO: 
					unique_shape.size = Vector3(1.0, 1.0, 1.0)
	
	# Update encounter data if needed based on config
	if "data" in config:
		encounter_data = config.data

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or not event.is_action_pressed("interact"):
		return
		
	trigger_interaction()

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
		
	player_in_range = true
	
	# Show interaction prompt
	HUDManager.show_message({
		"text": prompt_text,
		"color": Color.WHITE,
		"duration": 1.0
	})
	
	# Fix for the incompatible ternary elements error
	var interactable: Node3D = self
	if interactable_npc:
		interactable = interactable_npc
	
	emit_signal("interaction_available", interactable)
	
	if auto_interact:
		trigger_interaction()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		emit_signal("interaction_unavailable")

func trigger_interaction() -> void:
	match encounter_type:
		EncounterManager.EncounterType.INFO:
			_handle_info_interaction()
		EncounterManager.EncounterType.NPC:
			_handle_npc_interaction()
		EncounterManager.EncounterType.COLLECTION:
			_handle_collection_interaction()

func _handle_info_interaction() -> void:
	# Info encounters are one-shot
	if interaction_count == 0:
		EncounterManager.start_encounter(EncounterManager.EncounterType.INFO, encounter_data)
		interaction_count += 1
	else:
		EncounterManager.complete_encounter()

func _handle_npc_interaction() -> void:
	# If we have an associated NPC, use it
	var npc = interactable_npc if interactable_npc else get_parent().current_object as NPController
	
	if npc and interaction_count == 0:
		# Start the encounter
		EncounterManager.start_encounter(EncounterManager.EncounterType.NPC, encounter_data, npc)
		interaction_count += 1
	else:
		# Complete the encounter
		EncounterManager.complete_encounter()
		interaction_count = 0

func _handle_collection_interaction() -> void:
	# Collection is one-shot but might need confirmation
	if interaction_count == 0:
		EncounterManager.start_encounter(EncounterManager.EncounterType.COLLECTION, encounter_data)
		interaction_count += 1
	else:
		EncounterManager.complete_encounter()
		get_parent().cleanup()  # This will remove the collectable
