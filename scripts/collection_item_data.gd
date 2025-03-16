extends Resource
class_name CollectionItemData

@export var id: int  # Numeric ID for internal reference
@export_enum("EXOBIOLOGY", "EXOBOTANY", "EXOGEOLOGY", "ARTIFACTS") var category: int
@export var label: String  # Display name/text label
@export_multiline var description: String
@export_file("*.png") var icon_path: String  # Optional icon
@export_file("*.tscn") var model_scene_path: String  # Optional 3D model reference
@export var rarity_tier: int = 1  # Numeric tier instead of arbitrary value
