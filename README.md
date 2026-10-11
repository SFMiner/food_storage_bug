# Bug Metabolism Game

A simple educational game about energy management and metabolism, built in Godot 4.5.

## Game Concept

Play as a small bug organism that must collect food while managing glucose and fat energy stores. Navigate a grid-based world, avoid spider enemies on patrol routes, and progress through two levels with increasing complexity.

## Controls

- **Arrow keys / WASD** - Jump up to your maximum distance in that direction (costs 1 glucose, like a click); hold **Shift** for a single step
- **Tab / Shift+Tab** - Move between the on-screen buttons (the Music switch and the open panel's button); **Enter/Space** presses one
- **Escape** - Closes the open panel; with nothing open it leaves the game (sims site)
- **Click/Touch** - Move to the clicked location (up to your maximum movement distance)
- The bug will automatically path toward your clicked location, stopping at the maximum distance if needed

## Feature checklist

- [x] Level 1: glucose only, collect 10 food
- [x] Level 2: fat storage, slowdown and auto-conversion
- [x] Spider patrols, death and restart
- [x] Click / touch movement
- [x] Keyboard movement (arrows / WASD) with an on-screen hint
- [x] Tab order and visible yellow focus outline on every button
- [x] Escape / Tab-past-the-ends send `sims:leave-game` to the sims site
- [x] Music waits for the first click or key; Music On/Off switch
- [x] No emoji or symbol glyphs; no flashing; information never by colour alone (spiders have legs, food is a plain dot, numbers are in the HUD)
- [x] Scales to small frames (960x640 base, canvas_items, expand)
- [x] Web export (2D + GUI custom template, single-threaded) and headless tests (`tests/run_all_tests.sh`)
- [x] Credits: sound effects in `sounds/credits.txt` (Pixabay); `main_music.ogg` is a Pixabay track (converted from `GameAssets/sounds/main_music.mp3`; the track's name was not recorded); the background image is AI-generated (GPT), no credit

## Game Mechanics

### Energy System

**Glucose (Energy on Hand)**
- Maximum storage: 5 glucose
- Each movement costs 1 glucose per tile
- If glucose reaches 0, you can't move and die

**Fat (Long-term Storage)** *(Level 2 only)*
- Maximum storage: 5 fat
- Fat slows you down:
  - 0-1 fat: Move up to 5 tiles
  - 2-3 fat: Move up to 4 tiles
  - 4-5 fat: Move up to 3 tiles
- **Auto-conversion**: When glucose hits 1 and you have fat, 1 fat automatically converts to 5 glucose

### Food Collection

- Each food gives **3 glucose**
- **Level 2 overflow**: If you have 4+ glucose when eating, excess converts to fat:
  - You lose 2 glucose and gain 1 fat
  - Example: At 5 glucose, eating food → 6 glucose → 3 glucose + 1 fat

### Enemies

- 2-3 spider enemies patrol predetermined paths
- They move after you move
- Contact with a spider = instant death and level restart
- Enemies don't chase you, they just patrol

## Levels

### Level 1: Basic Survival
- **Goal**: Collect 10 food
- **Mechanics**: Glucose only, simple energy management
- **Starting**: 5 glucose

### Level 2: Fat Storage
- **Goal**: Collect 20 food AND build up at least 2 fat
- **Mechanics**: Fat storage system active, movement penalties, auto-conversion
- **Starting**: 5 glucose, 0 fat
- **Challenge**: Must balance collecting enough food while building fat reserves

## Customization

The game is built with easily adjustable constants at the top of `main.gd`:

```gdscript
const GRID_WIDTH = 30          # Grid width
const GRID_HEIGHT = 20         # Grid height
const CELL_SIZE = 32           # Visual cell size

const MAX_GLUCOSE = 5          # Maximum glucose storage
const MAX_FAT = 5              # Maximum fat storage
const FOOD_GLUCOSE_VALUE = 3   # Glucose per food

const LEVEL_1_FOOD_GOAL = 10   # Food needed for Level 1
const LEVEL_2_FOOD_GOAL = 20   # Food needed for Level 2
const LEVEL_2_FAT_GOAL = 2     # Fat needed for Level 2
```

## How to Run

### In Godot Editor
1. Open Godot 4.5 or later
2. Import the project by opening `project.godot`
3. Press F5 or click the "Play" button

### Export to HTML5
1. Open the project in Godot
2. Go to Project → Export
3. Add "Web" export preset
4. Export the project
5. Host on a web server or use Godot's built-in HTTP server for testing

## Sound Effects

The game supports sound effects but works perfectly without them. See `sounds/README.md` for details on adding:
- `click.wav/ogg` - Movement sound
- `eat.wav/ogg` - Food collection sound
- `convert.wav/ogg` - Fat→glucose conversion sound
- `death.wav/ogg` - Death sound

## Technical Details

- **Engine**: Godot 4.5
- **Language**: GDScript
- **Rendering**: GL Compatibility (works on web and mobile)
- **Resolution**: 960x640 (canvas_items stretch mode)
- **Grid**: Invisible grid system with visual cell rendering

## Educational Value

This game teaches:
- Resource management
- Risk/reward decision making (move further vs. conserve glucose)
- Strategic planning (enemy patrol patterns)
- Biological concepts (glucose vs. fat energy storage)
- Spatial reasoning (pathfinding and movement planning)

## License

Free to use and modify for educational purposes.
