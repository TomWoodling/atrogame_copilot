extends Node

enum State {
	STARTING,
	MOVING,
	FINISHING,
	FINISHED,
	INTERACTING,
	PAUSED
	}

@export var current_state : State = State.STARTING
@export var text_representation: String
@onready var in_course = false

func _ready():
	current_state = State.STARTING
	text_representation = State.find_key(current_state)
# Called when the node enters the scene tree for the first time.
func set_state(target_state):
	current_state = target_state
	text_representation = State.find_key(current_state)
	
func get_state() -> String:
	return text_representation
