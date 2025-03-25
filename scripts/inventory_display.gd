extends Control

const TAB_COLORS = {
	"missions": Color(0.2, 0.7, 0.9, 0.8),  # Cyan for active tasks
	"collections": Color(0.2, 0.9, 0.2, 0.8),  # Green for discoveries
	"encounters": Color(0.9, 0.7, 0.2, 0.8),  # Warm yellow for NPCs
	"achievements": Color(0.9, 0.2, 0.7, 0.8)  # Magenta for achievements
}

# Map between category enums and display names
const CATEGORY_NAMES = {
	0: "EXOBIOLOGY",
	1: "EXOBOTANY",
	2: "EXOGEOLOGY",
	3: "ARTIFACTS"
}

# Map between category strings and tab names
const CATEGORY_TABS = {
	"EXOBIOLOGY": "Exobiology",
	"EXOBOTANY": "Exobotany",
	"EXOGEOLOGY": "Exogeology",
	"ARTIFACTS": "Artifacts"
}

@onready var tab_container: TabContainer = $MarginContainer/TabContainer
@onready var backdrop: ColorRect = $Backdrop

var current_tab: String = "missions"

func _ready() -> void:
	# Ensure we start hidden
	hide()
	backdrop.color = Color(0.1, 0.1, 0.15, 0.85)
	_setup_tabs()
	
	# Connect to inventory signals
	InventoryManager.inventory_opened.connect(show_inventory)
	InventoryManager.inventory_closed.connect(hide_inventory)

# Remove _unhandled_input as this will now be handled at the manager level

func show_inventory() -> void:
	self.visible = true
	_populate_data()
	
	# Smooth fade in
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func hide_inventory() -> void:
	# Smooth fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): self.visible = false)

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
	
	# Assuming GameManager still provides these properties
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
	
	# Get all collection categories from the inventory manager
	var categories = InventoryManager.get_collection_categories()
	
	# Process each category
	for category in categories:
		# Get the corresponding tab name for this category
		var tab_name = CATEGORY_TABS.get(category, category.capitalize())
		var category_container = collection_tabs.get_node("%s/List" % tab_name)
		
		if not category_container:
			push_warning("Failed to find container for category: %s" % tab_name)
			continue
			
		_clear_container(category_container)
		
		# Get collection data for this category
		var items = InventoryManager.get_collection_data(category)
		
		# Skip category entry in collections
		if items.has("category"):
			items.erase("category")
		
		if items.is_empty():
			_add_flavor_text(category_container, 
				_get_empty_collection_message(category),
				TAB_COLORS["collections"])
		else:
			_create_collection_display(category_container, items)

func _create_collection_display(container: Control, items: Dictionary) -> void:
	for item_id in items:
		# Skip metadata entries
		if item_id == "category":
			continue
			
		var item_data = items[item_id]
		
		# Skip if this is not actually an item
		if typeof(item_data) != TYPE_DICTIONARY:
			continue
		
		var item_box = PanelContainer.new()
		var hbox = HBoxContainer.new()
		item_box.add_child(hbox)
		
		# Add icon if available
		var icon_path = item_data.get("icon_path", "")
		if not icon_path.is_empty():
			var texture_rect = TextureRect.new()
			var texture = load(icon_path)
			if texture:
				texture_rect.texture = texture
				texture_rect.expand_mode = 3
				texture_rect.custom_minimum_size = Vector2(48, 48)
				hbox.add_child(texture_rect)
		
		# Add text content
		var vbox = VBoxContainer.new()
		hbox.add_child(vbox)
		
		# Create title container with name and rarity
		var title_hbox = HBoxContainer.new()
		vbox.add_child(title_hbox)
		
		# Use label if available, otherwise use ID
		var item_label = item_data.get("label", item_id)
		var name_label = Label.new()
		name_label.text = item_label
		title_hbox.add_child(name_label)
		
		# Add rarity indicator
		var rarity_tier : int = item_data.get("rarity_tier", 1)
		var rarity_label = Label.new()
		rarity_label.text = " ★".repeat(rarity_tier) # Display stars based on rarity
		rarity_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # Gold color
		title_hbox.add_child(rarity_label)
		
		# Show count
		var count = item_data.get("count", 0)
		var count_label = Label.new()
		count_label.text = "Found: %d" % count
		vbox.add_child(count_label)
		
		# Add description if available
		var description = item_data.get("description", "")
		if not description.is_empty():
			var desc_label = Label.new()
			desc_label.text = description
			desc_label.add_theme_font_size_override("font_size", 12)
			desc_label.autowrap_mode = 3
			vbox.add_child(desc_label)
		
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
		"EXOBIOLOGY":
			return "No lifeforms catalogued yet.\nThey're probably just shy..."
		"EXOBOTANY":
			return "Plant database empty.\nThey must be well-camouflaged..."
		"EXOGEOLOGY":
			return "No interesting rocks found.\nDon't take them for granite!"
		"ARTIFACTS":
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
