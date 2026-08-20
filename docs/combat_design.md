# DiceGod — Combat Design

## 1. Combat Flow

Each combat turn follows this exact order:

1. Battle Start / Turn Start
2. Roll Dice
3. Lock Dice
4. Reroll once
5. Confirm Results
6. Use Skills
7. Attack
8. Enemy Action
9. Next Turn

## 2. Dice Count

The player starts combat with 3 dice.

The maximum number of dice is 6.

The number of dice may increase through progression, equipment, abilities, or other future systems.

For the initial prototype:
- Start with exactly 3 dice.
- Do not implement dice-count upgrades yet.

## 3. Locking

After the initial roll, the player may lock any number of dice.

Locked dice are not rerolled.

The player may lock zero, some, or all dice.

For the initial prototype:
- A die can be toggled between locked and unlocked.
- Locked state must be visually obvious.
- There is no cost for locking.

## 4. Reroll

The player gets exactly one reroll per turn.

When rerolling:
- Locked dice keep their current result.
- Unlocked dice are rolled again.
- The reroll cannot be repeated.

Future abilities may modify this rule, but the base rule remains one reroll.

## 5. Result Confirmation

After the reroll, the player confirms the final dice results.

Once confirmed:
- Dice results are fixed for the action phase.
- The player can use available skills.
- The player can attack.

## 6. Skills

Skills are used after results are confirmed and before the attack.

Skills may inspect:
- Individual die values
- Number of dice
- Sum of dice
- Matching values
- Odd/even values
- Special faces
- Previous actions

The first prototype should have one simple skill or can omit skills until basic combat is proven.

## 7. Attack

The initial prototype should use a simple deterministic rule.

Recommended prototype rule:

Attack damage = sum of the final dice results.

Example:

2 + 4 + 6 = 12 damage.

This rule is intentionally simple and should later be replaced or expanded once the core loop is validated.

## 8. Enemy Action

After the player attacks, the enemy performs its action.

The first prototype needs only one simple enemy behavior:
- Deal a fixed amount of damage to the player.

## 9. Victory

If enemy HP reaches 0:
- Combat ends.
- Player wins.
- Reward can be added in a later milestone.

## 10. Defeat

If player HP reaches 0:
- Combat ends.
- Run ends for the prototype.

## 11. Future Combat Features

Not part of the first prototype:

- Critical hits
- Status effects
- Multiple enemies
- Enemy intent
- Complex skill chains
- Dice manipulation abilities
- Special dice faces
- Equipment interactions
- Boss mechanics
