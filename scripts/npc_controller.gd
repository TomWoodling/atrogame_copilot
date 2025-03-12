extends CharacterBody3D
class_name NPController

# NPC Configuration
@export var npc_name: String = "Generic NPC"
@export_node_path("AnimationPlayer") var animation_player_path: NodePath
@export var dialogue_id: String = ""  # For future dialogue system integration

# Node References
@onready var animation_player: AnimationPlayer = get_node(animation_player_path)

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

# NPC State
var current_state: AnimState = AnimState.IDLE
var is_interactable: bool = true
var has_played_initial_animation: bool = false  # Track if we've played our first animation

func _ready() -> void:
	# Validate required components
	if not animation_player:
		push_error("NPC Controller (%s): AnimationPlayer not found at %s" % [npc_name, animation_player_path])
		return
	
	# Initialize idle animation
	play_animation(AnimState.IDLE)

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
	var talk_anims = [AnimState.TALK1, AnimState.TALK2, AnimState.TALK3]
	play_animation(talk_anims[randi() % talk_anims.size()])

# Called by interaction_zone through encounter_stage
func on_interaction_started() -> void:
	if is_interactable:
		get_random_talk_animation()

# Called when interaction ends
func on_interaction_ended() -> void:
	play_animation(AnimState.IDLE)

# Called by encounter system when mood should change
func on_mood_change(is_positive: bool) -> void:
	play_animation(AnimState.MOOD1 if is_positive else AnimState.MOOD2)

# Called when celebrating (e.g., after completing a task)
func celebrate() -> void:
	play_animation(AnimState.DANCE)
