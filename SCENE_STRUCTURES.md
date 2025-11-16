# Scene Structure Guide

This document provides detailed instructions for creating all scene (.tscn) files in the Godot editor.

---

## Table of Contents
1. [Main Menu](#main-menu)
2. [Party Selection](#party-selection)
3. [Map Scene](#map-scene)
4. [Battle Scene](#battle-scene)
5. [UI Components](#ui-components)
6. [Map Node UIs](#map-node-uis)

---

## Main Menu

**File:** `scenes/main_menu.tscn`
**Script:** `scripts/ui/main_menu.gd`

### Node Structure
```
MainMenu (Control) [main_menu.gd]
├── Background (ColorRect)
│   └── (color: #1a1a2e, anchor: full rect)
├── VBoxContainer
│   ├── TitleLabel (Label)
│   │   └── (text: "ALS TAVERN", font_size: 64, horizontal_alignment: center)
│   ├── VSeparator (custom minimum size: 50)
│   ├── MenuButtons (VBoxContainer)
│   │   ├── NewGameButton (Button)
│   │   │   └── (text: "New Game", custom_minimum_size: (200, 50))
│   │   ├── ContinueButton (Button)
│   │   │   └── (text: "Continue", custom_minimum_size: (200, 50))
│   │   ├── SettingsButton (Button)
│   │   │   └── (text: "Settings", custom_minimum_size: (200, 50))
│   │   └── QuitButton (Button)
│   │       └── (text: "Quit", custom_minimum_size: (200, 50))
│   ├── VSeparator (custom minimum size: 20)
│   └── VersionLabel (Label)
│       └── (text: "v1.0.0", font_size: 12, horizontal_alignment: center)
└── ConfirmDialog (ConfirmationDialog)
    └── (title: "Start New Game?", dialog_text: "...", ok_button_text: "Yes")
```

### Setup Steps
1. Create Control node, rename to "MainMenu", attach script
2. Add ColorRect child (Background), anchor to full rect, set color to dark blue
3. Add VBoxContainer child, center it (anchors preset: Center)
4. Add children as shown above
5. Connect button signals to script methods
6. Save scene

---

## Party Selection

**File:** `scenes/ui/party_selection.tscn`
**Script:** `scripts/ui/party_selection_ui.gd`

### Node Structure
```
PartySelection (Control) [party_selection_ui.gd]
├── Background (ColorRect)
├── MarginContainer
│   └── VBoxContainer
│       ├── TitleLabel (Label) [text: "SELECT YOUR PARTY"]
│       ├── ChampionSlotsContainer (HBoxContainer)
│       │   ├── ChampionSlot1 (Panel)
│       │   │   └── VBoxContainer
│       │   │       ├── Portrait1 (ColorRect)
│       │   │       ├── NameLabel1 (Label)
│       │   │       ├── StatsLabel1 (Label)
│       │   │       └── CardsContainer1 (HBoxContainer)
│       │   ├── ChampionSlot2 (Panel) [same structure]
│       │   └── ChampionSlot3 (Panel) [same structure]
│       ├── ButtonsContainer (HBoxContainer)
│       │   ├── BackButton (Button)
│       │   └── ConfirmButton (Button)
│       └── GoldLabel (Label)
├── ChampionPickerPanel (Panel) [visible: false]
│   └── MarginContainer
│       └── VBoxContainer
│           ├── PickerTitle (Label) [text: "Choose Champion"]
│           ├── ChampionsGrid (GridContainer) [columns: 3]
│           └── ClosePickerButton (Button)
└── DeckBuilderPanel (Panel) [visible: false]
    └── MarginContainer
        └── VBoxContainer
            ├── BuilderTitle (Label) [text: "Build Deck"]
            ├── CardsGrid (GridContainer) [columns: 4]
            ├── SelectedCounter (Label)
            ├── HBoxContainer
            │   ├── ClearButton (Button)
            │   └── SaveDeckButton (Button)
            └── CloseBuilderButton (Button)
```

### Setup Steps
1. Create Control node "PartySelection", attach script
2. Add all children as shown, use Panels for champion slots
3. Set ChampionPickerPanel and DeckBuilderPanel visible to false initially
4. Connect button pressed signals to script
5. Style panels with borders, backgrounds
6. Save scene

---

## Map Scene

**File:** `scenes/map/map_scene.tscn`
**Script:** `scripts/map/map_scene.gd`

### Node Structure
```
MapScene (Control) [map_scene.gd]
├── MapGenerator (Node) [map_generator.gd]
├── Background (ColorRect)
├── MapContainer (CenterContainer)
│   ├── NodeGrid (Control) [for positioning nodes]
│   ├── PathLines (Control) [for drawing paths, custom _draw()]
│   └── PlayerMarker (Sprite2D or ColorRect)
├── UIElements (Control)
│   ├── TopBar (HBoxContainer)
│   │   ├── GoldLabel (Label)
│   │   ├── FloorLabel (Label)
│   │   └── PartyButton (Button)
│   └── InfoLabel (Label)
└── EventPanel (Panel) [visible: false]
    └── [Shop/Rest/Shrine UI instances will be added at runtime]
```

### Setup Steps
1. Create Control node "MapScene", attach script
2. Add MapGenerator node child, attach map_generator.gd
3. Add Background ColorRect
4. Add MapContainer and children
5. NodeGrid will be populated at runtime with node instances
6. Save scene

---

## Battle Scene

**File:** `scenes/battle/battle_scene.tscn`
**Script:** `scripts/battle/battle_scene.gd`

### Node Structure
```
BattleScene (Control) [battle_scene.gd]
├── BattleManager (Node) [battle_manager.gd]
├── Background (ColorRect) [color: #2a2a3e]
├── ChampionsContainer (VBoxContainer) [anchor: left, position: (50, 100)]
│   ├── ChampionDisplay1 (Control) [champion_display.gd]
│   ├── ChampionDisplay2 (Control) [champion_display.gd]
│   └── ChampionDisplay3 (Control) [champion_display.gd]
├── EnemiesContainer (HBoxContainer) [anchor: right, position: (800, 200)]
│   ├── EnemyDisplay1 (Control) [enemy_display.gd]
│   ├── EnemyDisplay2 (Control) [enemy_display.gd]
│   └── EnemyDisplay3 (Control) [enemy_display.gd]
├── Hand (Control) [hand_ui.gd, anchor: bottom center, position: (400, 600)]
│   └── CardsContainer (HBoxContainer)
├── UIElements (Control)
│   ├── TopBar (HBoxContainer) [anchor: top, full width]
│   │   ├── PhaseLabel (Label)
│   │   ├── ActionsLabel (Label)
│   │   ├── GoldLabel (Label)
│   │   ├── DeckCountLabel (Label)
│   │   └── DiscardCountLabel (Label)
│   └── EndTurnButton (Button) [anchor: bottom right]
└── VictoryDefeatScreen (Panel) [visible: false, anchor: full rect]
    └── (victory_defeat_ui.gd structure)
```

### Setup Steps
1. Create Control node "BattleScene", attach script
2. Add BattleManager node, attach battle_manager.gd
3. Add Background ColorRect
4. Create ChampionsContainer on left, EnemiesContainer on right
5. Add 3 ChampionDisplay and 3 EnemyDisplay controls (attach scripts)
6. Add Hand UI at bottom center
7. Add UI elements and EndTurnButton
8. Connect EndTurnButton pressed signal to `_on_end_turn_button_pressed`
9. Save scene

---

## UI Components

### ChampionDisplay

**File:** `scenes/ui/champion_display.tscn`
**Script:** `scripts/ui/champion_display.gd`

```
ChampionDisplay (Control) [champion_display.gd]
├── BackgroundPanel (Panel)
├── Portrait (ColorRect) [size: 80x80]
├── NameLabel (Label)
├── HPBar (ProgressBar)
├── HPText (Label)
├── BlockIndicator (Label) [visible: false initially]
├── StatusIconsContainer (HBoxContainer)
└── ActionsContainer (HBoxContainer)
    ├── AttackButton (Button) [text: "Attack"]
    └── DefendButton (Button) [text: "Defend"]
```

**Setup:**
1. Create Control node, attach champion_display.gd
2. Add all children, position manually or use containers
3. Connect button signals to script methods
4. Save scene

### EnemyDisplay

**File:** `scenes/ui/enemy_display.tscn`
**Script:** `scripts/ui/enemy_display.gd`

```
EnemyDisplay (Control) [enemy_display.gd]
├── BackgroundPanel (Panel)
├── SpriteContainer (ColorRect) [size: 100x100]
├── NameLabel (Label)
├── HPBar (ProgressBar)
├── HPText (Label)
├── BlockIndicator (Label) [visible: false]
└── TypeBadge (Label) [visible: false]
```

**Setup:**
1. Create Control node, attach enemy_display.gd
2. Add children
3. Set SpriteContainer to different colors for enemy types
4. Set mouse_filter to "Pass" to enable clicking
5. Save scene

### CardUI

**File:** `scenes/ui/card_ui.tscn`
**Script:** `scripts/ui/card_ui.gd`

```
CardUI (Control) [card_ui.gd]
├── BackgroundPanel (ColorRect) [custom_minimum_size: (120, 180)]
├── VBoxContainer
│   ├── CardName (Label) [autowrap: true]
│   ├── CostLabel (Label)
│   ├── CardTypeIcon (TextureRect) [expand: false, size: 32x32]
│   └── DescriptionLabel (Label) [autowrap: true, font_size: 10]
```

**Setup:**
1. Create Control node, attach card_ui.gd
2. Add children in VBoxContainer for automatic layout
3. Set mouse_filter to "Pass" for drag detection
4. Style with borders, colors
5. Save scene

### HandUI

**File:** `scenes/ui/hand_ui.tscn`
**Script:** `scripts/ui/hand_ui.gd`

```
HandUI (Control) [hand_ui.gd]
└── CardsContainer (HBoxContainer) [alignment: center]
```

**Setup:**
1. Create Control node, attach hand_ui.gd
2. Add HBoxContainer child
3. Set HBoxContainer alignment to center
4. Card instances will be added at runtime
5. Save scene

---

## Map Node UIs

### Shop UI

**File:** `scenes/ui/shop_ui.tscn`
**Script:** `scripts/ui/shop_ui.gd`

```
ShopUI (Control) [shop_ui.gd]
├── BackgroundPanel (Panel)
├── MarginContainer
│   └── VBoxContainer
│       ├── TitleLabel (Label) [text: "SHOP"]
│       ├── GoldLabel (Label)
│       ├── ItemsGrid (GridContainer) [columns: 3]
│       ├── StatusLabel (Label)
│       └── CloseButton (Button)
```

### Rest UI

**File:** `scenes/ui/rest_ui.tscn`
**Script:** `scripts/ui/rest_ui.gd`

```
RestUI (Control) [rest_ui.gd]
├── BackgroundPanel (Panel)
├── MarginContainer
│   └── VBoxContainer
│       ├── TitleLabel (Label) [text: "REST SITE"]
│       ├── OptionsContainer (VBoxContainer)
│       │   ├── HealButton (Button) [text: "Heal All Champions"]
│       │   └── UpgradeSection (VBoxContainer)
│       │       ├── UpgradeLabel (Label)
│       │       └── UpgradeCardsGrid (GridContainer)
│       ├── StatusLabel (Label)
│       └── CloseButton (Button)
```

### Shrine UI

**File:** `scenes/ui/shrine_ui.tscn`
**Script:** `scripts/ui/shrine_ui.gd`

```
ShrineUI (Control) [shrine_ui.gd]
├── BackgroundPanel (Panel)
├── MarginContainer
│   └── VBoxContainer
│       ├── TitleLabel (Label) [text: "SHRINE OF BLESSINGS"]
│       ├── BlessingsContainer (HBoxContainer)
│       │   ├── BlessingCard1 (Panel)
│       │   ├── BlessingCard2 (Panel)
│       │   └── BlessingCard3 (Panel)
│       ├── StatusLabel (Label)
│       └── CloseButton (Button)
```

---

## Tips for Scene Creation

### Anchors & Positioning
- Use anchor presets for responsive layouts
- Center containers for main UI elements
- Use margins for padding

### Styling
- Set Panel stylebox overrides for borders and backgrounds
- Use theme overrides for consistent fonts/colors
- Add separators between sections

### Signals
- Connect button `pressed()` signals to script methods
- Use `@onready var` for node references in scripts

### Testing Scenes
- You can test individual scenes by setting them as the main scene temporarily
- Use placeholder data to test UI without full game flow

---

## Quick Setup Order

1. **Main Menu** - Start here, simplest scene
2. **Battle Scene** - Core gameplay, most important
3. **Party Selection** - Needed before battles
4. **Map Scene** - Exploration system
5. **UI Components** - Create as needed for battle scene
6. **Map Node UIs** - Shop, Rest, Shrine

---

**Need Help?**
- Check script comments for detailed node name requirements
- Use Godot's Scene → New Inherited Scene to create variants
- Test each scene individually before integrating

Happy building! 🎮
