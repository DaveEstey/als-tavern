# ALS TAVERN - Card Battle System Design Document

## Game Overview
A champion-based turn-based card battle game combining elements of Final Fantasy, Darkest Dungeon, and Slay the Spire. Players build a party of 3 champions, each contributing their unique cards to a shared deck, and battle through a procedurally generated map to defeat bosses and unlock new champions.

---

## CORE MECHANICS

### Combat System

#### Turn Structure
- **Player Phase:** Player acts first, selecting actions for all 3 champions
- **Enemy Phase:** All enemies act after player, attacking random champions
- **Turn Order:** Player chooses order of champion actions
- **Enemy Order:** Fixed order assigned at combat start

#### Champion Actions (Per Turn)
Each champion gets ONE action per turn:
- **Play a Card:** Drag card onto champion → select target → execute ability
- **Basic Attack:** Click champion → click "Attack" → select target → deal base damage
- **Basic Defend:** Click champion → click "Defend" → gain base block

#### Resource System
- **One action per champion** (no energy system for MVP)
- Future: Cards that cost 2 actions (one champion must use basic action to fuel another)

---

### Card System

#### Deck Composition
- **Deck Size:** Always 15 cards (5 per champion)
- **Active Party:** 3 champions selected before battle
- **Deck Auto-Build:** When party is selected, all their cards combine into shared deck
- **No Duplicates:** Each card appears once in deck
- **No Rarity:** All cards balanced equally (for now)

#### Card Mechanics
- **Draw:** 5 cards at start of each turn
- **Hand Limit:** None during turn
- **End of Turn:** Discard all unplayed cards
- **Deck Empty:** Shuffle discard pile back into deck
- **Card Targeting:** Drag card onto champion → drag/click to select enemy target
- **AOE Cards:** Target all enemies at once

#### Card Types
- **Attack Cards:** Deal damage (Warrior specialty)
- **Defense Cards:** Grant block/shields (Defender specialty)
- **Heal Cards:** Restore HP (Healer specialty)
- **Buff Cards:** Enhance allies (future champions)
- **Debuff Cards:** Weaken enemies (future champions)
- **Utility Cards:** Draw, energy, special effects (future champions)

---

### Champion System

#### Party Composition
- **Active Party:** 3 champions in battle
- **Party Selection:** Choose from unlocked champion roster
- **Swapping:** Can change party between encounters (not mid-battle)
- **Deck Updates:** Deck automatically rebuilds when party changes

#### Champion Stats
- **HP:** Health points
- **Damage:** Base damage for attacks (adds to card damage)
- **Defense:** Damage reduction

#### Champion Progression
- **Leveling:** Shared XP after each battle
- **Level Benefits:** Increases HP, Damage, Defense stats
- **Card Unlocks:** Purchase from shops or earn upgrade points
- **Card Upgrades:** Purchase better versions (more damage, defense, special effects)

#### Death & Revival
- **Champion KO:** Can be revived with Healer cards
- **Party Wipe:** Return to last visited city/resurrection point
- **Death Penalty:**
  - Lose non-permanent resources
  - Gold drops at death location (must retrieve)
  - Must travel back through map (chance of random encounters)

---

## STARTER CHAMPIONS

### 1. WARRIOR (Attacker)
**Role:** High-damage dealer
**Starting HP:** 40
**Starting Damage:** 10
**Starting Defense:** 5

**5 Core Cards:**
1. **Heavy Strike**
   - Cost: 1 action
   - Effect: Deal 12 damage to target enemy

2. **Cleave**
   - Cost: 1 action
   - Effect: Deal 7 damage to ALL enemies

3. **Berserker Rage**
   - Cost: 1 action
   - Effect: Deal 8 damage. Warrior takes 3 damage.

4. **Execute**
   - Cost: 1 action
   - Effect: Deal 20 damage to enemy below 50% HP. Otherwise deal 8 damage.

5. **Power Strike**
   - Cost: 1 action
   - Effect: Deal 15 damage. Cannot defend next turn.

---

### 2. DEFENDER (Tank)
**Role:** Protector, damage mitigation
**Starting HP:** 60
**Starting Damage:** 6
**Starting Defense:** 12

**5 Core Cards:**
1. **Shield Bash**
   - Cost: 1 action
   - Effect: Deal 6 damage. Gain 5 Block.

2. **Taunt**
   - Cost: 1 action
   - Effect: Force all enemies to target Defender next turn.

3. **Iron Wall**
   - Cost: 1 action
   - Effect: Gain 15 Block.

4. **Counter Stance**
   - Cost: 1 action
   - Effect: Next time Defender is attacked, deal 10 damage back to attacker.

5. **Fortify**
   - Cost: 1 action
   - Effect: Gain 8 Block. Next turn, Defender gains +3 Block from all sources.

---

### 3. HEALER (Support)
**Role:** Sustain, keeping party alive
**Starting HP:** 30
**Starting Damage:** 5
**Starting Defense:** 8

**5 Core Cards:**
1. **Heal**
   - Cost: 1 action
   - Effect: Restore 10 HP to target ally.

2. **Prayer**
   - Cost: 1 action
   - Effect: Restore 8 HP to ALL allies.

3. **Regeneration**
   - Cost: 1 action
   - Effect: Target ally heals 4 HP at the start of their next 3 turns.

4. **Cleanse**
   - Cost: 1 action
   - Effect: Remove all debuffs from target ally. Heal 5 HP.

5. **Revive**
   - Cost: 1 action
   - Effect: Revive a fallen champion with 15 HP. (Can only use once per battle)

---

## ENEMY SYSTEM

### MVP Enemy Roster (10 Total)

#### Trash Mobs (7)
1. **Goblin Scout**
   - HP: 15
   - Attack: "Stab" (Deal 5 damage)

2. **Wolf**
   - HP: 20
   - Attack 1: "Bite" (Deal 6 damage)
   - Attack 2: "Howl" (Next attack deals +3 damage)

3. **Bandit**
   - HP: 18
   - Attack: "Slash" (Deal 7 damage)

4. **Skeleton Warrior**
   - HP: 22
   - Attack 1: "Bone Strike" (Deal 6 damage)
   - Attack 2: "Shield Block" (Gain 8 block)

5. **Dark Mage**
   - HP: 12
   - Attack 1: "Fireball" (Deal 8 damage)
   - Attack 2: "Drain" (Deal 5 damage, heal self 5 HP)

6. **Orc Grunt**
   - HP: 25
   - Attack: "Smash" (Deal 9 damage)

7. **Venomous Spider**
   - HP: 10
   - Attack 1: "Poison Bite" (Deal 3 damage, apply 2 poison per turn for 3 turns)
   - Attack 2: "Web" (Target champion can't act next turn - FUTURE)

#### Elites (2)
8. **Orc Warlord**
   - HP: 50
   - Attack 1: "Brutal Swing" (Deal 12 damage)
   - Attack 2: "War Cry" (Deal 8 damage to all champions)
   - Attack 3: "Enrage" (Gain +5 damage for rest of battle)

9. **Lich**
   - HP: 40
   - Attack 1: "Shadow Bolt" (Deal 10 damage)
   - Attack 2: "Life Drain" (Deal 8 damage, heal 8 HP)
   - Attack 3: "Summon Skeleton" (Summon 1 Skeleton Warrior - FUTURE)

#### Boss (1)
10. **Fire Knight** (Recruitable Champion)
   - HP: 100
   - Uses 5 ability cards (like player):
     - "Flame Strike" (Deal 15 fire damage)
     - "Fire Wave" (Deal 10 damage to all champions)
     - "Burning Armor" (Gain 12 block, attackers take 3 damage)
     - "Ignite" (Deal 8 damage, apply 5 burn per turn for 2 turns)
     - "Inferno" (Deal 25 damage, Fire Knight takes 5 damage)

---

## MAP SYSTEM

### Map Structure
- **Style:** Node-based (Slay the Spire style)
- **Size:** 20 nodes for MVP
- **Generation:** Procedurally generated paths
- **Movement:** Click to move to connected nodes
- **Backtracking:** Can move backwards through completed nodes
- **Encounter Rules:**
  - First visit to combat node: **Forced encounter**
  - Revisiting combat node: **Chance of encounter** (~30% chance)

### Node Types

#### Combat Nodes
- **Regular Battle:** 1-3 trash mobs
- **Elite Battle:** 1 elite enemy (harder, better rewards)
- **Boss Battle:** 1 boss (unlocks new champion on defeat)

#### Non-Combat Nodes
- **Rest Site:** Heal HP, upgrade cards (limited uses?)
- **Shop:** Buy card upgrades, stat-boosting items, remove cards
- **Shrine:** Gain temporary buff for next 1-3 battles
- **Treasure:** Free loot (gold, items, maybe card upgrade)
- **Event:** Hints on which direction to go, story moments (future)

### Map Progression
- **Campaign:** Persistent, single playthrough
- **Goal:** Defeat boss to unlock new champion
- **Expansion:** After first boss, new regions unlock with new bosses
- **Endgame:** Unlock all champions → face final boss

---

## PROGRESSION SYSTEMS

### Experience & Leveling
- **XP Gain:** Shared party XP after each battle
- **All Champions:** Even benched champions gain XP (or only active party?)
- **Level Benefits:**
  - Increased HP
  - Increased Damage
  - Increased Defense

### Card Acquisition
- **Starting Cards:** 5 core cards per champion (unlocked automatically)
- **New Cards:** Purchase from shops using gold/upgrade points
- **Card Pool:** Each champion has 15-20 total unlockable cards
- **Upgrades:** Purchase upgraded versions of existing cards
  - Example: Heavy Strike → Heavy Strike+ (12 → 18 damage)

### Resources
- **Gold:** Earned from battles, treasures, chests
  - Used to buy: Card upgrades, items, stat boosts
  - Drops at death location (must retrieve)

- **Upgrade Points:** Earned from leveling or special events
  - Used to: Unlock new cards, upgrade cards

- **Items:** Stat-boosting equipment (future expansion)
  - Example: "Warrior's Blade" (+5 Damage to Warrior)

### Persistence
- **Persistent:**
  - Champion unlocks
  - Champion levels
  - Card unlocks
  - Story progress

- **Non-Persistent (Lost on Death):**
  - Current run gold (dropped at location)
  - Temporary buffs
  - Battle state

---

## DECK BUILDING UI

### Party Selection Screen
```
+--------------------------------------------------+
|  PARTY SELECTION                                 |
+--------------------------------------------------+
|                                                  |
|   [Champion Slot 1]  [Champion Slot 2]  [Champion Slot 3] |
|   Click to select    Click to select     Click to select   |
|                                                  |
+--------------------------------------------------+
```

When champion is selected:
```
+--------------------------------------------------+
|  WARRIOR SELECTED                                |
+--------------------------------------------------+
|  HP: 40  |  Damage: 10  |  Defense: 5          |
|                                                  |
|  CARD LOADOUT (5 cards):                        |
|  [Card 1: Heavy Strike  ]  <-- Click to change  |
|  [Card 2: Cleave        ]  <-- Click to change  |
|  [Card 3: Berserker Rage]  <-- Click to change  |
|  [Card 4: Execute       ]  <-- Click to change  |
|  [Card 5: Power Strike  ]  <-- Click to change  |
|                                                  |
+--------------------------------------------------+
```

Clicking a card slot opens card selection:
```
+--------------------------------------------------+
|  SELECT CARD FOR WARRIOR - SLOT 1                |
+--------------------------------------------------+
|  UNLOCKED CARDS:                                 |
|  [ Heavy Strike ] (Starting card)                |
|  [ Whirlwind    ] (Unlocked - Level 3)          |
|  [ Charge       ] (Unlocked - Purchased)        |
|  [ Execute+     ] (Upgraded version - Locked)    |
|                                                  |
+--------------------------------------------------+
```

---

## BATTLE UI LAYOUT

### Screen Layout (Pixel Art Style)
```
+--------------------------------------------------------+
|  HP: 120/120    Gold: 250    Floor: 5/20              |
+--------------------------------------------------------+
|                                                        |
|                    [ENEMY 1]    [ENEMY 2]             |
|                     HP: 20/30    HP: 15/15            |
|                                                        |
|                                                        |
|                                                        |
|                                                        |
|  [WARRIOR]         HAND (5 cards):                    |
|  HP: 35/40        [Card] [Card] [Card] [Card] [Card]  |
|  Block: 0                                              |
|                   Drag card onto champion, then target |
|  [DEFENDER]                                            |
|  HP: 60/60                                             |
|  Block: 5         [Attack] [Defend] (Basic actions)   |
|                                                        |
|  [HEALER]                                              |
|  HP: 28/30                                             |
|  Block: 0                                              |
|                                                        |
+--------------------------------------------------------+
```

### Combat Flow
1. **Turn Start:** Draw 5 cards
2. **Player Phase:**
   - Select champion (Warrior, Defender, or Healer)
   - Choose action:
     - **Play Card:** Drag card onto champion → Select target → Execute
     - **Basic Attack:** Click "Attack" button → Select enemy target
     - **Basic Defend:** Click "Defend" button → Gain block
   - Repeat for remaining champions
3. **Enemy Phase:** Each enemy attacks random champion
4. **Turn End:** Discard unplayed cards, draw 5 new cards
5. **Repeat** until all enemies defeated or party wiped

---

## BATTLE MECHANICS DETAILS

### Block System
- **Block:** Temporary damage absorption
- **Duration:** Block persists across enemy attacks within same turn
- **Expiration:** Block resets to 0 at start of next player turn
- **Stacking:** Multiple block sources stack additively

### Damage Calculation
- **Attack Damage:** (Card Damage + Champion's Base Damage) - Enemy Defense
- **Received Damage:** (Enemy Attack) - (Block + Champion's Defense)
- **Minimum Damage:** Always at least 1 damage (can't reduce to 0)

### Status Effects (Future Expansion)
- **Poison:** Deal X damage per turn for Y turns
- **Burn:** Deal X damage per turn for Y turns
- **Regeneration:** Heal X HP per turn for Y turns
- **Strength:** Increase damage dealt
- **Weak:** Decrease damage dealt
- **Vulnerable:** Increase damage taken
- **Stun:** Skip next turn

---

## VICTORY & REWARDS

### Battle Victory
**Rewards:**
- **XP:** Shared among all champions
- **Gold:** 10-50 gold depending on enemy difficulty
- **Random Loot:** 10% chance of item drop
- **Boss Reward:** Unlock boss as playable champion

### Boss Defeat Unlocks
- **Fire Knight Unlocked:** New champion added to roster
- **Fire Knight Cards:** 5 new fire-themed cards available
- **Map Expansion:** New region unlocked (future)

---

## DEFEAT & RESURRECTION

### Party Wipe
**Consequences:**
- Return to last visited **City/Resurrection Point**
- **Lose:** Non-permanent resources (consumables, temporary buffs)
- **Drop Gold:** Gold dropped at death location
- **Retrieval:** Must travel back to retrieve gold
- **Encounter Risk:** Random encounters possible when backtracking

**Keep:**
- Champion levels
- Unlocked champions
- Unlocked cards
- Permanent items
- Story progress

---

## DEVELOPMENT PHASES

### Phase 1: Core Combat System ✓
**Goal:** Functional turn-based battle system

**Features:**
- Turn-based combat loop (player → enemies)
- 3 starter champions with stats
- 15 starter cards (5 per champion)
- Basic Attack/Defend actions
- Card drag-and-drop onto champions
- Target selection
- HP, damage, block mechanics
- 1 test enemy
- Victory/defeat conditions
- Basic battle UI

**Deliverable:** Can fight and win/lose a battle

---

### Phase 2: Content Expansion
**Goal:** Variety of enemies, cards, progression

**Features:**
- 10 unique enemies (7 trash, 2 elite, 1 boss)
- Enemy AI (random targeting, attack patterns)
- XP and leveling system
- Stat increases on level up
- Battle rewards (XP, gold)
- Card unlock system (5 additional cards per champion)
- Card upgrade system (basic)
- Death/revival mechanic

**Deliverable:** Can fight multiple enemy types, level up, unlock cards

---

### Phase 3: Map & Exploration
**Goal:** World map with node-based progression

**Features:**
- Procedurally generated node map (20 nodes)
- Node types: Battle, Elite, Boss, Rest, Shop, Shrine, Treasure
- Map navigation (click to move)
- Backtracking with encounter chance
- Rest site (heal, upgrade cards)
- Shop (buy upgrades, items)
- Shrine (temporary buffs)
- Map persistence (save/load map state)

**Deliverable:** Can explore map, encounter battles, use services

---

### Phase 4: Champion Recruitment
**Goal:** Defeat bosses to unlock new champions

**Features:**
- Boss battle (Fire Knight)
- Boss defeat → unlock as champion
- Fire Knight champion with 5 cards
- Party selection UI (choose 3 from 4 champions)
- Deck building UI (select 5 cards per champion)
- Deck auto-update on party change
- Champion swap between encounters

**Deliverable:** Can defeat boss, unlock Fire Knight, use in party

---

### Phase 5: Polish & Juice
**Goal:** Improve feel, visuals, sound

**Features:**
- Card play animations
- Damage number pop-ups
- Screen shake on big hits
- Card hover effects
- Smooth transitions
- Sound effect hooks (play/attack/damage/heal/death)
- Music hooks (battle music, exploration music)
- Particle effects (fire, blood, shields)
- UI polish (tooltips, card preview)

**Deliverable:** Game feels good to play

---

## FUTURE EXPANSION ROADMAP

### Post-MVP Features
- **More Champions:** 10-20 total champions
  - Strategist (card draw specialist)
  - Buffer (ally enhancement)
  - Debuffer (enemy weakening)
  - Assassin (high single-target damage)
  - Summoner (spawn allies)

- **More Bosses:** 5-10 bosses across multiple regions
  - Ice Queen (frost abilities)
  - Shadow Assassin (stealth, crits)
  - Ancient Dragon (multi-phase fight)

- **More Maps:** 5 regions with unique themes
  - Dark Forest
  - Frozen Wastes
  - Volcanic Caverns
  - Haunted Castle
  - Celestial Tower

- **Advanced Mechanics:**
  - Status effects (poison, burn, stun)
  - Multi-target cards
  - Cards costing 2 actions
  - Champion synergies
  - Combo system

- **Meta Progression:**
  - Permanent unlocks
  - Achievement system
  - Challenge modes
  - Difficulty settings

---

## TECHNICAL SPECIFICATIONS

### Engine & Tools
- **Engine:** Godot 4.3+
- **Language:** GDScript
- **Resolution:** 1280x720 (scalable)
- **Platform:** Windows/Linux/Mac

### Project Structure
```
als-tavern/
├── project.godot
├── scenes/
│   ├── battle/
│   │   ├── battle_scene.tscn
│   │   ├── champion_card.tscn
│   │   ├── enemy.tscn
│   ├── map/
│   │   ├── map_scene.tscn
│   │   ├── map_node.tscn
│   ├── ui/
│   │   ├── party_selection.tscn
│   │   ├── deck_builder.tscn
│   │   ├── shop.tscn
│   ├── main_menu.tscn
├── scripts/
│   ├── battle/
│   │   ├── battle_manager.gd
│   │   ├── champion.gd
│   │   ├── enemy.gd
│   │   ├── card.gd
│   ├── map/
│   │   ├── map_generator.gd
│   │   ├── node.gd
│   ├── managers/
│   │   ├── game_manager.gd
│   │   ├── party_manager.gd
│   │   ├── card_database.gd
├── data/
│   ├── champions.json
│   ├── cards.json
│   ├── enemies.json
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── fonts/
```

### Data Files (JSON)

**champions.json:**
```json
{
  "warrior": {
    "name": "Warrior",
    "starting_hp": 40,
    "starting_damage": 10,
    "starting_defense": 5,
    "core_cards": ["heavy_strike", "cleave", "berserker_rage", "execute", "power_strike"]
  }
}
```

**cards.json:**
```json
{
  "heavy_strike": {
    "name": "Heavy Strike",
    "champion": "warrior",
    "type": "attack",
    "cost": 1,
    "effect": "deal_damage",
    "value": 12,
    "target": "single_enemy"
  }
}
```

**enemies.json:**
```json
{
  "goblin_scout": {
    "name": "Goblin Scout",
    "hp": 15,
    "attacks": [
      {"name": "Stab", "damage": 5}
    ]
  }
}
```

---

## ACCEPTANCE CRITERIA (MVP)

### Must-Have Features
- [x] Turn-based combat (player → enemies)
- [x] 3 starter champions with unique stats
- [x] 15 starter cards (5 per champion)
- [x] Card drag-and-drop combat system
- [x] Basic Attack/Defend actions
- [x] At least 5 unique enemies
- [x] Boss battle (Fire Knight)
- [x] Map with 20 nodes
- [x] Battle, Elite, Boss, Rest, Shop nodes
- [x] XP and leveling system
- [x] Gold and rewards
- [x] Champion death/revival
- [x] Save/load system
- [x] Party selection UI
- [x] Deck building UI
- [x] Boss defeat unlocks champion

### Nice-to-Have
- [ ] Card animations
- [ ] Sound effects
- [ ] Particle effects
- [ ] Status effects (poison, burn)
- [ ] Multiple difficulty settings
- [ ] Tutorial system

---

## SUCCESS METRICS

**The MVP is successful when:**
1. Player can select 3 champions from roster
2. Player can build deck by selecting 5 cards per champion
3. Player can navigate map and engage in battles
4. Player can play cards to execute champion abilities
5. Player can use basic attack/defend actions
6. Player can defeat enemies and gain XP/gold
7. Player can level up champions (stats increase)
8. Player can visit shops to buy upgrades
9. Player can defeat boss to unlock new champion
10. Player can use newly unlocked champion in party
11. Game saves progress and can be loaded
12. Game is fun and engaging to play!

---

## DESIGN PHILOSOPHY

**Core Pillars:**
1. **Champion Identity:** Each champion feels unique with thematic cards
2. **Tactical Depth:** Choose when to play cards vs basic actions
3. **Risk/Reward:** High-power cards have drawbacks
4. **Progression:** Steady unlocks of new champions and cards
5. **Replayability:** Different champion combinations create varied strategies

**Inspirations:**
- **Final Fantasy:** Party-based combat, character classes, JRPG aesthetics
- **Slay the Spire:** Card-based combat, map progression, roguelike structure
- **Darkest Dungeon:** Death penalties, stress management, gothic atmosphere

---

**END OF DESIGN DOCUMENT**
