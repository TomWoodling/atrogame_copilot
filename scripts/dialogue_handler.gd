extends Node

# Dialog system state
var dialog_queue : Array = []
var current_turn : int = 0
@export var alien_name : String
@export var player_name : String = "Snaut"

enum DialogueState {
	WAITING_FOR_INPUT,
	DIALOGUE,
	MUTE
}

@onready var dialog_state : DialogueState = DialogueState.MUTE

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GameManager.dialog_active_flag == true:
		if dialog_state in [DialogueState.MUTE]:
			dialog_state = DialogueState.WAITING_FOR_INPUT
	if Input.is_action_just_pressed("ui_accept") and dialog_state not in [DialogueState.MUTE,DialogueState.DIALOGUE]:
		show_next_dialog()
	
func show_next_dialog():
	if current_turn < dialog_queue.size():
		var turn = dialog_queue[current_turn]
		#print(AlienManager.get_state())
		AlienManager.set_state(turn["alien_state"])
		if turn["speaker"] == alien_name:
			emit_signal("make_alien_sound")

		else:
			emit_signal("make_player_sound")

		
		# Move to the next turn in the dialog
		current_turn += 1

		# Update state: waiting for input after the NPC's turn
		dialog_state = DialogueState.DIALOGUE
		await get_tree().create_timer(1).timeout
		dialog_state = DialogueState.WAITING_FOR_INPUT
	else:
		# End the dialog when no more turns remain
		#print(state)
		if dialog_state not in [DialogueState.MUTE]:
			dialog_state = DialogueState.MUTE
			emit_signal("talk_ends")
		current_turn = 10
		
func _reset_dialog_queue(new_queue : Array):
	dialog_queue = new_queue
	current_turn = 0
