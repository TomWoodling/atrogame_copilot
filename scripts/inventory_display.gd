extends Control

const TAB_COLORS = {
	"missions": Color(0.2, 0.7, 0.9, 0.8),  # Cyan for active tasks
	"collections": Color(0.2, 0.9, 0.2, 0.8),  # Green for discoveries
	"encounters": Color(0.9, 0.7, 0.2, 0.8),  # Warm yellow for NPCs
	"achievements": Color(0.9, 0.2, 0.7, 0.8)  # Magenta for achievements
}

@onready var tab_container: TabContainer = $MarginContainer/TabContainer
@onready var backdrop: ColorRect = $Backdrop

var current_tab: String = "missions"

func _ready() -> void:
	# Ensure we start hidden
	hide()
	backdrop.color = Color(0.1, 0.1, 0.15, 0.85)
	_setup_tabs()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if GameManager.current_state == GameManager.GameState.PLAYING:
			GameManager.toggle_inventory()
	elif event.is_action_pressed("ui_cancel"):
		if self.visible:
			# Let GameManager handle the state transition
			GameManager.return_to_normal_state()
		
func show_inventory() -> void:
	self.visible = true
	_populate_data()
	
	# Smooth fade in
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _close_inventory() -> void:
	# Smooth fade out and proper state transition
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): 
		self.visible = false
		GameManager.toggle_inventory()
	)

func _setup_tabs() -> void:
	tab_container.tab_changed.connect(_on_tab_changed)
	
	# Add a slight glow effect to tab text using proper theme styling
	for tab_idx in tab_container.get_tab_count():
		var tab_title = tab_container.get_tab_title(tab_idx).to_lower()
		if TAB_COLORS.has(tab_title):
			var stylebox = StyleBoxFlat.new()
			stylebox.bg_color = TAB_COLORS[tab_title]
			stylebox.corner_radius_top_left = 4
			stylebox.corner_radius_top_right = 4
			
			# Use proper theme override for tab styling
			tab_container.add_theme_stylebox_override("tab_selected", stylebox)
			tab_container.add_theme_stylebox_override("tab_unselected", stylebox.duplicate())

func _on_tab_changed(tab_idx: int) -> void:
	var tab_name = tab_container.get_tab_title(tab_idx).to_lower()
	current_tab = tab_name
	_refresh_tab_content(tab_name)

func _populate_data() -> void:
	_populate_missions()
	_populate_collections()
	_populate_encounters()

func _populate_missions() -> void:
	var mission_container = tab_container.get_node("Missions/ScrollContainer/MissionList")
	_clear_container(mission_container)
	
	if InventoryManager.is_mission_active:
		_create_mission_display(mission_container, 
			InventoryManager.current_mission_items,
			InventoryManager.current_mission_id)
	else:
		_add_flavor_text(mission_container, 
			"No active missions...\nPerhaps someone needs your help?",
			TAB_COLORS["missions"])

func _create_mission_display(container: Control, mission_data: Dictionary, mission_id: String) -> void:
	# For now, create a simple label display until we have the mission_entry scene
	var mission_box = PanelContainer.new()
	var vbox = VBoxContainer.new()
	mission_box.add_child(vbox)
	
	var title = Label.new()
	title.text = mission_id.capitalize()
	vbox.add_child(title)
	
	for item_id in mission_data:
		var item = mission_data[item_id]
		var progress = Label.new()
		progress.text = "Progress: %d/%d" % [item.current, item.target]
		vbox.add_child(progress)
	
	container.add_child(mission_box)

func _populate_collections() -> void:
	var collection_tabs = tab_container.get_node("Collections/CollectionTabs")
	
	for category in InventoryManager.collections.keys():
		var category_container = collection_tabs.get_node("%s/List" % category.capitalize())
		_clear_container(category_container)
		
		var items = InventoryManager.collections[category]
		if items.is_empty():
			_add_flavor_text(category_container, 
				_get_empty_collection_message(category),
				TAB_COLORS["collections"])
		else:
			_create_collection_display(category_container, items)

func _create_collection_display(container: Control, items: Dictionary) -> void:
	for item_id in items:
		var item_box = PanelContainer.new()
		var vbox = VBoxContainer.new()
		item_box.add_child(vbox)
		
		var name_label = Label.new()
		name_label.text = item_id.capitalize()
		vbox.add_child(name_label)
		
		var count_label = Label.new()
		count_label.text = "Found: %d" % items[item_id].count
		vbox.add_child(count_label)
		
		container.add_child(item_box)

func _populate_encounters() -> void:
	var encounter_list = tab_container.get_node("Encounters/ScrollContainer/EncounterList")
	_clear_container(encounter_list)
	
	if InventoryManager.npc_encounters.is_empty():
		_add_flavor_text(encounter_list,
			"No encounters logged.\nFeeling lonely? Go make some friends!",
			TAB_COLORS["encounters"])
	else:
		_create_encounter_display(encounter_list, InventoryManager.npc_encounters)

func _create_encounter_display(container: Control, encounters: Dictionary) -> void:
	for npc_id in encounters:
		var npc_box = PanelContainer.new()
		var vbox = VBoxContainer.new()
		npc_box.add_child(vbox)
		
		var name_label = Label.new()
		name_label.text = npc_id.capitalize()
		vbox.add_child(name_label)
		
		var met_date = Label.new()
		met_date.text = "First met: %s" % Time.get_datetime_string_from_unix_time(encounters[npc_id].first_met)
		vbox.add_child(met_date)
		
		container.add_child(npc_box)

func _get_empty_collection_message(category: String) -> String:
	match category:
		"exobiology":
			return "No lifeforms catalogued yet.\nThey're probably just shy..."
		"exobotany":
			return "Plant database empty.\nThey must be well-camouflaged..."
		"exogeology":
			return "No interesting rocks found.\nDon't take them for granite!"
		"artifacts":
			return "Nothing collected yet.\nKeep exploring, space cowboy!"
		_:
			return "Nothing here yet!"

func _add_flavor_text(container: Control, text: String, color: Color) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)

func _clear_container(container: Control) -> void:
	if container:
		for child in container.get_children():
			child.queue_free()

func _refresh_tab_content(tab_name: String) -> void:
	match tab_name:
		"missions":
			_populate_missions()
		"collections":
			_populate_collections()
		"encounters":
			_populate_encounters()
