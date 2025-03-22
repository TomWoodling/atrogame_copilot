extends Node3D

@onready var orbit_point = %orbitPoint
@onready var rotation_speed: float = 0.05
@onready var alien_node : Node3D = %npc
@onready var player_path : String = "player/snaut2"
@onready var player_node
@onready var player_cam : Camera3D
@onready var level_alien_name : String = "Jlxyr"
@onready var scepter_node = %scepter
@onready var drop_box = %dropBox

# Called when the node enters the scene tree for the first time.
func _ready():
	_level_prep()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	orbit_point.rotate(Vector3.LEFT, rotation_speed * delta)
	look_at_target(alien_node,player_node)
	
func look_at_target(source,target):
	source.look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)

func _level_prep():
	StateManager.set_state(StateManager.State.MOVING)
	player_node = get_node(player_path)
	player_cam = get_node("player/snaut2/CameraPoint/SpringArm3D/Camera3D")
	DialogueHandler.alien_name = level_alien_name
	
func _stash_asset(source : Node3D):
	source.global_transform.origin = drop_box.global_transform.origin
	
func _recover_asset(source : Node3D, target : Node3D):
	source.global_transform.origin = target.global_transform.origin
