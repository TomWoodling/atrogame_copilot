extends RigidBody3D

@onready var col_shape : CollisionShape3D = %bodyShape
@onready var inv_append : Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	if InventoryManager.scepter_state == InventoryManager.hold_states.HELD:
		_disable_collision()
	inv_append = [
		{"name":"scepter_1","type":"Rhand","Held":false,"Path":"res://scenes/scepter_1.tscn"}
	]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _disable_collision():
	self.collision_layer = 2
	self.collision_mask = 2

func _enable_collision():
	self.collision_layer = 1
	self.collision_mask = 1
