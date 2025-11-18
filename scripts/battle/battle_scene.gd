extends Control
## BattleScene - Main battle scene controller that coordinates UI with BattleManager
##
## This script attaches to the root Control node of the battle scene and manages
## all battle UI elements, connecting player actions to the BattleManager and
## updating displays based on battle events.
##
## SCENE TREE STRUCTURE (to be created in Godot editor):
## ========================================================
## BattleScene (Control) - this script
## ├── BattleManager (Node - battle_manager.gd)
## ├── Background (ColorRect) - full screen background
## │   └── [Properties] anchors_preset = 15 (full rect), color = dark gray
## ├── Champions (VBoxContainer) - left side of screen
## │   └── [Properties] anchors_preset = 4 (left), margin_left = 50, margin_top = 100
## │   ├── ChampionDisplay1 (Control - champion_display.gd)
## │   ├── ChampionDisplay2 (Control - champion_display.gd)
## │   └── ChampionDisplay3 (Control - champion_display.gd)
## ├── Enemies (HBoxContainer) - right side of screen
## │   └── [Properties] anchors_preset = 6 (right), margin_right = -50, margin_top = 100
## │   ├── EnemyDisplay1 (Control - enemy_display.gd)
## │   ├── EnemyDisplay2 (Control - enemy_display.gd)
## │   └── EnemyDisplay3 (Control - enemy_display.gd)
## ├── Hand (Control - hand_ui.gd) - bottom center of screen
## │   └── [Properties] anchors_preset = 7 (bottom center), margin_bottom = -20
## │   └── Cards (HBoxContainer)
## │       └── [Properties] alignment = center, separation = 10
## ├── UIElements (Control) - overlay UI
## │   ├── DeckCount (Label) - top left
## │   │   └── [Properties] text = "Deck: 0", anchors_preset = 0 (top left)
## │   ├── DiscardCount (Label) - top left, below deck
## │   │   └── [Properties] text = "Discard: 0"
## │   ├── GoldLabel (Label) - top right
## │   │   └── [Properties] text = "Gold: 0", anchors_preset = 1 (top right)
## │   ├── PhaseLabel (Label) - top center
## │   │   └── [Properties] text = "Player Turn", anchors_preset = 5 (top center)
## │   ├── ActionsLabel (Label) - top center, below phase
## │   │   └── [Properties] text = "Actions: 3/3"
## │   └── EndTurnButton (Button) - bottom right
## │       └── [Properties] text = "End Turn", anchors_preset = 3 (bottom right)
## └── VictoryDefeatScreen (Control) - full screen overlay, initially hidden
##     └── [Properties] visible = false, anchors_preset = 15 (full rect)
##     └── Panel (Panel)
##         └── VBoxContainer
##             ├── ResultLabel (Label) - "Victory!" or "Defeat!"
##             ├── RewardsLabel (Label) - shows XP and gold
##             └── ContinueButton (Button) - returns to map

# Node references - BattleManager
@onready var battle_manager: BattleManager = $BattleManager

# Node references - Champion displays (left side)
@onready var champion_displays: Array[Node] = [
	$ChampionsContainer/ChampionDisplay1,
	$ChampionsContainer/ChampionDisplay2,
	$ChampionsContainer/ChampionDisplay3
]

# Node references - Enemy displays (right side)
@onready var enemy_displays: Array[Node] = [
	$EnemiesContainer/EnemyDisplay1,
	$EnemiesContainer/EnemyDisplay2,
	$EnemiesContainer/EnemyDisplay3
]

# Node references - Hand and deck UI
@onready var hand_ui: Control = $Hand
@onready var deck_count_label: Label = $DeckCountLabel
@onready var discard_count_label: Label = $DiscardCountLabel
@onready var gold_label: Label = $GoldLabel
@onready var phase_label: Label = $PhaseLabel
@onready var actions_label: Label = $ActionsLabel
@onready var end_turn_button: Button = $EndTurnButton

# Node references - Victory/Defeat screen
@onready var victory_defeat_screen: Control = $VictoryDefeatScreen
@onready var result_label: Label = $VictoryDefeatScreen/VictoryDefeatLabel
@onready var rewards_label: Label = $VictoryDefeatScreen/RewardsLabel
@onready var continue_button: Button = $VictoryDefeatScreen/ContinueButton

# Manager references
var game_manager: Node


func _ready() -> void:
	# Get reference to GameManager (autoload)
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
	else:
		push_error("GameManager not found. Make sure it's set up as an autoload.")
		return

	# Connect BattleManager signals
	_connect_battle_signals()

	# Connect UI signals
	_connect_ui_signals()

	# Initialize battle with enemies from GameManager
	if game_manager and "current_battle_enemies" in game_manager:
		var enemy_ids: Array[String] = []
		var raw_enemies = game_manager.current_battle_enemies

		# Ensure proper typing
		if raw_enemies is Array:
			for enemy in raw_enemies:
				if enemy is String:
					enemy_ids.append(enemy)

		if enemy_ids.is_empty():
			push_warning("No enemies set in GameManager, using default test enemies")
			enemy_ids = ["goblin", "skeleton"]

		battle_manager.initialize_battle(enemy_ids)
	else:
		push_error("GameManager does not have current_battle_enemies")

	# Initial UI update
	update_all_displays()

	# Hide victory/defeat screen initially
	if victory_defeat_screen:
		victory_defeat_screen.hide()


## Connect all BattleManager signals to handler methods
func _connect_battle_signals() -> void:
	if not battle_manager:
		push_error("BattleManager not found")
		return

	battle_manager.turn_started.connect(_on_turn_started)
	battle_manager.card_drawn.connect(_on_card_drawn)
	battle_manager.card_played.connect(_on_card_played)
	battle_manager.champion_acted.connect(_on_champion_acted)
	battle_manager.damage_dealt.connect(_on_damage_dealt)
	battle_manager.champion_died.connect(_on_champion_died)
	battle_manager.enemy_died.connect(_on_enemy_died)
	battle_manager.battle_ended.connect(_on_battle_ended)

	print("BattleScene: All signals connected")


## Connect UI element signals
func _connect_ui_signals() -> void:
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)

	if continue_button:
		continue_button.pressed.connect(_on_continue_button_pressed)

	if hand_ui and hand_ui.has_signal("card_play_requested"):
		hand_ui.card_play_requested.connect(_on_card_play_requested)

	# Connect champion and enemy display targeting signals to hand_ui
	_connect_display_targeting_signals()


## Connect champion and enemy display targeting signals to hand_ui
func _connect_display_targeting_signals() -> void:
	if not hand_ui:
		return

	# Connect each champion display's targeting signal
	for i in range(champion_displays.size()):
		var display = champion_displays[i]
		if display and display.has_signal("champion_clicked_for_targeting"):
			if hand_ui.has_method("_on_champion_clicked"):
				display.champion_clicked_for_targeting.connect(hand_ui._on_champion_clicked)

	# Connect each enemy display's targeting signal
	for i in range(enemy_displays.size()):
		var display = enemy_displays[i]
		if display and display.has_signal("enemy_clicked_for_targeting"):
			if hand_ui.has_method("_on_enemy_clicked"):
				display.enemy_clicked_for_targeting.connect(hand_ui._on_enemy_clicked)


## Called when a new turn phase starts
func _on_turn_started(phase: String) -> void:
	print("BattleScene: Turn started - Phase: %s" % phase)

	# Update phase label
	if phase_label:
		match phase:
			"player_turn":
				phase_label.text = "PLAYER TURN"
				phase_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
				if end_turn_button:
					end_turn_button.disabled = false
			"enemy_turn":
				phase_label.text = "ENEMY TURN"
				phase_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
				if end_turn_button:
					end_turn_button.disabled = true
			"victory":
				phase_label.text = "VICTORY"
				phase_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2))
			"defeat":
				phase_label.text = "DEFEAT"
				phase_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	# Update all displays
	update_all_displays()


## Called when a card is drawn from the deck
func _on_card_drawn() -> void:
	print("BattleScene: Card drawn")

	# Update deck and discard counters
	_update_deck_counters()

	# Update hand UI (if hand_ui script has update method)
	if hand_ui and hand_ui.has_method("update_hand"):
		hand_ui.update_hand(battle_manager.hand)


## Called when a card is played
func _on_card_played(card: Card, caster: Champion, targets: Array) -> void:
	print("BattleScene: Card played - %s by %s" % [card.card_name, caster.champion_name])

	# TODO: Show card play animation
	# - Animate card moving from hand to center
	# - Show effect particles/animation
	# - Tween card to discard pile

	# Update displays
	update_all_displays()

	# Update hand UI
	if hand_ui and hand_ui.has_method("update_hand"):
		hand_ui.update_hand(battle_manager.hand)


## Called when a champion performs an action
func _on_champion_acted(champion: Champion, action_type: String) -> void:
	print("BattleScene: Champion acted - %s performed %s" % [champion.champion_name, action_type])

	# Update actions remaining
	_update_actions_label()


## Called when damage is dealt to any target
func _on_damage_dealt(source, target, amount: int) -> void:
	var source_name = _get_entity_name(source)
	var target_name = _get_entity_name(target)

	print("BattleScene: Damage dealt - %s -> %s: %d damage" % [source_name, target_name, amount])

	# TODO: Show damage number popup animation
	# - Create a damage label at target position
	# - Animate upward with fade out
	# - Color based on damage type (red for damage, green for healing)

	# Update displays
	update_champion_displays()
	update_enemy_displays()


## Called when a champion is knocked out
func _on_champion_died(champion: Champion) -> void:
	print("BattleScene: Champion died - %s" % champion.champion_name)

	# TODO: Show death animation
	# - Fade out champion display
	# - Show "KO" effect
	# - Gray out champion portrait

	update_champion_displays()


## Called when an enemy is defeated
func _on_enemy_died(enemy: Dictionary) -> void:
	print("BattleScene: Enemy died - %s" % enemy.get("name", "Unknown"))

	# TODO: Show death animation
	# - Fade out enemy display
	# - Show defeat particles
	# - Play death sound

	update_enemy_displays()

	# Check if all enemies defeated (victory)
	var all_dead = true
	for e in battle_manager.enemies:
		if not e.get("is_dead", false):
			all_dead = false
			break

	if all_dead:
		print("BattleScene: All enemies defeated!")


## Called when the battle ends
func _on_battle_ended(victory: bool) -> void:
	print("BattleScene: Battle ended - Victory: %s" % victory)

	# Show victory/defeat screen
	_show_victory_defeat_screen(victory)


## Update all champion displays with current stats
func update_champion_displays() -> void:
	if not battle_manager:
		return

	for i in range(min(champion_displays.size(), battle_manager.champions.size())):
		var display = champion_displays[i]
		var champion = battle_manager.champions[i]

		if display and display.has_method("update_display"):
			display.update_display(champion)
		elif display:
			# Fallback if display doesn't have update_display method
			# Hide or show based on champion existence
			display.visible = (champion != null)


## Update all enemy displays with current stats
func update_enemy_displays() -> void:
	if not battle_manager:
		return

	# Show/update enemy displays based on active enemies
	for i in range(enemy_displays.size()):
		var display = enemy_displays[i]

		if i < battle_manager.enemies.size():
			var enemy = battle_manager.enemies[i]

			if display and display.has_method("update_display"):
				display.update_display(enemy)
				display.visible = not enemy.get("is_dead", false)
			elif display:
				display.visible = not enemy.get("is_dead", false)
		else:
			# No enemy for this slot, hide display
			if display:
				display.visible = false


## Update all UI displays (champions, enemies, counters)
func update_all_displays() -> void:
	update_champion_displays()
	update_enemy_displays()
	_update_deck_counters()
	_update_actions_label()
	_update_gold_label()


## Update deck and discard pile counters
func _update_deck_counters() -> void:
	if not battle_manager:
		return

	if deck_count_label:
		deck_count_label.text = "Deck: %d" % battle_manager.deck.size()

	if discard_count_label:
		discard_count_label.text = "Discard: %d" % battle_manager.discard_pile.size()


## Update actions remaining label
func _update_actions_label() -> void:
	if not battle_manager or not actions_label:
		return

	var max_actions = 3
	var remaining = battle_manager.actions_remaining

	actions_label.text = "Actions: %d/%d" % [remaining, max_actions]

	# Color code based on actions remaining
	if remaining == 0:
		actions_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	elif remaining <= 1:
		actions_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
	else:
		actions_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))


## Update gold label from GameManager
func _update_gold_label() -> void:
	if not game_manager or not gold_label:
		return

	if "player_gold" in game_manager:
		gold_label.text = "Gold: %d" % game_manager.player_gold


## Called when End Turn button is pressed
func _on_end_turn_button_pressed() -> void:
	print("BattleScene: End Turn button pressed")

	if battle_manager and battle_manager.current_phase == "player_turn":
		battle_manager.end_player_turn()


## Called when player requests to play a card
func _on_card_play_requested(card_id: String, champion_index: int, target_indices: Array[int]) -> void:
	print("BattleScene: Card play requested - %s by champion %d" % [card_id, champion_index])

	if not battle_manager:
		return

	# Attempt to play the card
	var success = battle_manager.play_card(card_id, champion_index, target_indices)

	if success:
		# Update displays after successful card play
		update_all_displays()
	else:
		print("BattleScene: Failed to play card %s" % card_id)


## Show the victory or defeat screen with results
func _show_victory_defeat_screen(victory: bool) -> void:
	if not victory_defeat_screen:
		push_error("Victory/Defeat screen not found")
		return

	# Calculate rewards
	var rewards = battle_manager.calculate_rewards()

	# Update result label
	if result_label:
		if victory:
			result_label.text = "VICTORY!"
			result_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2))
		else:
			result_label.text = "DEFEAT"
			result_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))

	# Update rewards label
	if rewards_label:
		if victory:
			var rewards_text = "Rewards:\n"
			rewards_text += "XP: +%d\n" % rewards.get("xp", 0)
			rewards_text += "Gold: +%d\n" % rewards.get("gold", 0)

			if rewards.get("unlocked_champion", "") != "":
				rewards_text += "\nNew Champion Unlocked: %s" % rewards.unlocked_champion

			rewards_label.text = rewards_text
		else:
			rewards_label.text = "No rewards"

	# Show the screen
	victory_defeat_screen.show()

	# Apply rewards to GameManager
	if victory and game_manager and game_manager.has_method("end_battle"):
		game_manager.end_battle(true, rewards)


## Called when Continue button is pressed on victory/defeat screen
func _on_continue_button_pressed() -> void:
	print("BattleScene: Continue button pressed")

	# Return to map or main menu
	# TODO: Change to appropriate scene (map, main menu, etc.)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


## Helper function to get entity name for logging
func _get_entity_name(entity) -> String:
	if entity is Champion:
		return entity.champion_name
	elif entity is Dictionary:
		return entity.get("name", "Unknown")
	else:
		return "Unknown"
