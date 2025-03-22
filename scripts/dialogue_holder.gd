extends Node3D

# Dialog system state
var dialog_queue : Array = []
var current_turn : int = 0

# UI elements
@onready var player_dia : Label3D = %diaOne
@onready var alien_dia : Label3D = %diaTwo
@export var player_name : String = "Snaut"
@export var alien_name : String = "Jlyxr"
@onready var cam_pivot : Node3D = %camPivot
@onready var dia_cam : Camera3D = %diaCam

# Signals
signal talk_ends
signal make_player_sound
signal make_alien_sound

# States
enum DialogueState {
	WAITING_FOR_INPUT,
	DIALOGUE,
	MUTE
}
@onready var state : DialogueState = DialogueState.MUTE


# Example usage in _process function or wherever you need it
func _process(delta):
	if GameManager.level_1_dia_flag == true or GameManager.level_1_end_dia_flag == true:
		if state in [DialogueState.MUTE]:
			state = DialogueState.WAITING_FOR_INPUT
	if Input.is_action_just_pressed("ui_accept") and state not in [DialogueState.MUTE,DialogueState.DIALOGUE]:
		show_next_dialog()


# Dialog data, alternating between Player and NPC
func _ready():
	print("ready")
	current_turn = 0
	# Example dialog sequence
	dialog_queue = [
		{"speaker": alien_name, "text": "Hello Snaut, welcome to the Gloobglob nebula!", "alien_state" : AlienManager.Alien_State.TALK1},
		{"speaker": player_name, "text": "Who are you? And how did I get here?", "alien_state" : AlienManager.Alien_State.TALK2},
		{"speaker": alien_name, "text": "I am Jlxyr of the Umygrox - and I am pleased to meet you.", "alien_state" : AlienManager.Alien_State.TALK2},
		{"speaker": player_name, "text": "The last thing I remember was an asteroid field, now I'm here.", "alien_state" : AlienManager.Alien_State.OHO},
		{"speaker": alien_name, "text": "Yes Snaut, and not by accident I think...", "alien_state" : AlienManager.Alien_State.DANCE},
		{"speaker": player_name, "text": "What can I do? How to get home?", "alien_state" : AlienManager.Alien_State.DRAT},
		{"speaker": alien_name, "text": "You must retrieve the Scepter of Prilzyx - it will reveal more.", "alien_state" : AlienManager.Alien_State.GESTURE}
		
	]	

# Show next piece of dialogue
func show_next_dialog():
	if current_turn < dialog_queue.size():
		var turn = dialog_queue[current_turn]
		#print(AlienManager.get_state())
		AlienManager.set_state(turn["alien_state"])
		if turn["speaker"] == alien_name:
			emit_signal("make_alien_sound")
			look_at_target(alien_dia)
			# Update the label text
			alien_dia.text = turn["text"]
			player_dia.text = ""
		else:
			emit_signal("make_player_sound")
			look_at_target(player_dia)
			player_dia.text = turn["text"]
			alien_dia.text = ""
		
		# Move to the next turn in the dialog
		current_turn += 1

		# Update state: waiting for input after the NPC's turn
		state = DialogueState.DIALOGUE
		await get_tree().create_timer(1).timeout
		state = DialogueState.WAITING_FOR_INPUT
	else:
		# End the dialog when no more turns remain
		player_dia.text = ""
		alien_dia.text = ""
		#print(state)
		if state not in [DialogueState.MUTE]:
			state = DialogueState.MUTE
			emit_signal("talk_ends")
		current_turn = 10

func look_at_target(target):
	cam_pivot.look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)

func _set_dialog_queue(new_queue : Array):
	dialog_queue = new_queue
	current_turn = 0
