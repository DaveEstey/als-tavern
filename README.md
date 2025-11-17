# ALS Tavern

A champion-based turn-based card battle game built with Godot Engine 4.3+.

![Status](https://img.shields.io/badge/status-skeleton-orange)
![Version](https://img.shields.io/badge/version-1.0.0--alpha-blue)
![Engine](https://img.shields.io/badge/engine-Godot%204.3%2B-blue)

---

## Overview

ALS Tavern is a strategic card battle game inspired by Slay the Spire, Final Fantasy, and Darkest Dungeon. Build a party of champions, collect powerful cards, and battle through procedurally generated maps to unlock new champions and defeat epic bosses.

### Key Features

✅ **Champion-Based Deck Building** - Select 3 champions, each with unique card abilities
✅ **Turn-Based Card Combat** - Strategic card play with targeting and positioning
✅ **Procedural Map Generation** - Explore branching paths with battles, shops, and events
✅ **Boss Recruitment System** - Defeat bosses to unlock them as playable champions
✅ **Persistent Progression** - Level up champions, unlock cards, and build your roster
✅ **Complete Game Skeleton** - All core systems implemented and ready to expand

---

## Game Design

### Champions
- **Warrior** - High-damage attacker with aggressive abilities
- **Defender** - Tank with shields and damage mitigation
- **Healer** - Support champion with healing and revival
- **Fire Knight** - Unlockable fire mage with devastating elemental attacks

### Core Gameplay Loop
1. **Party Selection** - Choose 3 champions from your roster
2. **Deck Building** - Select 5 cards per champion (15 card deck)
3. **Map Exploration** - Navigate procedurally generated node map
4. **Battle Encounters** - Use cards and basic actions to defeat enemies
5. **Rewards & Progression** - Gain XP, gold, unlock cards and champions
6. **Boss Battles** - Defeat bosses to recruit them as champions

### Combat System
- **Turn-based** - Player acts first, then all enemies
- **3 Actions Per Turn** - One action per champion (play card or basic action)
- **Card Targeting** - Drag-and-drop cards onto champions, then select targets
- **Basic Actions** - Attack (deal damage) or Defend (gain block)
- **Strategic Depth** - Block, healing, buffs, debuffs, and special effects

---

## Current Status

### ✅ Completed (Phase 1-4)
- [x] **Data Architecture** - JSON-based cards, champions, enemies
- [x] **Manager Systems** - GameManager, CardDatabase, PartyManager, SaveManager
- [x] **Battle System** - Full turn-based combat with card effects
- [x] **Champion System** - Stats, leveling, HP tracking, death/revival
- [x] **Card System** - 20 unique cards with diverse effects
- [x] **Enemy AI** - 10 enemies (trash, elite, boss) with attack patterns
- [x] **Map System** - Procedural generation with 20 nodes
- [x] **UI Components** - Battle, hand, party selection, shop, rest, shrine
- [x] **Save/Load** - Full persistence system

### 🚧 In Progress (Phase 5)
- [ ] **Scene Files** - Create .tscn scenes in Godot editor (see SCENE_STRUCTURES.md)
- [ ] **Visual Polish** - Animations, particles, screen shake
- [ ] **Audio Hooks** - Sound effects and music integration
- [ ] **Placeholder Art** - Sprites for champions, enemies, cards

### 📋 Planned (Post-MVP)
- [ ] More champions (10-20 total)
- [ ] More bosses and regions
- [ ] Status effects (poison, burn, stun, etc.)
- [ ] Advanced card mechanics
- [ ] Tutorial system
- [ ] Balance pass

---

## Getting Started

### Prerequisites
- **Godot Engine 4.3+** - [Download Here](https://godotengine.org/download)
- **Git** (optional, for cloning)

### Installation

1. **Clone or download** this repository
   ```bash
   git clone <your-repo-url>
   cd als-tavern
   ```

2. **Open in Godot**
   - Launch Godot Engine
   - Click "Import"
   - Select `project.godot`
   - Click "Import & Edit"

3. **Create Scene Files**
   - Follow **SCENE_STRUCTURES.md** to create all .tscn files
   - Start with `main_menu.tscn`, then `battle_scene.tscn`

4. **Run the Game**
   - Press F5 or click Play
   - Start exploring!

### Quick Setup Guide
See **SETUP_INSTRUCTIONS.md** for detailed step-by-step instructions.

---

## Documentation

- **[GAME_DESIGN_DOC.md](GAME_DESIGN_DOC.md)** - Complete game design specification
- **[BUILD_PLAN.md](BUILD_PLAN.md)** - Development roadmap and task breakdown
- **[SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)** - Installation and configuration guide
- **[SCENE_STRUCTURES.md](SCENE_STRUCTURES.md)** - Detailed scene creation instructions

---

## Project Structure

```
als-tavern/
├── data/                  # JSON data files
│   ├── champions.json     # Champion definitions
│   ├── cards.json         # Card effects and stats
│   └── enemies.json       # Enemy types and attacks
├── scripts/
│   ├── managers/          # Global singletons
│   ├── battle/            # Combat system
│   ├── champions/         # Champion classes
│   ├── enemies/           # Enemy AI
│   ├── map/               # Map generation
│   └── ui/                # UI components
├── scenes/                # Scene files (create these)
└── assets/                # Art, audio, fonts
```

---

## Adding Content

### Add a New Card
1. Open `data/cards.json`
2. Add new card entry with ID, stats, and effect
3. Add card ID to champion's card pool in `champions.json`

### Add a New Enemy
1. Open `data/enemies.json`
2. Add enemy with HP, damage, defense, attacks
3. Enemy will appear in battle encounters

### Add a New Champion
1. Add to `champions.json` with stats and core cards
2. Create 5+ cards for the champion in `cards.json`
3. Set `"unlocked": false` (unlock via boss defeat or story)

---

## Development Roadmap

### Phase 1: Core Combat ✅
- Turn-based battle system
- Champions, cards, enemies
- Basic UI

### Phase 2: Content Expansion ✅
- 10 enemies with AI
- XP and leveling
- Card unlocking

### Phase 3: Map System ✅
- Procedural generation
- Shop, rest, shrine nodes
- Save/load

### Phase 4: Recruitment ✅
- Boss battles
- Champion unlocking
- Deck builder UI

### Phase 5: Polish 🚧
- Animations
- Sound effects
- Visual effects
- Playtesting

---

## Technology Stack

- **Engine:** Godot 4.3+
- **Language:** GDScript
- **Data Format:** JSON
- **Platform:** Windows/Mac/Linux

---

## Contributing

This is a personal project, but suggestions are welcome!

1. Check **BUILD_PLAN.md** for tasks
2. Follow existing code style
3. Test changes thoroughly
4. Submit issues or pull requests

---

## License

See [LICENSE](LICENSE) file for details.

---

## Credits

**Inspiration:**
- Slay the Spire (deck-building mechanics)
- Final Fantasy (party-based combat)
- Darkest Dungeon (death penalties, progression)

**Built with:** Godot Engine 4.3+

---

## Contact

For questions or feedback, please open an issue on the repository.

---

**Let's build an epic card battle game! 🎮**
