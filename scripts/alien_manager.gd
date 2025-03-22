extends Node

enum Alien_State {
	WELCOME,
	TALK1,
	TALK2,
	GESTURE,
	DRAT,
	DANCE,
	OHO,
	PAUSED
	}

@export var current_state : Alien_State = Alien_State.WELCOME
@export var text_representation: String
@onready var make_gesture = false

func _ready():
	current_state = Alien_State.WELCOME
	text_representation = Alien_State.find_key(current_state)
	
func set_state(target_state):
	current_state = target_state
	text_representation = Alien_State.find_key(current_state)
	#print(current_state)
	
func get_state() -> String:
	return text_representation
