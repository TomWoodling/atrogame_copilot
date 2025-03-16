extends Control

@onready var progress_bar: ProgressBar = $VBoxContainer/ScanProgress
@onready var target_info: Label = $VBoxContainer/TargetInfo
@onready var range_indicator: TextureProgressBar = $VBoxContainer/RangeIndicator

var current_target: Node3D = null

func _ready() -> void:
	GameManager.game_state_changed.connect(_on_game_state_changed)
	
func _process(_delta: float) -> void:
	if not visible or not current_target:
		return
		
	if GameManager.gameplay_state != GameManager.GameplayState.SCANNING:
		get_parent().hide_element()
		return
		
	if ScannerManager.is_scanning and is_instance_valid(current_target):
		progress_bar.value = ScannerManager.scan_progress * 100
		
		var distance = GameManager.player.global_position.distance_to(current_target.global_position)
		range_indicator.value = (1.0 - distance / ScannerManager.SCAN_RANGE) * 100

# This method is called by HUDManager
func _on_scan_started(target: Node3D) -> void:
	if not target is ScannableObject:
		return
		
	current_target = target
	GameManager.start_scanning()
	
	progress_bar.value = 0
	if target is ScannableObject and target.collection_data:
		target_info.text = target.collection_data.label
	else:
		target_info.text = "Unknown Object"
	
	get_parent().show_element()

# This method is called by HUDManager
func _on_scan_completed(_target: Node3D, _data: Dictionary) -> void:
	GameManager.stop_scanning()
	get_parent().hide_element()
	current_target = null

# This method is called by HUDManager
func _on_scan_failed(_reason: String) -> void:
	GameManager.stop_scanning()
	get_parent().hide_element()
	current_target = null

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	if new_state != GameManager.GameState.PLAYING:
		get_parent().hide_element()
