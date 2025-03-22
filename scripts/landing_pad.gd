extends Node3D

@onready var cam_pivot = %camPivot
@onready var zone_cam : Camera3D = %zoneCam
@onready var rotation_speed: float = 0.3
@onready var land_cloud : CPUParticles3D = %dustCloud
@export var target_scene : String = "res://scenes/landing_zone.tscn"

# Called when the node enters the scene tree for the first time.
func _ready():
	TrackManager.start_track.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	cam_pivot.rotate(Vector3.UP, rotation_speed * delta)


func _on_touchdown_body_entered(body):
	if body.is_in_group("Rocket"):
		land_cloud.emitting = true
		await get_tree().create_timer(5).timeout
		GlobalColorRect._transition_to_scene(target_scene)
