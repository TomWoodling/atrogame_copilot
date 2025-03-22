extends CharacterBody3D

@onready var _anim_player : AnimationPlayer = $alien1/AnimationPlayer
@onready var state_machine : AnimationNodeStateMachinePlayback = $alien1/AnimationTree["parameters/playback"]

func _ready():
	AlienManager.set_state(AlienManager.Alien_State.WELCOME)

func _physics_process(_delta):
	if AlienManager.current_state == AlienManager.Alien_State.WELCOME :
		state_machine.travel("Nod")
		#_anim_player.play("Nod")
	elif AlienManager.current_state == AlienManager.Alien_State.TALK1 :
		state_machine.travel("Talk1")
		#_anim_player.play("Talk1")
	elif AlienManager.current_state == AlienManager.Alien_State.TALK2 :
		state_machine.travel("Hmm")
		#_anim_player.play("Talk2")
	elif AlienManager.current_state == AlienManager.Alien_State.OHO :
		state_machine.travel("Oho")
		#_anim_player.play("Oho")
	elif AlienManager.current_state == AlienManager.Alien_State.DANCE :
		state_machine.travel("Dance")
		#_anim_player.play("Dance")
	elif AlienManager.current_state == AlienManager.Alien_State.DRAT :
		state_machine.travel("Drat")
		#_anim_player.play("Drat")
	elif AlienManager.current_state == AlienManager.Alien_State.GESTURE : 
		state_machine.travel("Gesture")
		#_anim_player.play("Gesture")
	else:
		state_machine.travel("Nod")
		#_anim_player.play("Nod")
