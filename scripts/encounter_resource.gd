# encounter_resource.gd
extends Resource
class_name EncounterResource

@export var encounter_id: String
@export var npc_id: String
@export var initial_dialog_id: String
@export var completion_dialog_id: String
@export var post_completion_dialog_id: String

# Challenge sequence - can be a single challenge or multiple in sequence
@export var challenges: Array[ChallengeResource] = []

# Completion criteria
@export var require_all_challenges: bool = true
@export var encounter_flags: Dictionary = {}

# Rewards
@export var rewards: Dictionary = {}

# Whether this encounter can only happen once
@export var one_time_only: bool = true
