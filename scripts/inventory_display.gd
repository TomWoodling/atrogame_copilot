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
    backdrop.color = Color(0.1, 0.1, 0.15, 0.85)  # Space-y semi-transparent dark blue
    _setup_tabs()
    _populate_data()
    
    # Smooth fade in
    modulate.a = 0
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _setup_tabs() -> void:
    tab_container.tab_changed.connect(_on_tab_changed)
    
    # Add a slight glow effect to tab text
    for tab_idx in tab_container.get_tab_count():
        var tab_title = tab_container.get_tab_title(tab_idx)
        var stylebox = StyleBoxFlat.new()
        stylebox.bg_color = TAB_COLORS[tab_title.to_lower()]
        stylebox.corner_radius_top_left = 4
        stylebox.corner_radius_top_right = 4
        tab_container.set_tab_custom_style(tab_idx, stylebox)

func _on_tab_changed(tab_idx: int) -> void:
    var tab_name = tab_container.get_tab_title(tab_idx).to_lower()
    current_tab = tab_name
    _refresh_tab_content(tab_name)
    
    # Play a subtle sci-fi UI sound
    AudioManager.play_ui_sound("tab_switch")

func _populate_data() -> void:
    _populate_missions()
    _populate_collections()
    _populate_encounters()
    _populate_achievements()

func _populate_missions() -> void:
    var mission_container = tab_container.get_node("Missions/ScrollContainer/MissionList")
    
    if InventoryManager.is_mission_active:
        _add_mission_entry(mission_container, 
            InventoryManager.current_mission_items,
            InventoryManager.current_mission_id)
    else:
        _add_flavor_text(mission_container, 
            "No active missions...\nPerhaps someone needs your help?",
            TAB_COLORS["missions"])

func _add_mission_entry(container: Control, mission_data: Dictionary, mission_id: String) -> void:
    var entry = preload("res://scenes/ui/mission_entry.tscn").instantiate()
    container.add_child(entry)
    entry.setup(mission_data, mission_id)

func _populate_collections() -> void:
    var collection_tabs = tab_container.get_node("Collections/CollectionTabs")
    
    for category in InventoryManager.collections.keys():
        var items = InventoryManager.collections[category]
        if items.is_empty():
            _add_flavor_text(collection_tabs, 
                _get_empty_collection_message(category),
                TAB_COLORS["collections"])
        else:
            for item_id in items:
                var item_data = items[item_id]
                _add_collection_entry(collection_tabs, item_id, item_data)

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

func _populate_encounters() -> void:
    var encounter_list = tab_container.get_node("Encounters/ScrollContainer/EncounterList")
    
    if InventoryManager.npc_encounters.is_empty():
        _add_flavor_text(encounter_list,
            "No encounters logged.\nFeeling lonely? Go make some friends!",
            TAB_COLORS["encounters"])
    else:
        for npc_id in InventoryManager.npc_encounters:
            var npc_data = InventoryManager.npc_encounters[npc_id]
            _add_npc_entry(encounter_list, npc_id, npc_data)

func _add_flavor_text(container: Control, text: String, color: Color) -> void:
    var label = Label.new()
    label.text = text
    label.add_theme_color_override("font_color", color)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    container.add_child(label)

func _refresh_tab_content(tab_name: String) -> void:
    match tab_name:
        "missions":
            _populate_missions()
        "collections":
            _populate_collections()
        "encounters":
            _populate_encounters()
        "achievements":
            _populate_achievements()