# npc_controller.gd (updated for Godot 4.3)
extends CharacterBody3D
class_name NPController

# NPC Configuration
@export var npc_name: String = "Generic NPC"
@export_node_path("AnimationPlayer") var animation_player_path: NodePath
@export var dialogue_id: String = ""  # ID for DialogManager to retrieve dialog
@export var interaction_distance: float = 2.0  # How close player needs to be

# Node References
@onready var animation_player: AnimationPlayer = get_node(animation_player_path)

@export var available_encounters: Array[String] = []
var current_encounter_id: String = ""

# Animation States - matches animation names in pascal case
enum AnimState {
	IDLE,
	TALK1,
	TALK2,
	TALK3,
	MOOD1,
	MOOD2,
	DANCE
}

# Animation mappings
const MOOD_ANIMATIONS = {
	"positive": AnimState.MOOD1,
	"negative": AnimState.MOOD2,
	"neutral": AnimState.TALK1
}

const talk_anims = [AnimState.TALK1, AnimState.TALK2, AnimState.TALK3]

# NPC State
var current_state: AnimState = AnimState.IDLE
var is_interactable: bool = true
var has_played_initial_animation: bool = false  # Track if we've played our first animation
var is_in_dialog: bool = false

func _ready() -> void:
	# Validate required components
	if not animation_player:
		push_error("NPC Controller (%s): AnimationPlayer not found at %s" % [npc_name, animation_player_path])
		return
	
	# Initialize idle animation
	play_animation(AnimState.IDLE)

# Get the appropriate encounter for this NPC
func get_appropriate_encounter_id() -> String:
	for encounter_id in available_encounters:
		var encounter = EncounterManager.get_encounter(encounter_id)
		if encounter and (not encounter.one_time_only or not InventoryManager.is_encounter_completed(encounter_id)):
			return encounter_id
	return ""

func play_animation(anim_state: AnimState, force: bool = false) -> void:
	if not animation_player:
		return
		
	# Don't restart current animation unless forced or it's our first animation
	if current_state == anim_state and not force and has_played_initial_animation:
		return
	
	var anim_name = AnimState.keys()[anim_state].to_pascal_case()
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
		current_state = anim_state
		has_played_initial_animation = true

func get_random_talk_animation() -> void:
	# Randomly select between Talk1, Talk2, and Talk3
	play_animation(talk_anims[randi() % talk_anims.size()])

# Called by interaction_zone through encounter_stage
# Modified on_interaction_started
func on_interaction_started() -> void:
	if is_interactable and not is_in_dialog:
		is_in_dialog = true
		get_random_talk_animation()
		
		# Check for available encounters first
		current_encounter_id = get_appropriate_encounter_id()
		if not current_encounter_id.is_empty():  # FIXED: empty() -> is_empty()
			EncounterManager.start_encounter_by_id(current_encounter_id, self)
		else:
			# No encounters available, use default dialog
			if not dialogue_id.is_empty():  # FIXED: empty() -> is_empty()
				# Check if we should use post-completion dialog instead
				var last_encounter = available_encounters if available_encounters.size() > 0 else null
				var encounter = EncounterManager.get_encounter(last_encounter)
				
				if not last_encounter.is_empty() and InventoryManager.is_encounter_completed(last_encounter) and encounter:  # FIXED: empty() -> is_empty()
					# Use post-completion dialog
					var dialog = DialogManager.get_dialog(encounter.post_completion_dialog_id)
					if dialog:
						EncounterManager.start_dialog(dialog)
						return
				
				# Use regular dialog
				EncounterManager.start_encounter(self, dialogue_id)
			else:
				# Fallback for NPCs without specific dialog
				EncounterManager.start_encounter(self, npc_name + ": Hello there, I'm " + npc_name + ".")

# Called when interaction ends
func on_interaction_ended() -> void:
	play_animation(AnimState.IDLE)
	is_in_dialog = false

# Called by encounter system when mood should change
func on_mood_change(is_positive: bool) -> void:
	play_animation(AnimState.MOOD1 if is_positive else AnimState.MOOD2)

# Play animation based on mood string
func play_mood_animation(mood: String) -> void:
	if mood in MOOD_ANIMATIONS:
		play_animation(MOOD_ANIMATIONS[mood])
	else:
		get_random_talk_animation()

# Called when celebrating (e.g., after completing a task)
func celebrate() -> void:
	play_animation(AnimState.DANCE)

# Play specific animation by name (for animation_hint in dialog)
func play_animation_by_name(anim_name: String) -> void:
	if not animation_player:
		return
		
	if anim_name.is_empty():  # FIXED: empty() -> is_empty()
		return
	
	# Try to match with enum first
	for anim_state in AnimState.values():
		if AnimState.keys()[anim_state].to_upper() == anim_name.to_upper():
			play_animation(anim_state)
			return
	
	# If not in enum, try direct animation name
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
		current_state = AnimState.IDLE  # Reset state tracking since we're playing directly
