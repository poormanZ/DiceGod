# DiceGod — Technical Design

## 1. Technology

- Godot 4.x
- GDScript
- 2D
- Compatibility renderer
- Web export is a primary target

## 2. Suggested Architecture

### Core

Responsible for:
- Game state
- Run state
- Save/meta state later

### Dice

Responsible for:
- Dice data
- Rolling
- Locking
- Rerolling
- Result handling

### Battle

Responsible for:
- Turn state
- Player action phase
- Enemy action
- Damage
- Victory/defeat

### Character

Responsible for:
- Player data
- Skills
- Equipment

### Dungeon

Responsible for:
- Map
- Nodes
- Rewards
- Encounters

## 3. Data-Driven Design

Prefer Godot Resource-based data for static content.

Potential resources:
- DiceData
- AbilityData
- EquipmentData
- EnemyData
- CharacterData

Gameplay systems should consume these data objects rather than hard-code every piece of content.

## 4. Suggested Folder Structure

scenes/
scripts/
resources/
assets/

Keep systems separated by responsibility.

## 5. First Prototype

The first implementation should be deliberately simple.

A single battle scene is enough.

Do not create a complex global architecture until the gameplay loop requires it.
