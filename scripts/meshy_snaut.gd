class_name SophiaSkin extends Node3D

@onready var animation_tree = %AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")




func _ready():
	state_machine.travel("Idle")

func idle():
	state_machine.travel("Idle")

func walk():
	state_machine.travel("Walk")
	
func run():
	state_machine.travel("Run")

func fall():
	state_machine.travel("Falling")

func jump():
	state_machine.travel("Jump")

func splat():
	state_machine.travel("Splat")

func stand():
	state_machine.travel("Stand")
