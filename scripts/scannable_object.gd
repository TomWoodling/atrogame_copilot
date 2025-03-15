extends Node3D
class_name ScannableObject

@export_enum("Exobiology", "Exobotany", "Exogeology", "Artifacts") var scan_category: int = 0
@export var scan_difficulty: float = 0.0  # 0.0 to 1.0
@export var object_name: String = "Unknown Object"
@export_multiline var description: String = "No data available"

var has_been_scanned: bool = false

func get_scan_data() -> Dictionary:
	has_been_scanned = true
	return {
		"name": object_name,
		"category": ScannerManager.ScanCategory.values()[scan_category],
		"description": description,
		"timestamp": Time.get_unix_time_from_system(),
		"location": global_position,
	}

func get_scan_difficulty() -> float:
	return scan_difficulty
