# encounter_resource.gd (Refactored for Godot 4.3)
extends Resource
class_name EncounterResource

## Unique identifier for this specific encounter/quest template.
@export var encounter_id: String = "default_encounter"

## Type or specific ID of the NPC that can offer this encounter.
## Can be used to filter which NPCs can offer which encounters.
@export var offered_by_npc_id: String = "generic_npc"

## Dialog ID to show when the encounter starts.
@export var initial_dialog_id: String = ""

## Dialog ID to show when the associated quest is completed and player talks to NPC again.
@export var completion_dialog_id: String = ""

## Dialog ID to show if player talks to NPC *after* completion dialog was already shown.
@export var post_completion_dialog_id: String = ""

## Quest ID associated with this encounter. The EncounterManager signals this ID,
## QuestManager handles the actual quest logic (acceptance, tracking, completion).
## If empty, this encounter is purely conversational.
@export var associated_quest_id: String = ""

## Can this encounter/quest only be offered and completed once per game?
@export var one_time_only: bool = true

## Optional: Add conditions for when this encounter can be offered
## e.g., player level, prerequisite quests completed, world state flags etc.
## This logic would be checked by EncounterManager.
# @export var prerequisite_flags: Dictionary = {}
# @export var min_player_level: int = 1
