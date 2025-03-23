# Creating Reusable Encounters in Astronaut Game: FAQ Guide

## 1. What's the overall architecture for a reusable encounter system?

The reusable encounter system should be structured with several specialized components that work together:

- **EncounterDefinition**: A resource class that stores all data for an encounter (dialogs, challenges, parameters)
- **EncounterRegistry**: A singleton that manages loading and retrieving encounter definitions
- **EncounterStageManager**: Handles the physical creation and management of challenge stages
- **EncounterFlowController**: Controls the state machine and progression of encounter phases

This separation allows you to define encounters in data files while the logic for running them remains consistent.

## 2. How should I structure the EncounterDefinition resource?

The EncounterDefinition resource should contain:

```gdscript
# encounter_definition.gd
extends Resource
class_name EncounterDefinition

@export var encounter_id: String
@export var npc_id: String
@export var initial_dialog_id: String
@export var completion_dialog_id: String
@export var post_completion_dialog_id: String

@export var challenge_sequence: Array[ChallengeData]
@export var completion_criteria: Dictionary
@export var encounter_flags: Dictionary  # For tracking state/progress

# More properties as needed
```

This way, each encounter is defined by its data rather than hardcoded logic.

## 3. How do I define the challenge sequence?

Create a ChallengeData resource:

```gdscript
# challenge_data.gd
extends Resource
class_name ChallengeData

@export_enum("Collection", "Platforming", "TimedTask", "Puzzle") var type: String
@export var parameters: Dictionary  # Flexible parameters for each challenge type
@export var time_limit: float
@export var success_criteria: Dictionary
@export var failure_criteria: Dictionary
@export var next_challenge_id: String  # For branching logic
```

The parameters dictionary would contain challenge-specific data like:
- Collection: item count, spawn radius, item type
- Platforming: destination position, platform count
- TimedTask: specific task parameters
- Puzzle: puzzle configuration

## 4. How do I manage the encounter state transitions?

Create an encounter state machine in the EncounterFlowController:

```gdscript
# Conceptual state machine
enum EncounterState {
  INACTIVE,
  INITIAL_DIALOG,
  CHALLENGE_ACTIVE,
  TRANSITION,
  COMPLETION_DIALOG,
  COMPLETED
}
```

Then define transition logic between states based on events like dialog completion or challenge completion.

## 5. How do I link the specific encounter with an NPC?

Add an EncounterTrigger component to your NPCs:

```gdscript
# encounter_trigger.gd
extends Node
class_name EncounterTrigger

@export var encounter_id: String
@export var one_time_only: bool = true
@export var required_player_level: int = 0
@export var required_items: Dictionary = {}
@export var required_flags: Dictionary = {}

var has_been_completed: bool = false
```

The interaction_zone can check this component when triggering an interaction.

## 6. How do I handle the timed collection challenge specifically?

For your collection challenge, define it in an EncounterDefinition:

```gdscript
# Example definition (conceptual)
var collection_challenge = ChallengeData.new()
collection_challenge.type = "Collection"
collection_challenge.parameters = {
  "count": 3,
  "item_type": "oxygen_canister",
  "spawn_radius": 10.0
}
collection_challenge.time_limit = 60.0
collection_challenge.success_criteria = {"collected_count": 3}
collection_challenge.failure_criteria = {"time_elapsed": true}
```

The EncounterStageManager would read this data and configure the stage accordingly.

## 7. How do I make the destination marker appear after challenge completion?

Implement a sequence controller in the EncounterFlowController:

```gdscript
# After challenge completion
func _on_challenge_completed(success: bool) -> void:
  if success:
    # Get the current encounter definition
    var encounter = current_encounter_definition
    
    # Spawn destination marker near NPC
    var marker = destination_marker_scene.instantiate()
    marker.global_position = current_npc.global_position + Vector3(2, 0, 0)
    get_tree().current_scene.add_child(marker)
    
    # Connect to marker signals
    marker.connect("reached", self, "_on_destination_reached")
  else:
    # Handle failure case
    _handle_challenge_failure()
```

## 8. How do I manage the different dialog phases?

Use the DialogManager to load different dialogs based on the encounter phase:

```gdscript
# In EncounterFlowController
func start_initial_dialog() -> void:
  var dialog = DialogManager.get_dialog(current_encounter.initial_dialog_id)
  DialogManager.start_dialog(dialog)
  # Connect to dialog completion signal
  DialogManager.connect("dialog_completed", self, "_on_initial_dialog_completed")

func start_completion_dialog() -> void:
  var dialog = DialogManager.get_dialog(current_encounter.completion_dialog_id)
  DialogManager.start_dialog(dialog)
  # Connect to dialog completion signal
  DialogManager.connect("dialog_completed", self, "_on_completion_dialog_completed")
```

## 9. How do I track which encounters have been completed?

Use a progress tracker in your save system:

```gdscript
# In a GameProgress singleton
var completed_encounters: Dictionary = {}

func mark_encounter_completed(encounter_id: String) -> void:
  completed_encounters[encounter_id] = true
  save_game()

func is_encounter_completed(encounter_id: String) -> bool:
  return completed_encounters.get(encounter_id, false)
```

NPCs can check this before offering their main encounter.

## 10. How do I make NPCs have different dialog after encounter completion?

Add a method to the NPController:

```gdscript
# In NPController
func get_appropriate_dialog_id() -> String:
  var encounter_id = get_node("EncounterTrigger").encounter_id
  
  if GameProgress.is_encounter_completed(encounter_id):
    return post_completion_dialog_id
  else:
    return dialogue_id
```

The interaction zone would use this method when triggering dialog.

## 11. How do I implement the progression between encounter phases?

Create a sequence controller:

```gdscript
# In EncounterFlowController
func advance_encounter() -> void:
  match current_state:
    EncounterState.INACTIVE:
      start_initial_dialog()
      current_state = EncounterState.INITIAL_DIALOG
      
    EncounterState.INITIAL_DIALOG:
      start_challenge()
      current_state = EncounterState.CHALLENGE_ACTIVE
      
    EncounterState.CHALLENGE_ACTIVE:
      if challenge_successful:
        current_state = EncounterState.TRANSITION
        show_destination_marker()
      else:
        handle_challenge_failure()
        
    EncounterState.TRANSITION:
      start_completion_dialog()
      current_state = EncounterState.COMPLETION_DIALOG
      
    EncounterState.COMPLETION_DIALOG:
      complete_encounter()
      current_state = EncounterState.COMPLETED
```

## 12. How do I create the encounter stage for challenges?

Enhance your existing encounter_stage.gd:

```gdscript
# In EncounterStageManager
func create_stage_for_challenge(challenge_data: ChallengeData) -> void:
  var stage = encounter_stage_scene.instantiate()
  add_child(stage)
  
  # Configure based on challenge type
  match challenge_data.type:
    "Collection":
      stage.setup_collection_challenge(challenge_data.parameters)
      if challenge_data.time_limit > 0:
        stage.start_timer(challenge_data.time_limit)
    # Handle other challenge types
```

## 13. How do I test and debug my encounters?

Create a debug menu that lets you:
1. List all available encounters
2. Force start any encounter
3. Skip to specific phases of an encounter
4. Reset encounter progress

This makes it easier to test and iterate without playing through the entire sequence.

## 14. How do I extend this system for more complex encounters?

For more complex encounters, consider adding:
- Branching paths based on player choices
- Multi-phase challenges with dependencies
- Conditional rewards based on performance
- Environmental effects or changes triggered by encounters
- Integration with a quest/mission system

## 15. How would I create the specific encounter in your example?

1. Create the encounter definition:
   - Set initial_dialog_id, completion_dialog_id, and post_completion_dialog_id
   - Add a collection challenge with count=3, time_limit=60
   - Set destination_marker to appear near the NPC

2. Create the dialog resources:
   - Initial dialog explaining the task
   - Completion dialog thanking the player
   - Post-completion dialog for future interactions

3. Attach the EncounterTrigger to your NPC:
   - Set the encounter_id to match your definition
   - Set one_time_only to true

4. Register it in the EncounterRegistry:
   - Add it to the available encounters on game start

The system handles the rest automatically, following the flow you described.
