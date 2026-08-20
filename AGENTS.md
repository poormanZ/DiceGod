# DiceGod — Codex Development Instructions

## Project Goal

DiceGod is a 2D turn-based roguelike dungeon RPG focused on dice manipulation, build creation, and strategic use of random results.

Read the relevant files in `docs/` before implementing or changing a system.

## Mandatory Rules

1. Use Godot 4.x and GDScript.
2. Do not use C#.
3. Keep the project compatible with web export.
4. Use the Compatibility renderer.
5. Do not introduce unnecessary third-party dependencies.
6. Do not rewrite unrelated systems while implementing a task.
7. Prefer small, isolated changes.
8. Preserve existing gameplay rules unless the user explicitly requests a rule change.
9. If code and design documentation conflict, do not silently choose one. Report the conflict.
10. If a gameplay rule changes, update the relevant design document.
11. Keep data and gameplay logic separated where practical.
12. Prefer Godot Resources for static game data such as dice, abilities, equipment, enemies, and characters.
13. Use snake_case for file names.
14. Use clear, descriptive class and node names.
15. Avoid hard-coding gameplay data when it should be editable data.
16. Do not add large amounts of content before the core gameplay loop is proven fun.
17. Do not implement future roadmap systems unless the current task requires them.
18. After implementation, check for obvious Godot parse errors and broken references.
19. Summarize changed files and important behavior after completing a task.
20. If a requested task is ambiguous and could change core gameplay rules, ask before making the change.

## Documentation Map

- `docs/game_design.md` — overall game vision
- `docs/combat_design.md` — battle flow and rules
- `docs/dice_design.md` — dice mechanics
- `docs/character_design.md` — character, skills, equipment
- `docs/dungeon_design.md` — dungeon structure
- `docs/progression_design.md` — progression
- `docs/ui_design.md` — UI
- `docs/technical_design.md` — architecture
- `docs/roadmap.md` — current implementation order

## Current Priority

Implement the smallest playable combat prototype first.

Do NOT begin with:
- large dungeon generation
- many enemies
- dozens of dice
- complex equipment
- meta progression
- online features

The first goal is to prove that the dice-to-combat loop is fun.

## Preferred Development Workflow

1. Read relevant documentation.
2. Inspect existing project structure.
3. Implement only the requested scope.
4. Test/check the implementation.
5. Update documentation if rules changed.
6. Report what changed and any remaining issues.
