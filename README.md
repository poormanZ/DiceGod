# DiceGod

DiceGod is a 2D turn-based roguelike dungeon RPG built with Godot 4 and GDScript.

The core fantasy is:

> Roll dice, manipulate fate, create your own build, and challenge the gods.

## Core Battle Loop

1. Battle starts
2. Roll dice
   - Start with 3 dice
   - Can increase to a maximum of 6 dice
3. Lock any number of dice
4. Perform 1 reroll
5. Confirm/select the final results
6. Use skills
7. Attack
8. Enemy acts
9. Repeat until victory or defeat

## Development Principles

- Godot 4.x
- GDScript only
- 2D
- Compatibility renderer
- Web deployment is a primary target
- Keep game rules data-driven where practical
- Prefer small, testable systems
- Do not expand scope without updating the design documents

## Documentation

- `AGENTS.md` — instructions for Codex
- `docs/game_design.md` — overall game concept
- `docs/combat_design.md` — battle rules
- `docs/dice_design.md` — dice rules
- `docs/character_design.md` — character, skills, equipment
- `docs/dungeon_design.md` — dungeon structure
- `docs/progression_design.md` — roguelike progression
- `docs/ui_design.md` — UI direction
- `docs/technical_design.md` — technical architecture
- `docs/roadmap.md` — implementation roadmap

## Current Development Status

Pre-production / core design phase.

The first playable milestone is a single battle containing:
- One player
- One enemy
- Three dice
- Locking
- One reroll
- Result confirmation
- One basic attack
- Enemy action
- Win/lose state
