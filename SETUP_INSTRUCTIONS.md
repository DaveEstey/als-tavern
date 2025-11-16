# ALS Tavern - Setup Instructions

## Overview
ALS Tavern is a champion-based turn-based card battle game built in Godot 4.3+. This document explains how to set up and run the project.

---

## Prerequisites

1. **Godot Engine 4.3 or higher**
   - Download from: https://godotengine.org/download
   - Extract and add to your PATH (optional)

2. **Git** (for version control)

---

## Installation Steps

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd als-tavern
```

### 2. Open Project in Godot

**Option A: Using Godot Project Manager**
1. Open Godot Engine
2. Click "Import"
3. Navigate to the `als-tavern` folder
4. Select `project.godot`
5. Click "Import & Edit"

**Option B: Using Command Line**
```bash
godot --editor project.godot
```

### 3. Create Scene Files

The project includes all GDScript code, but you need to create the scene (.tscn) files in the Godot editor. Follow the **SCENE_STRUCTURES.md** document for detailed instructions on creating each scene.

**Priority Scenes to Create:**
1. `scenes/main_menu.tscn` - Main menu (start here)
2. `scenes/ui/party_selection.tscn` - Party selection screen
3. `scenes/map/map_scene.tscn` - Map exploration
4. `scenes/battle/battle_scene.tscn` - Battle system
5. UI components (card_ui, champion_display, enemy_display, hand_ui)

---

## Project Structure

```
als-tavern/
├── project.godot              # Godot project configuration
├── GAME_DESIGN_DOC.md         # Complete game design specification
├── BUILD_PLAN.md              # Development roadmap
├── SETUP_INSTRUCTIONS.md      # This file
├── SCENE_STRUCTURES.md        # Detailed scene creation guide
├── data/                      # JSON data files
│   ├── champions.json         # Champion stats and cards
│   ├── cards.json             # All card definitions
│   └── enemies.json           # Enemy types and attacks
├── scripts/
│   ├── managers/              # Global singletons
│   │   ├── game_manager.gd
│   │   ├── card_database.gd
│   │   ├── party_manager.gd
│   │   └── save_manager.gd
│   ├── battle/                # Combat system
│   │   ├── battle_manager.gd
│   │   ├── battle_scene.gd
│   │   └── card.gd
│   ├── champions/
│   │   └── champion.gd
│   ├── enemies/
│   │   └── enemy.gd
│   ├── map/                   # Map generation
│   │   ├── map_generator.gd
│   │   └── map_scene.gd
│   └── ui/                    # All UI components
│       ├── card_ui.gd
│       ├── champion_display.gd
│       ├── enemy_display.gd
│       ├── hand_ui.gd
│       ├── party_selection_ui.gd
│       ├── shop_ui.gd
│       ├── rest_ui.gd
│       ├── shrine_ui.gd
│       ├── main_menu.gd
│       └── victory_defeat_ui.gd
├── scenes/                    # Scene files (create these)
│   ├── main_menu.tscn
│   ├── battle/
│   ├── map/
│   └── ui/
└── assets/                    # Art, audio, fonts
    ├── sprites/
    ├── audio/
    └── fonts/
```

---

## Quick Start Guide

### Minimum Viable Setup (Test the Game)

To get the game running quickly:

1. **Create Main Menu Scene**
   - Open Godot
   - Scene → New Scene → Control node
   - Rename to "MainMenu"
   - Attach `scripts/ui/main_menu.gd`
   - Add UI buttons as per SCENE_STRUCTURES.md
   - Save as `scenes/main_menu.tscn`
   - Set as main scene (Project → Project Settings → Run → Main Scene)

2. **Create Battle Scene** (simplified)
   - Create Control node "BattleScene"
   - Attach `scripts/battle/battle_scene.gd`
   - Add BattleManager node (script: `scripts/battle/battle_manager.gd`)
   - Add basic UI labels and buttons
   - Save as `scenes/battle/battle_scene.tscn`

3. **Run the Game**
   - Press F5 or click Play button
   - Click "New Game" to start

---

## Configuration

### Autoloads (Already Configured in project.godot)

The following singletons are auto-loaded:
- `GameManager` - Global game state
- `CardDatabase` - Data loading
- `PartyManager` - Champion management
- `SaveManager` - Save/load system

### Display Settings

- **Resolution:** 1280x720 (configurable in Project Settings)
- **Stretch Mode:** canvas_items
- **Resizable:** true

---

## Testing the Game

### Test Battle (Quick Test)

Create a simple test battle scene:

1. Open Godot Script Editor
2. Create a test script that calls:
   ```gdscript
   GameManager.start_battle(["goblin_scout"])
   ```
3. Run to test combat mechanics

### Test Data

The game comes with:
- **3 starter champions:** Warrior, Defender, Healer
- **15 starter cards:** 5 per champion
- **10 enemies:** 7 trash, 2 elite, 1 boss
- **1 unlockable champion:** Fire Knight

---

## Development Workflow

### Making Changes

1. **Modify Data:** Edit JSON files in `data/` folder
2. **Modify Logic:** Edit GDScript files in `scripts/` folder
3. **Modify UI:** Edit scene files in Godot editor
4. **Test:** Press F5 to run

### Adding New Cards

1. Open `data/cards.json`
2. Add new card entry:
```json
"new_card_id": {
  "id": "new_card_id",
  "name": "New Card",
  "champion": "warrior",
  "type": "attack",
  "cost": 1,
  "target_type": "single_enemy",
  "effect_type": "damage",
  "value": 10,
  "description": "Deal 10 damage"
}
```
3. Add card ID to champion's card pool in `champions.json`
4. Restart game

### Adding New Champions

1. Open `data/champions.json`
2. Add champion entry with stats and core_cards
3. Create cards for the champion in `cards.json`
4. Champion will appear after unlocking

---

## Troubleshooting

### "Node not found" errors

**Cause:** Scene structure doesn't match script expectations

**Fix:** Check SCENE_STRUCTURES.md and ensure all node names match exactly

### "Cannot access property" errors

**Cause:** Missing autoload or script reference

**Fix:** Check Project → Project Settings → Autoload tab

### JSON parse errors

**Cause:** Invalid JSON syntax in data files

**Fix:** Use a JSON validator (jsonlint.com) to check syntax

### Drag and drop not working

**Cause:** Card UI scene not properly set up

**Fix:** Ensure CardUI scene has `mouse_filter` set to "Pass" or "Stop"

---

## Next Steps

1. **Follow SCENE_STRUCTURES.md** to create all scenes
2. **Test each system** individually (battle, map, shop, etc.)
3. **Add placeholder art** in `assets/sprites/`
4. **Implement missing features** from BUILD_PLAN.md Phase 5 (animations, sound)
5. **Playtest and balance** card values and enemy difficulty

---

## Support

For questions or issues:
1. Check **GAME_DESIGN_DOC.md** for game rules
2. Check **BUILD_PLAN.md** for development tasks
3. Check **SCENE_STRUCTURES.md** for UI setup
4. Review script comments for implementation details

---

**Ready to build!** Start with creating `scenes/main_menu.tscn` and work through the scene structures document.
