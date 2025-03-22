extends Node3D

@onready var start_cam : Camera3D = %startCam
@onready var snaut_cam = "snaut2/CameraPoint/SpringArm3D/Camera3D"
@onready var dia_cam : Camera3D = %diaCam
@onready var dialog_manager = %diaSpace
@onready var alien_npc = %Jlxyr_of_Umygrox
@onready var storage_space = %restStop
@onready var scepter_path = "Scepter_1"
@onready var scepter_course = %scepterStart
@onready var scepter_preview = %scepterPre
@onready var snaut_path = "snaut2"
@onready var scepter_scene_path = "res://scenes/scepter_1.tscn"
@onready var end_dialog : Array = []
@onready var next_scene : String = "res://scenes/fin.tscn"
# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.level_1_dia_flag = false
	GameManager.level_1_scepter_flag = false
	GameManager.level_1_end_dia_flag = false
	var scepter_move : RigidBody3D = get_node(scepter_path)
	scepter_move.global_transform.origin = scepter_preview.global_transform.origin
	#dialog_manager.visible = false
	start_cam.current = true
	StateManager.set_state(StateManager.State.STARTING)
	await get_tree().create_timer(2).timeout
	GlobalColorRect._anim_player.play("Fade")
	GlobalColorRect._anim_player.play_backwards("Fade")
	_dialogue_prep()

	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_dialogue_holder_talk_ends():
	if GameManager.level_1_dia_flag == true:
		_finish_level_1_dia()
	elif GameManager.level_1_end_dia_flag == true:
		_finish_level_1_end_dia()

func _finish_level_1_dia():
	var scepter_move : RigidBody3D = get_node(scepter_path)
	var player_cam : Camera3D = get_node(snaut_cam)
	GlobalColorRect._anim_player.play("Fade")
	#alien_npc.transform.origin = storage_space.transform.origin
	AlienManager.set_state(AlienManager.Alien_State.GESTURE)
	dialog_manager.visible = false
	GameManager.level_1_dia_flag = false
	#start_cam.current = false
	scepter_move.global_transform.origin = scepter_course.global_transform.origin
	GlobalColorRect._anim_player.play_backwards("Fade")
	player_cam.current = true
	StateManager.set_state(StateManager.State.MOVING)

func _finish_level_1_end_dia():
	await get_tree().create_timer(2).timeout
	dialog_manager.visible = false
	GameManager.level_1_end_dia_flag = false
	GlobalColorRect._transition_to_scene(next_scene)

func _dialogue_prep():
	var player_dialog = DialogueHolder.player_dia
	var alien_dialog = DialogueHolder.alien_dia
	var player_speech = get_node("snaut2/snautSpeech")
	var alien_speech = get_node("Jlxyr_of_Umygrox/alienSpeech")
	var alien_name = DialogueHolder.alien_name
	var player_name = DialogueHolder.player_name
	dia_cam.global_transform.origin = dialog_manager.global_transform.origin
	player_dialog.global_transform.origin = player_speech.global_transform.origin
	alien_dialog.global_transform.origin = alien_speech.global_transform.origin
	dia_cam.current = true
	dialog_manager.visible = true
	GameManager.level_1_dia_flag = true
	
func _end_dia_prep():
	var player_dialog = DialogueHolder.player_dia
	var alien_dialog = DialogueHolder.alien_dia
	var player_speech = get_node("snaut2/snautSpeech")
	var alien_speech = get_node("Jlxyr_of_Umygrox/alienSpeech")
	var alien_name = DialogueHolder.alien_name
	var player_name = DialogueHolder.player_name
	var scepter_move : RigidBody3D = get_node(scepter_path)
	var snaut_look = get_node("snaut2/meshy_snaut")
	var snaut_act = get_node(snaut_path)
	
	end_dialog = [
	{"speaker": alien_name, "text": "Welld done Snaut, you have found the scepter!", "alien_state" : AlienManager.Alien_State.DANCE},
	{"speaker": player_name, "text": "It, err, wasn't too difficult...", "alien_state" : AlienManager.Alien_State.DANCE},
	{"speaker": alien_name, "text": "For you perhaps, but my people cannot touch it.", "alien_state" : AlienManager.Alien_State.OHO},
	{"speaker": player_name, "text": "Isn't it an artefact of the Umygrox? How can that be?", "alien_state" : AlienManager.Alien_State.OHO},
	{"speaker": alien_name, "text": "Ah Snaut, you will come to understand many things about our Nebula...", "alien_state" : AlienManager.Alien_State.TALK2},
	{"speaker": player_name, "text": "As I go on a quest, I suppose?", "alien_state" : AlienManager.Alien_State.TALK1},
	{"speaker": alien_name, "text": "Aha you are very perceptive Snaut, but I will let the scepter tell you more.", "alien_state" : AlienManager.Alien_State.GESTURE}
	]
	#print("scepter_return")
	StateManager.set_state(StateManager.State.INTERACTING)
	DialogueHolder._set_dialog_queue(end_dialog)
	snaut_act._r_hand_detach()
	scepter_move._enable_collision()
	scepter_move.global_transform.origin = scepter_preview.global_transform.origin
	player_dialog.global_transform.origin = player_speech.global_transform.origin
	alien_dialog.global_transform.origin = alien_speech.global_transform.origin
	snaut_look.look_at(Vector3(alien_npc.global_position.x, global_position.y, alien_npc.global_position.z), Vector3.UP)
	dia_cam.current = true
	dialog_manager.visible = true
	GameManager.level_1_end_dia_flag = true
	
func _on_course_area_body_entered(body):
	if body.is_in_group("Snauts"):
		StateManager.in_course = true

func _on_course_area_body_exited(body):
	if body.is_in_group("Snauts"):
		StateManager.in_course = false

func _on_scepter_area_body_entered(body):
	if body.is_in_group("Snauts") and GameManager.level_1_scepter_flag == false:
		print("scepter get")
		InventoryManager._set_scepter_state(InventoryManager.hold_states.HELD)
		StateManager.set_state(StateManager.State.INTERACTING)
		GameManager.level_1_scepter_flag = true
		var scepter_move : RigidBody3D = get_node(scepter_path)
		scepter_move.global_transform.origin = storage_space.global_transform.origin
		var snaut_scene = get_node(snaut_path)
		snaut_scene._r_hand_attach(scepter_scene_path)
		StateManager.set_state(StateManager.State.MOVING)

func _on_end_zone_body_entered(body):
	if body.is_in_group("Snauts") and GameManager.level_1_scepter_flag == true:
		_end_dia_prep()
