# DiceGod — Dice Design

## 1. Dice Are the Core System

Dice are not merely random damage generators.

They are the main resource used to create builds.

The player should eventually be able to modify:
- Which dice they own
- How many dice they roll
- The faces on each die
- The probability distribution
- How results are manipulated
- How results interact with skills and equipment

## 2. Base Dice

The prototype uses ordinary six-sided dice:

1 / 2 / 3 / 4 / 5 / 6

Each die has an integer result from 1 to 6.

## 3. Dice Count

Initial count: 3

Maximum count: 6

The prototype must use exactly 3 dice.

## 4. Locking

Each die has a locked/unlocked state during the dice phase.

Locked dice survive the reroll unchanged.

## 5. Reroll

The base rule is one reroll per turn.

Only unlocked dice are rerolled.

## 6. Future Dice Types

Possible future dice:

### Berserker Die

1 / 1 / 2 / 4 / 6 / 6

### Gambler Die

1 / 1 / 1 / 6 / 6 / 6

### Poison Die

Poison / Poison / 2 / 3 / 4 / Poison

### Holy Die

Defense / Defense / 2 / 3 / 4 / 6

These are design examples, not final balance values.

## 7. Face Modification

A major future system is modifying individual faces.

Examples:

3 → Poison

5 → +2 Damage

6 → Critical

1 → Gold

The player should eventually be able to create unusual custom dice.

## 8. Dice Build Philosophy

A rare die is not automatically better.

The important question is whether the die fits the player's build.

The system should encourage:
- Synergy
- Risk/reward
- Probability manipulation
- Adaptation during a run

## 9. Prototype Restrictions

Do not implement custom faces, multiple die types, or advanced probability manipulation in the first prototype.

First prove that rolling, locking, rerolling, confirming, and attacking are fun.
