extends StaticBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_interaction_zone_body_entered(body):
	if body.is_in_group("player"):
		var message_data = {
		"text": "Encountered a Stage!",
		"color": Color.DEEP_PINK,  # Or any Color you want
		"duration": 3.0       # Duration in seconds
		}
		HUDManager.show_message(message_data)
