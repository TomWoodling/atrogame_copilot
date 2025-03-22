extends ColorRect

#@export var scene_path : String

# Reference to the _AnimationPlayer_ node
@onready var _anim_player : AnimationPlayer = $AnimationPlayer

signal exit_scene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Plays the animation backward to fade in
	_anim_player.play_backwards("Fade")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Function to load the new scene
func _transition_to_scene(scene_path: String) -> void:
	var new_scene = load(scene_path).instantiate()
	_anim_player.play("Fade")
	await(_anim_player.animation_finished)
	# Changes the scene
	emit_signal("exit_scene")
	get_tree().current_scene.queue_free()  # Remove the current scene
	get_tree().root.add_child(new_scene)  # Add the new scene
	get_tree().current_scene = new_scene  # Set the new scene as current
	_anim_player.play_backwards("Fade")
