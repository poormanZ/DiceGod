# DiceGod — Game Design

## 1. High Concept

DiceGod is a 2D turn-based roguelike dungeon RPG.

The player explores dangerous dungeons, fights monsters, obtains dice, skills, and equipment, and gradually creates a unique build.

The central idea is:

> Luck creates possibilities. Strategy decides how to use them.

## 2. Core Fantasy

The player is a character who manipulates fate through dice.

At the beginning, the player has only a few ordinary dice. During a run, the player can obtain stronger or stranger dice, skills, and equipment.

The long-term fantasy is to create a build where dice results, skills, and equipment interact to produce powerful combinations.

## 3. Core Game Loop

Dungeon exploration:

Battle → Reward → Choice → Battle → Event/Shop/Elite → Boss

Battle:

Battle Start
→ Roll Dice
→ Lock Dice
→ Reroll Once
→ Confirm Results
→ Use Skills
→ Attack
→ Enemy Action
→ Next Turn

## 4. Core Design Pillars

### Dice First

Dice are the identity of the game. Combat systems should interact with dice rather than treating dice as a simple damage roll.

### Luck With Agency

Randomness should create uncertainty, but the player must have meaningful ways to influence results.

### Build Creation

Dice + Skills + Equipment should create different play styles.

### Short-Term Decisions

Each turn should present meaningful choices.

### Long-Term Decisions

The player should decide which dice, skills, and equipment to keep or replace.

## 5. Example Builds

### Six Build

Focus on producing and exploiting the result 6.

### Poison Build

Use special poison faces and effects that stack poison.

### Defense/Counter Build

Use defensive results to survive and convert defense into counterattacks.

### Gambling Build

Use extreme dice distributions with high risk and high reward.

## 6. Roguelike Structure

A run should create a different build through randomized rewards and choices.

Death ends the current run.

Permanent progression may unlock new content, but the first playable version should focus on the run itself.

## 7. Initial Scope

The first playable prototype only needs:

- One player
- One enemy
- Three dice
- Dice locking
- One reroll
- Result confirmation
- One basic attack
- Enemy action
- Win/lose state

Everything else comes later.
