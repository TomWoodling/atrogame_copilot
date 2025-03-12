# SNAUT - Game Design Document

## Table of Contents
1. [Character Profiles](#character-profiles)
2. [Game Mechanics](#game-mechanics)
3. [Story Structure](#story-structure)
4. [Level Design Guidelines](#level-design-guidelines)
5. [Encounter Design](#encounter-design)
6. [Collectible System](#collectible-system)
7. [Challenge Course Framework](#challenge-course-framework)
8. [Dialogue System](#dialogue-system)
9. [Progression Tracking](#progression-tracking)

## Character Profiles

### Player Character
- **Name**: Snaut
- **Role**: Recently qualified astronaut/assistant
- **Traits**: 
  - Small in stature
  - Intelligent and determined
  - Helpful and enthusiastic with a hint of snark
  - Always in spacesuit (gender-neutral design)
- **Implementation Notes**: 
  - Character model should be visibly smaller than NPCs
  - Keep dialogue responses helpful but with occasional witty remarks
  - Design spacesuit to be distinctive but not gender-specific

### NPCs

#### Asstronauts
- **Role**: Mild antagonists/comic relief
- **Traits**:
  - Foolish and bumbling
  - Unqualified for their mission
  - Obsessed with cryptocurrency, fraternity culture
- **Implementation Notes**:
  - First NPCs encountered in gameplay
  - Design multiple Asstronaut models with slight variations
  - Dialog should reflect their misplaced confidence and poor decision-making
  - Task assignments should be trivial or absurd

#### Lucy Borgiya
- **Role**: Cyborg terraforming scientist
- **Traits**:
  - Feisty and determined
  - Intelligent with surprising compassion
  - Constantly irritated by Asstronauts
  - Favorite element: Niobium
- **Implementation Notes**:
  - Appears in Level 2
  - Visually distinct cybernetic features
  - Dialog should be scientifically accurate but accessible
  - Tasks related to terraforming and technology

#### Jackie Gunn
- **Role**: Cyborg security consultant/weapons expert
- **Traits**:
  - Effusive with wicked humor
  - Single-minded in supporting Lucy
  - Potentially transformable into a defense cannon
  - Favorite movie: The Terminator
- **Implementation Notes**:
  - Appears in Level 3
  - Design with obvious weapon-related cybernetics
  - Dialog should include dark humor and protective sentiments
  - Tasks involve security and defensive measures

#### Jess 167
- **Role**: Veteran cyborg/logistics expert
- **Traits**:
  - Older model cyborg (numbered, not surname)
  - Friendly and outgoing
  - Takes everything in good humor
  - Favorite flower: Hibiscus
- **Implementation Notes**:
  - Appears in Level 4
  - Visually older cybernetic design
  - Dialog reflects experience and worldliness
  - Tasks related to resource management

#### AutoSue
- **Role**: Robot who thinks she's a cyborg
- **Traits**:
  - Brave and strong
  - Enjoys talking to Snaut
  - Unclear on her own origins
  - Favorite transformer: Ironhide
- **Implementation Notes**:
  - Appears in Level 5
  - Design clearly robotic, not cyborg-like
  - Dialog should hint at identity confusion
  - Tasks involve physical challenges

#### Jylxr of Umygrox
- **Role**: Alien ambassador
- **Traits**:
  - Pompous but good-hearted
  - Royal heritage
  - Long-winded speech patterns
  - Favorite fabric: Umygroxian Bofurit Leather
- **Implementation Notes**:
  - Appears in Level 6 (after meeting Blembor)
  - Distinctly alien design with regal elements
  - Dialog should be formal and unnecessarily complex
  - Tasks involve diplomatic objectives

#### Blembor
- **Role**: Jylxr's attendant
- **Traits**:
  - Non-binary alien
  - Sometimes timid but dutiful
  - Loyal to Jylxr
  - Favorite dessert: Moon pie
- **Implementation Notes**:
  - Appears in Level 6 (before Jylxr)
  - Design as alien but less regal than Jylxr
  - Dialog reflects both caution and dedication
  - Tasks involve preparation for meeting Jylxr

#### Mr. X
- **Role**: True antagonist
- **Traits**:
  - Mysterious
  - Owner of deep-space exploration company
  - Hidden agenda
- **Implementation Notes**:
  - Only referenced, not directly encountered in first game cycle
  - Design communications to hint at ulterior motives
  - Keep references subtle but increasingly suspicious

## Game Mechanics

### Core Gameplay
- 3D exploration with platforming elements
- Procedurally generated world
- Four primary interaction types:
  1. NPC dialogue encounters
  2. Information gathering
  3. Collectible acquisition
  4. Challenge course completion

### World Generation Parameters
- Environment should evolve to match story progression
- Each level introduces new biome elements reflecting terraforming progress
- Procedural generation should create areas suited to specific challenge types
- Difficulty gradients should increase with level progression

### Character Abilities
- Basic movement: walk, run, jump
- Special abilities unlocked progressively:
  - Level 2: Enhanced jumping after meeting Lucy
  - Level 3: Gliding mechanics for sky challenges with Jackie
  - Level 4: Climbing for crevice exploration with Jess
  - Level 5: Short-range teleportation from AutoSue's tech
  - Level 6-7: Alien technology integration

## Story Structure

### Prologue
- **Setting**: Astro university graduation → job application → shuttle assignment
- **Key Events**:
  - Snaut hired as space-intern
  - Introduction to Asstronauts
  - Discovery of terraforming equipment
  - Crash landing on uninhabited planet
  - Cyborgs awakening
- **Implementation Notes**:
  - Create as playable tutorial or cutscene sequence
  - Establish character dynamics early
  - Plant seeds of mystery regarding mission discrepancies

### Level 1: The Search Begins
- **Objective**: Find D00D4D (shuttle's AI core)
- **Key NPCs**: Asstronauts
- **Implementation Notes**:
  - Design as tutorial area with basic mechanics
  - Create simple fetch quests from Asstronauts
  - Culminate in challenge course to retrieve D00D4D
  - Progression metrics: complete 5-7 Asstronaut tasks before challenge unlocks

### Level 2: The Fibonacci Oscillator
- **Objective**: Find first D00D4D component (fibonacci oscillator)
- **Key NPCs**: Asstronauts, Lucy Borgiya (introduced)
- **Implementation Notes**:
  - Expand world area
  - Introduce Lucy's terraforming elements to environment
  - Create contrast between Lucy's scientific tasks and Asstronauts' frivolous requests
  - Progression metrics: complete 4-5 Lucy tasks + 2-3 Asstronaut tasks before challenge unlocks

### Level 3: Skyward Wiring
- **Objective**: Retrieve microfilament wiring from the sky
- **Key NPCs**: Lucy, Jackie Gunn (introduced)
- **Implementation Notes**:
  - Develop vertical gameplay elements
  - Introduce security/defense elements to environment
  - Design sky-based challenge course with increasing difficulty
  - Progression metrics: complete 4-5 Jackie tasks + 2 Lucy tasks before challenge unlocks

### Level 4: The Deep Crevice
- **Objective**: Recover geothermic heatsink
- **Key NPCs**: Lucy, Jackie, Jess 167 (introduced)
- **Implementation Notes**:
  - Develop underground/crevice gameplay elements
  - Incorporate resource management mechanics
  - Design challenge course with emphasis on precision platforming
  - Progression metrics: complete 4-5 Jess tasks + 1-2 tasks from previous NPCs

### Level 5: The Quantum BIOS
- **Objective**: Obtain quantum-entangled BIOS chip from AutoSue
- **Key NPCs**: Jess, AutoSue (introduced)
- **Implementation Notes**:
  - Introduce anomalous environment elements
  - Design puzzle-oriented challenges
  - Create mission structure that centers on AutoSue's capabilities
  - Progression metrics: complete 5 AutoSue tasks before challenge unlocks

### Level 6: First Contact
- **Objective**: Meet alien visitors
- **Key NPCs**: Lucy, Blembor (introduced)
- **Implementation Notes**:
  - Create distinct alien environment section
  - Design diplomatic-themed tasks
  - Incorporate alien cultural elements
  - Progression metrics: complete 5-6 Blembor tasks before Jylxr introduction

### Level 7: The Message
- **Objective**: Stabilize quantum BIOS chip for D00D4D
- **Key NPCs**: Blembor, Jylxr (introduced)
- **Implementation Notes**:
  - Design quantum-themed challenges
  - Create visual representation of quantum entanglement
  - Build suspense for the encrypted message reveal
  - Progression metrics: collect quantum BIOS 10 times through specialized encounters

## Level Design Guidelines

### Environmental Themes
- **Level 1**: Crash site and immediate surroundings (barren planet)
- **Level 2**: Early terraforming area (first vegetation appearing)
- **Level 3**: Atmospheric integration zone (clouds forming, wind currents)
- **Level 4**: Geological restructuring area (crevices, rock formations)
- **Level 5**: Quantum anomaly region (visual distortions, physics anomalies)
- **Level 6**: Alien contact site (blend of terraform and alien aesthetics)
- **Level 7**: Quantum resonance zone (visual representations of entanglement)

### Navigation Design
- Each level should have a central hub where NPCs gather
- Spokes leading to encounter zones and collection areas
- Challenge courses should be visually distinct and clearly marked
- Terrain complexity should increase with level progression
- Use environmental storytelling to guide players toward objectives

## Encounter Design

### NPC Encounters
- Structured as conversation trees with:
  - Information delivery
  - Task assignment
  - Character development
  - Story progression
- Each NPC should have 15-20 unique dialogue options
- Dialogue should reflect character personality and motivation
- Repeatable encounters should vary slightly to reduce repetition

### Information Encounters
- Data logs
- Environmental scans
- Crashed shuttle fragments with recorded messages
- Alien artifacts with translated information
- Each level should have 8-10 unique information pieces

### Collectible Encounters
- Tied to specific NPC request lines
- Visually distinctive based on requesting NPC
- Located in areas that match NPC's character and role
- Each NPC should have 10-15 associated collectibles

### Challenge Course Encounters
- One major challenge course per level (unlocks progression)
- 3-5 minor challenge courses per level (optional, rewards)
- Design according to level theme and newly introduced abilities
- Increasing difficulty curve within each course

## Collectible System

### Collectible Categories
1. **Asstronaut Requests**:
   - Lost personal items
   - Food and comfort items
   - Cryptocurrency mining components
   - Fraternity memorabilia

2. **Lucy's Research Items**:
   - Soil samples
   - Atmospheric data nodes
   - Mineral specimens (emphasis on niobium)
   - Terraforming equipment parts

3. **Jackie's Security Objects**:
   - Weapons components
   - Defense system parts
   - Security footage records
   - Tactical assessment devices

4. **Jess's Resources**:
   - Organic precursors
   - Construction materials
   - Vintage technology
   - Hibiscus seeds and specimens

5. **AutoSue's Components**:
   - Robot parts she believes are cyborg parts
   - Memory fragments
   - Anomaly readings
   - Transformer figurines (especially Ironhide)

6. **Alien Artifacts**:
   - Umygroxian cultural items
   - Diplomatic gifts
   - Quantum-entangled objects
   - Historical records relating to D00D4D

### Collection Mechanics
- Visual and audio cues for nearby collectibles
- Collectible log in player menu
- Collection progress tied to NPC relationship advancement
- Special rewards at collection milestones

## Challenge Course Framework

### Course Types
1. **Navigation Challenges**:
   - Platforming sequences
   - Timing puzzles
   - Environmental hazards

2. **Puzzle Challenges**:
   - Pattern recognition
   - Sequential activation
   - Resource management

3. **Skill Challenges**:
   - Precision movement
   - Rapid response
   - Ability combinations

4. **Hybrid Challenges**:
   - Multi-stage courses
   - Adaptive difficulty
   - Character-specific abilities required

### Difficulty Scaling
- **Basic Parameters**:
  - Timer duration
  - Platform spacing
  - Hazard frequency
  - Puzzle complexity

- **Level-based Scaling**:
  - Level 1: Tutorial difficulty (forgiving)
  - Level 2-3: Moderate difficulty (introducing consequences)
  - Level 4-5: Challenging (requiring skill mastery)
  - Level 6-7: Advanced (requiring strategy and precision)

## Dialogue System

### Dialogue Principles
- Character-specific vocabulary and speech patterns
- Humor appropriate to character personalities
- Progressive revelation of story elements
- Callbacks to previous interactions
- Subtle hints about Mr. X and the true mission

### Implementation Structure
```
DialogueNode {
  id: string
  character: CharacterID
  text: string
  options: DialogueOption[]
  requirements: DialogueRequirement[]
  onComplete: DialogueEffect[]
}

DialogueOption {
  text: string
  nextNodeId: string
  requirement?: DialogueRequirement
}

DialogueRequirement {
  type: "item" | "level" | "npcMet" | "taskComplete"
  value: any
}

DialogueEffect {
  type: "addTask" | "completeTask" | "giveItem" | "unlockArea"
  value: any
}
```

### Character-Specific Dialogue Examples
- **Asstronauts**: "Dude, can you like, find my crypto wallet? I dropped it somewhere near that weird glowing mushroom patch."
- **Lucy**: "The terraforming process is 12.4% complete, but I need additional niobium samples to calibrate the mineral replicator."
- **Jackie**: "Keep your eyes open around sector 7. My sensors picked up some unusual movement patterns. Could be nothing, could be... boom time."
- **Jess**: "Back in my day, we didn't have fancy quantum BIOS chips. We made do with vacuum tubes and good old-fashioned determination!"
- **AutoSue**: "My internal diagnostics indicate I am operating at 98.2% efficiency. The remaining 1.8% is dedicated to wondering what Ironhide would do in this situation."
- **Blembor**: "The esteemed Ambassador Jylxr requires specific ceremonial preparations before first contact. Would you assist with the gathering of proper materials?"
- **Jylxr**: "Most honored small human, the conjunction of our meeting was foretold in the quantum resonance patterns of the ancient BIOS relic, which has adorned our sacred chambers for seventeen generations of my lineage."

## Progression Tracking

### Progression Metrics
- **NPC Relationship Levels**:
  - Level 1: Introduction
  - Level 2: Acquaintance
  - Level 3: Colleague
  - Level 4: Friend
  - Level 5: Confidant
  - Each level unlocks new dialogue and task options

- **Task Completion Tracking**:
  - Required tasks (main storyline)
  - Optional tasks (character development, rewards)
  - Hidden tasks (easter eggs, special rewards)

- **Collectible Completion**:
  - Per-character collection rate
  - Total collection percentage
  - Special collection sets

- **Challenge Course Completion**:
  - Main courses (required)
  - Side courses (optional)
  - Performance ratings (time, accuracy)

### Data Structure for Progression
```
PlayerProgress {
  currentLevel: number
  completedTasks: TaskID[]
  activeTasks: TaskID[]
  collectedItems: ItemID[]
  npcRelationships: {
    [CharacterID]: RelationshipLevel
  }
  completedChallenges: {
    [ChallengeID]: ChallengeRating
  }
  storyFlags: {
    [FlagID]: boolean
  }
}
```

### Level Advancement Requirements
- **Level 1→2**: Find D00D4D, complete 5+ Asstronaut tasks
- **Level 2→3**: Find fibonacci oscillator, complete 4+ Lucy tasks
- **Level 3→4**: Retrieve microfilament wiring, complete 4+ Jackie tasks
- **Level 4→5**: Recover geothermic heatsink, complete 4+ Jess tasks
- **Level 5→6**: Obtain quantum BIOS, complete 5+ AutoSue tasks
- **Level 6→7**: Meet Blembor, complete diplomatic preparation
- **Level 7→Future**: Collect BIOS 10 times, unlock encrypted message
