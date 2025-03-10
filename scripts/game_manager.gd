extends Node

var player: Node3D
var score: int = 0
var health: int = 100

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func can_player_move() -> bool:
	return health > 0

func start_interaction(zone: InteractionZone) -> void:
	match zone.interaction_type:
		"dialogue":
			HUDManager.show_message(zone.interaction_data["dialogues"][0])
		"collection":
			score += 1
			HUDManager.update_score(score)
			zone.queue_free()
		"challenge":
			HUDManager.show_message("Challenge started!")

func reduce_health(amount: int) -> void:
	health -= amount
	HUDManager.update_health(health)
	if health <= 0:
		_game_over()

func _game_over() -> void:
	HUDManager.show_message("Game Over")
	get_tree().pause = true
