extends Control

@onready var progress_bar: ProgressBar = $HUDElement/VBoxContainer/ScanProgress
@onready var target_info: Label = $HUDElement/VBoxContainer/TargetInfo
@onready var range_indicator: TextureProgressBar = $HUDElement/VBoxContainer/RangeIndicator

var current_target: Node3D = null

func _ready() -> void:
	ScannerManager.scan_started.connect(_on_scan_started)
	ScannerManager.scan_completed.connect(_on_scan_completed)
	ScannerManager.scan_failed.connect(_on_scan_failed)
	
	# Hide initially
	progress_bar.hide()
	target_info.hide()

func _process(_delta: float) -> void:
	if ScannerManager.is_scanning and current_target:
		progress_bar.value = ScannerManager.scan_progress * 100
		
		var distance = GameManager.player.global_position.distance_to(current_target.global_position)
		range_indicator.value = (1.0 - distance / ScannerManager.SCAN_RANGE) * 100

func _on_scan_started(target: Node3D) -> void:
	if not target is ScannableObject:
		return
		
	current_target = target
	progress_bar.show()
	progress_bar.value = 0
	
	var scannable := target as ScannableObject
	if scannable.collection_data:
		target_info.text = scannable.collection_data.label if scannable.collection_data.label else "Unknown Object"
	target_info.show()

func _on_scan_completed(_target: Node3D, data: Dictionary) -> void:
	progress_bar.hide()
	target_info.hide()
	current_target = null

func _on_scan_failed(reason: String) -> void:
	progress_bar.hide()
	target_info.hide()
	current_target = null

func update_range_indicator(target: Node3D) -> void:
	if target and is_instance_valid(target):
		var distance = GameManager.player.global_position.distance_to(target.global_position)
		var in_range = distance <= ScannerManager.SCAN_RANGE
		range_indicator.value = (1.0 - distance / ScannerManager.SCAN_RANGE) * 100
		range_indicator.modulate = Color.GREEN if in_range else Color.RED
	else:
		range_indicator.value = 0
