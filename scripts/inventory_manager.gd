extends Node

@onready var inv_manager : Array = []
@onready var right_hand : Array = []
@onready var left_hand : Array = []
@onready var back_attach : Array = []
@onready var active_inv : Array = []
@onready var snaut_path = "res://scenes/snaut_2.tscn"

enum hold_states {
	HELD,
	FREE,
	HIDDEN
}
var scepter_state : hold_states = hold_states.FREE

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _set_inventory_item(inv_asset : Array):
	inv_manager.append_array(inv_asset)

func _set_scepter_state(new_state : hold_states):
	scepter_state = new_state

func _update_inventory():
	active_inv = inv_manager
