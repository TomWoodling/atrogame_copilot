extends CanvasLayer

var score_label: Label
var health_label: Label

func _ready() -> void:
	score_label = $ScoreLabel
	health_label = $HealthLabel

func show_message(message: String, type: String = "INFO") -> void:
	var message_label: Label = $MessageLabel
	message_label.text = message
	message_label.show()
	await get_tree().create_timer(3.0).timeout
	message_label.hide()

func update_score(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score

func update_health(new_health: int) -> void:
	health_label.text = "Health: %d" % new_health
