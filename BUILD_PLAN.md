# ALS TAVERN - Master Build Plan

This document breaks down the development into actionable phases with specific tasks.

---

## PHASE 1: CORE COMBAT SYSTEM (Foundation)

### 1.1 Project Setup
- [ ] Initialize Godot 4.x project
- [ ] Set up project structure (folders: scenes, scripts, data, assets)
- [ ] Configure project settings (resolution: 1280x720, window mode)
- [ ] Set up Git repository and .gitignore
- [ ] Create placeholder pixel art assets

### 1.2 Data Architecture
- [ ] Create JSON data files (champions.json, cards.json, enemies.json)
- [ ] Create data loading system (read JSON into game)
- [ ] Create Champion resource/class
- [ ] Create Card resource/class
- [ ] Create Enemy resource/class
- [ ] Implement CardDatabase singleton
- [ ] Implement GameManager singleton

### 1.3 Battle Scene Setup
- [ ] Create battle_scene.tscn (main battle container)
- [ ] Create champion UI elements (HP bar, portrait, action buttons)
- [ ] Create enemy UI elements (HP bar, sprite)
- [ ] Position champions on left side (staggered, Final Fantasy style)
- [ ] Position enemies on right side
- [ ] Create card hand UI at bottom center

### 1.4 Champion System
- [ ] Implement Champion class (HP, Damage, Defense stats)
- [ ] Create 3 starter champions (Warrior, Defender, Healer)
- [ ] Implement Basic Attack action (deal base damage)
- [ ] Implement Basic Defend action (gain base block)
- [ ] Champion HP tracking and display
- [ ] Champion death/KO state
- [ ] Champion revival mechanic (for Healer card)

### 1.5 Card System
- [ ] Implement Card class (name, cost, effect, target type)
- [ ] Create 15 starter cards (5 Warrior, 5 Defender, 5 Healer)
- [ ] Implement card visual (card UI with text/stats)
- [ ] Card hover effects (enlarge, show details)
- [ ] Deck shuffling system
- [ ] Draw 5 cards at turn start
- [ ] Discard hand at turn end
- [ ] Reshuffle discard pile when deck empty

### 1.6 Drag-and-Drop System
- [ ] Implement card drag from hand
- [ ] Highlight champion when card hovers over them
- [ ] Drop card on champion to "load" it
- [ ] Implement target selection (click enemy to target)
- [ ] Execute card effect on target
- [ ] Remove card from hand after play
- [ ] Visual feedback (card flies to target, animation)

### 1.7 Turn System
- [ ] Implement turn manager (player phase → enemy phase)
- [ ] Player phase: Allow 3 champion actions (card or basic action)
- [ ] Track which champions have acted
- [ ] Enemy phase: Each enemy attacks random champion
- [ ] Turn counter display
- [ ] End turn button

### 1.8 Combat Mechanics
- [ ] Damage calculation (attack + card damage - defense)
- [ ] Block system (temporary damage absorption)
- [ ] Block expiration (reset at turn start)
- [ ] HP reduction and display
- [ ] Death check (HP <= 0)
- [ ] Victory condition (all enemies dead)
- [ ] Defeat condition (all champions dead)

### 1.9 Enemy AI (Basic)
- [ ] Create 1 test enemy (Goblin Scout)
- [ ] Enemy attack action (deal damage to random champion)
- [ ] Random target selection
- [ ] Enemy turn execution

### 1.10 Battle Flow
- [ ] Battle start sequence (initialize champions, enemies, deck)
- [ ] Turn loop (player → enemies → repeat)
- [ ] Victory screen (show rewards)
- [ ] Defeat screen (return to menu)

**Phase 1 Deliverable:** Playable battle with 3 champions vs 1 enemy, can play cards and use basic actions.

---

## PHASE 2: CONTENT EXPANSION

### 2.1 Enemy Roster
- [ ] Create 7 trash mob enemies (Goblin, Wolf, Bandit, Skeleton, Mage, Orc, Spider)
- [ ] Give each enemy 1-2 unique attacks
- [ ] Create 2 elite enemies (Orc Warlord, Lich)
- [ ] Elite enemies with 3 attacks each
- [ ] Create boss enemy (Fire Knight)
- [ ] Boss uses 5 ability cards (like player)

### 2.2 Enemy AI Enhancements
- [ ] Multiple attack patterns (random selection)
- [ ] Enemy block/defend actions
- [ ] Enemy targeting logic (random champion)
- [ ] Elite enemy special abilities
- [ ] Boss AI (uses cards from hand)

### 2.3 XP & Leveling System
- [ ] XP rewards after battle (based on enemy difficulty)
- [ ] Shared XP distribution to all champions
- [ ] Level up system (XP thresholds)
- [ ] Stat increases on level up (HP, Damage, Defense)
- [ ] Level up notification/animation
- [ ] Display champion levels in UI

### 2.4 Rewards System
- [ ] Gold rewards after battle (10-50 gold)
- [ ] Victory screen with reward summary
- [ ] Random loot drops (10% chance)
- [ ] Boss defeat unlocks champion

### 2.5 Card Unlocking
- [ ] Create 5 additional cards per champion (total 10 per champion)
- [ ] Card unlock at specific levels (Level 3, 5, 7, etc.)
- [ ] Card unlock notification
- [ ] Unlocked cards available in deck builder

### 2.6 Card Upgrade System
- [ ] Create upgraded versions of core cards (+50% effectiveness)
- [ ] Upgrade purchase mechanic (at shops)
- [ ] Replace card with upgraded version in deck

### 2.7 Death & Revival
- [ ] Champion KO state (HP = 0, can't act)
- [ ] Healer "Revive" card functionality
- [ ] Party wipe detection (all champions dead)
- [ ] Return to resurrection point on wipe
- [ ] Gold drop at death location

**Phase 2 Deliverable:** 10 enemy types, leveling system, card unlocks, death mechanics.

---

## PHASE 3: MAP & EXPLORATION

### 3.1 Map Structure
- [ ] Create map_scene.tscn (node-based map)
- [ ] Implement node-based map layout (20 nodes)
- [ ] Procedural map generation (paths between nodes)
- [ ] Node types: Battle, Elite, Boss, Rest, Shop, Shrine, Treasure
- [ ] Visual representation of nodes (icons, paths)

### 3.2 Map Navigation
- [ ] Click node to move
- [ ] Show available nodes (connected to current)
- [ ] Disable unreachable nodes
- [ ] Current position indicator
- [ ] Backtracking (move to previous nodes)

### 3.3 Encounter System
- [ ] First visit to combat node → forced battle
- [ ] Revisit combat node → 30% chance of encounter
- [ ] Random enemy selection for battle nodes
- [ ] Elite nodes spawn elite enemies
- [ ] Boss nodes spawn boss enemy

### 3.4 Rest Site
- [ ] Rest UI scene
- [ ] Heal party HP (full heal or percentage?)
- [ ] Upgrade card option (choose 1 card to upgrade)
- [ ] Limited uses per run? Or unlimited?

### 3.5 Shop System
- [ ] Shop UI scene
- [ ] Display purchasable items:
  - Card upgrades (50 gold each)
  - Stat-boosting items (100 gold each)
  - Card removal (75 gold each)
- [ ] Purchase functionality (deduct gold, grant item)
- [ ] Shop inventory (random or fixed?)

### 3.6 Shrine System
- [ ] Shrine UI scene
- [ ] Choose buff/blessing:
  - +5 damage next battle
  - +10 HP next battle
  - Draw +2 cards next battle
- [ ] Apply temporary buff
- [ ] Remove buff after battle

### 3.7 Treasure Nodes
- [ ] Treasure UI scene
- [ ] Random loot generation (gold, items, card upgrade)
- [ ] Loot notification

### 3.8 Map Persistence
- [ ] Save current map state
- [ ] Save visited nodes
- [ ] Save current position
- [ ] Load map on game start

**Phase 3 Deliverable:** Explorable map with 20 nodes, various node types, navigation system.

---

## PHASE 4: CHAMPION RECRUITMENT & DECK BUILDING

### 4.1 Boss Battle & Recruitment
- [ ] Boss battle scene (Fire Knight)
- [ ] Boss defeat triggers unlock
- [ ] Add Fire Knight to champion roster
- [ ] Unlock Fire Knight's 5 cards
- [ ] Unlock notification screen

### 4.2 Party Selection UI
- [ ] Create party_selection.tscn
- [ ] Display 3 champion slots
- [ ] Click slot to open champion picker
- [ ] Display unlocked champions
- [ ] Select champion to add to party
- [ ] Show champion stats (HP, Damage, Defense, Level)

### 4.3 Deck Building UI
- [ ] Create deck_builder.tscn
- [ ] Display 3 columns (one per selected champion)
- [ ] Each column shows 5 card slots
- [ ] Click card slot to open card picker
- [ ] Display all unlocked cards for that champion
- [ ] Select card to add to slot
- [ ] Show card details on hover

### 4.4 Party & Deck Management
- [ ] PartyManager singleton (tracks active party)
- [ ] Deck auto-generation (combine 15 cards from 3 champions)
- [ ] Party swap between encounters
- [ ] Deck update when party changes
- [ ] Validate deck (must have 5 cards per champion)

### 4.5 Fire Knight Champion
- [ ] Create Fire Knight champion data
- [ ] Fire Knight stats (HP: 45, Damage: 12, Defense: 7)
- [ ] Fire Knight 5 cards:
  - Flame Strike (15 damage)
  - Fire Wave (10 damage to all)
  - Burning Armor (12 block, attackers take 3 damage)
  - Ignite (8 damage + 5 burn per turn for 2 turns)
  - Inferno (25 damage, self-damage 5)

**Phase 4 Deliverable:** Boss unlocks Fire Knight, can select Fire Knight in party, use Fire Knight cards in battle.

---

## PHASE 5: POLISH & JUICE

### 5.1 Animations
- [ ] Card draw animation (cards fly from deck to hand)
- [ ] Card play animation (card flies from hand to champion to target)
- [ ] Attack animation (champion moves toward enemy, hit flash)
- [ ] Damage number pop-ups (fly up and fade)
- [ ] Heal particle effect (green sparkles)
- [ ] Block shield visual (shield icon appears)
- [ ] Death animation (enemy fades out, champion collapses)

### 5.2 Visual Effects
- [ ] Screen shake on big hits (>15 damage)
- [ ] Card hover glow
- [ ] Valid drop zone highlight (green outline)
- [ ] Invalid drop zone highlight (red outline)
- [ ] Critical hit effect (red flash, bigger number)
- [ ] Fire particles for fire cards
- [ ] Blood splatter on damage
- [ ] Shield break effect

### 5.3 Sound System
- [ ] Create audio manager singleton
- [ ] Sound effect hooks:
  - Card draw (swish)
  - Card play (whoosh)
  - Attack hit (thud/slash)
  - Damage taken (grunt)
  - Heal (chime)
  - Block (shield clang)
  - Death (fall sound)
  - Victory (fanfare)
  - Defeat (sad music)
- [ ] Music hooks:
  - Main menu music
  - Map exploration music
  - Battle music
  - Boss battle music

### 5.4 UI/UX Polish
- [ ] Card tooltip (hover to see full description)
- [ ] Champion stat tooltips
- [ ] Button hover effects
- [ ] Smooth transitions between scenes
- [ ] Loading screen
- [ ] Victory/defeat screen animations
- [ ] Settings menu (volume, resolution, fullscreen)

### 5.5 Particle Effects
- [ ] Fire card particles (flames)
- [ ] Heal card particles (sparkles)
- [ ] Shield card particles (energy bubble)
- [ ] Critical hit particles (explosion)
- [ ] Level up particles (glow, stars)

**Phase 5 Deliverable:** Game feels polished, responsive, and satisfying to play.

---

## ADDITIONAL SYSTEMS (Post-MVP)

### Save/Load System
- [ ] Create save data structure (JSON or binary)
- [ ] Save champion roster (unlocked champions, levels)
- [ ] Save card unlocks
- [ ] Save current party
- [ ] Save current deck
- [ ] Save map progress
- [ ] Save gold and resources
- [ ] Load game state on start
- [ ] Auto-save after each battle/node

### Main Menu
- [ ] Create main_menu.tscn
- [ ] New Game button → Party selection
- [ ] Continue button → Load saved game
- [ ] Settings button → Settings menu
- [ ] Quit button → Exit game
- [ ] Title art/logo

### Settings Menu
- [ ] Volume sliders (master, music, SFX)
- [ ] Resolution dropdown
- [ ] Fullscreen toggle
- [ ] Controls display
- [ ] Back button

### Tutorial System (Optional)
- [ ] First-time player flag
- [ ] Tutorial overlay on first battle
- [ ] Step-by-step instructions
- [ ] Highlight interactable elements
- [ ] Skip tutorial option

---

## TESTING CHECKLIST

### Combat System Tests
- [ ] Can play all 15 starter cards
- [ ] Basic Attack deals correct damage
- [ ] Basic Defend grants correct block
- [ ] Block expires at turn start
- [ ] Damage calculation correct (stats + card - defense)
- [ ] Champions can die and be revived
- [ ] Party wipe triggers defeat
- [ ] All enemies defeated triggers victory

### Map System Tests
- [ ] Can navigate to all 20 nodes
- [ ] Combat nodes trigger battles
- [ ] Backtracking has encounter chance
- [ ] Rest site heals party
- [ ] Shop purchases work correctly
- [ ] Shrine buffs apply and expire
- [ ] Map state persists after battle

### Progression Tests
- [ ] XP awarded after battles
- [ ] Champions level up at correct thresholds
- [ ] Stats increase on level up
- [ ] Cards unlock at correct levels
- [ ] Boss defeat unlocks Fire Knight
- [ ] Fire Knight usable in party
- [ ] Deck updates when party changes

### Save/Load Tests
- [ ] Game saves after each node
- [ ] Save includes all progress (levels, unlocks, gold)
- [ ] Load restores exact game state
- [ ] No data loss on crash/quit

---

## BUG PREVENTION CHECKLIST

### Common Issues to Avoid
- [ ] Deck reshuffle when empty (prevent infinite loop)
- [ ] Prevent playing cards for KO'd champions
- [ ] Prevent targeting dead enemies
- [ ] Prevent negative HP/block values
- [ ] Prevent playing cards without valid targets
- [ ] Handle edge case: all enemies die from AOE
- [ ] Handle edge case: champion revived mid-turn
- [ ] Prevent double-click exploits
- [ ] Validate deck has exactly 15 cards before battle

---

## PERFORMANCE OPTIMIZATION

### Optimization Tasks
- [ ] Object pooling for damage numbers
- [ ] Lazy load card images
- [ ] Optimize map generation (cache results)
- [ ] Reduce draw calls (batch sprites)
- [ ] Profile FPS during battle (target 60 FPS)

---

## FINAL POLISH CHECKLIST

### Before Release
- [ ] All core features working
- [ ] No game-breaking bugs
- [ ] All 3 starter champions playable
- [ ] Fire Knight unlockable
- [ ] Map fully explorable
- [ ] Save/load functional
- [ ] Placeholder art acceptable
- [ ] Sound hooks in place (even without assets)
- [ ] Win condition achievable
- [ ] Game is fun!

---

## DEPLOYMENT

### Build & Package
- [ ] Export for Windows (64-bit)
- [ ] Export for Linux (64-bit)
- [ ] Export for Mac (if possible)
- [ ] Test exported builds
- [ ] Create README with instructions
- [ ] Package assets separately (for modding)

---

## ESTIMATED TIMELINE

**Phase 1 (Core Combat):** 2-3 days
**Phase 2 (Content):** 1-2 days
**Phase 3 (Map System):** 2-3 days
**Phase 4 (Recruitment):** 1 day
**Phase 5 (Polish):** 1-2 days

**Total MVP:** 7-11 days (active development)

---

## SUCCESS CRITERIA

**The project is complete when:**
1. ✓ Player can fight battles using 3 champions
2. ✓ Player can play cards and use basic actions
3. ✓ Player can navigate map with 20 nodes
4. ✓ Player can defeat boss to unlock Fire Knight
5. ✓ Player can use Fire Knight in party
6. ✓ Player can level up and unlock cards
7. ✓ Player can save and load progress
8. ✓ Game is playable from start to boss victory
9. ✓ Game is enjoyable and strategic

---

**Let's build this! 🎮**
