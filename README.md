# Bubble Bobble Clone (Godot 4.x)

## How to Run
1. Open the project folder in Godot 4.x
2. Run `Main.tscn` (Project → Run, or F5)


## Controls

| Action | Keys |
|---|---|
| Move Left | A / Left Arrow |
| Move Right | D / Right Arrow |
| Jump | W / Up Arrow |
| Fire Bubble | Space |
| Start Game | Enter / Space |
| Restart | R |


## Implemented Features

### Core
- [x] Player movement — left/right, jump, gravity
- [x] CharacterBody2D with `move_and_slide()`
- [x] TileMap platforms with collision (3 layouts, 4 color variants)
- [x] Player cannot walk through walls or fall through floors

### Bubble Shooting
- [x] Player fires bubbles in the facing direction
- [x] Bubble travels horizontally then floats upward
- [x] Hold fire to extend horizontal travel distance
- [x] Bubble has a lifetime and despawns automatically
- [x] Maximum of 5 bubbles on screen at once

### Enemies
- [x] 5 enemies per level (mix of NORMAL and AGGRESSIVE types)
- [x] Enemies patrol platforms and reverse on wall collision
- [x] Enemies randomly change direction every few seconds
- [x] Enemies drop in from the top with staggered spawn delays
- [x] Enemies shoot bolts at the player
- [x] Enemy contact damages the player via HitBox

### Trap Mechanic
- [x] Bubbles trap enemies on contact
- [x] Trapped enemy is hidden and follows the bubble
- [x] Trapped bubble plays a type-specific animation
- [x] Trapped enemy's HitBox is disabled while trapped

### Popping, Scoring & Game Loop
- [x] Player pops trapped bubbles by touching them
- [x] Bolts fired by enemies pop bubbles
- [x] Popping a trapped enemy awards points
- [x] HUD displays level, score, lives, and health
- [x] Lives and health shown as icon indicators
- [x] Player takes damage and flashes on hit
- [x] Player death fall animation before respawn
- [x] Game Over screen on losing all lives
- [x] Game pauses on Game Over
- [x] Restart resets all state cleanly

### Level Progression
- [x] Level advances when all enemies are defeated
- [x] 2-second delay before transitioning to next level
- [x] 3 platform layouts cycle with each level
- [x] 4 color themes cycle independently each level
- [x] Player spawns at a layout-specific position


## Bonus Feature — Power-up Fruit (Implemented)

- Fruit drops from popped enemy bubbles
- NORMAL enemies have a 25% chance to drop power-up fruit
- AGGRESSIVE enemies always drop from the power-up pool
- Power-up fruit can restore health or grant an extra life
- Random regular fruit (apple, raspberry, lemon) spawns periodically
- Fruit flashes before despawning and plays a pop animation on pickup


## How to Run

### Requirements
- [Godot 4.x](https://godotengine.org/download) (any 4.x release)

### Steps
1. Download or clone the project folder
2. Open **Godot 4.x**
3. Click **Import** in the Project Manager
4. Navigate to the project folder and select `project.godot`
5. Click **Import & Edit**
6. Once the project is open, press **F5** or go to **Project → Run Project**
7. The game will launch from `Main.tscn` automatically
