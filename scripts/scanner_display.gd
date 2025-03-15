extends Control

@onready var progress_bar: ProgressBar = $ScanProgress
@onready var target_info: Label = $TargetInfo
@onready var range_indicator: TextureProgressBar = $RangeIndicator

var current_target: Node3D = null

func _ready() -> void:
	ScannerManager.scan_started.connect(_on_scan_started)
	ScannerManager.scan_completed.connect(_on_scan_completed)
	ScannerManager.scan_failed.connect(_on_scan_failed)
	
	# Hide initially
	progress_bar.hide()
	target_info.hide()

func _process(_delta: float) -> void:
	if ScannerManager.is_scanning:
		progress_bar.value = ScannerManager.scan_progress * 100
		
		if current_target:
			var distance = GameManager.player.global_position.distance_to(current_target.global_position)
			range_indicator.value = (1.0 - distance / ScannerManager.SCAN_RANGE) * 100

func _on_scan_started(target: Node3D) -> void:
	current_target = target
	progress_bar.show()
	progress_bar.value = 0
	
	if target is ScannableObject:
		target_info.text = target.object_name
	target_info.show()

func _on_scan_completed(_target: Node3D, data: Dictionary) -> void:
	progress_bar.hide()
	target_info.hide()
	current_target = null
	
	# Show completion feedback
	HUDManager.show_message({
		"text": "Scan complete: %s" % data.name,
		"color": Color(0.2, 0.9, 0.2),
		"duration": 2.0
	})

func _on_scan_failed(reason: String) -> void:
	progress_bar.hide()
	target_info.hide()
	current_target = null
	
	HUDManager.show_message({
		"text": "Scan failed: %s" % reason,
		"color": Color(0.9, 0.2, 0.2),
		"duration": 2.0
	})
