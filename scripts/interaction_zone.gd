# interaction_zone.gd (modified)
extends Area3D

signal interaction_available(npc: NPController)
signal interaction_unavailable

# Configuration
@export var auto_interact: bool = false
@export var prompt_text: String = "Press E to interact"
@export_node_path("NPController") var npc_path: NodePath
@export var dialog_id: String = ""

# Runtime state
var player_in_range: bool = false
var interaction_count: int = 0
var npc: NPController = null

func _ready() -> void:
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Get NPC reference if provided
	if not npc_path.is_empty():
		npc = get_node(npc_path)

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
	
	emit_signal("interaction_available", npc)
	
	if auto_interact:
		trigger_interaction()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		emit_signal("interaction_unavailable")

func trigger_interaction() -> void:
	# Start NPC encounter
	if npc:
		EncounterManager.start_encounter(npc, dialog_id)
