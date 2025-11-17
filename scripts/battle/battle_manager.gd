class_name BattleManager
extends Node
## BattleManager - Core combat system controller for turn-based card battles

# Battle participants
var champions: Array[Champion] = []  # 3 champions from party
var enemies: Array[Dictionary] = []  # 1-3 enemy dictionaries {id, name, hp, max_hp, damage, defense, block, is_dead}

# Deck management
var deck: Array[String] = []  # 15 card IDs from party deck
var hand: Array[String] = []  # Current hand of 5 cards
var discard_pile: Array[String] = []

# Battle state
var current_phase: String = "player_turn"  # player_turn, enemy_turn, victory, defeat
var actions_remaining: int = 3  # 3 actions per turn, one per champion
var champions_acted: Array[int] = []  # Track which champion indices used their action this turn

# References
var card_database: Node
var party_manager: Node

# Signals
signal turn_started(phase: String)
signal card_drawn
signal card_played(card: Card, caster: Champion, targets: Array[Variant])
signal champion_acted(champion: Champion, action_type: String)
signal damage_dealt(source, target, amount: int)
signal champion_died(champion: Champion)
signal enemy_died(enemy: Dictionary)
signal battle_ended(victory: bool)


func _ready() -> void:
	# Get references to autoload managers
	if has_node("/root/CardDatabase"):
		card_database = get_node("/root/CardDatabase")
	else:
		push_error("CardDatabase not found. Make sure it's set up as an autoload.")

	if has_node("/root/PartyManager"):
		party_manager = get_node("/root/PartyManager")
	else:
		push_error("PartyManager not found. Make sure it's set up as an autoload.")


## Initialize battle with given enemy IDs
## Loads enemies, champions, builds deck and starts first turn
func initialize_battle(enemy_ids: Array[String]) -> void:
	# Clear previous battle state
	champions.clear()
	enemies.clear()
	deck.clear()
	hand.clear()
	discard_pile.clear()
	champions_acted.clear()

	# Load enemies from database
	_load_enemies(enemy_ids)

	# Load champions from party
	_load_champions()

	# Build deck from party
	_build_deck()

	# Shuffle deck
	shuffle_deck()

	# Set initial state
	current_phase = "player_turn"
	actions_remaining = 3

	# Start first player turn
	start_player_turn()


## Load enemies from CardDatabase
func _load_enemies(enemy_ids: Array[String]) -> void:
	if not card_database:
		push_error("Cannot load enemies: CardDatabase not available")
		return

	for enemy_id in enemy_ids:
		var enemy_data = card_database.get_enemy_data(enemy_id)
		if enemy_data.is_empty():
			push_error("Enemy data not found for ID: %s" % enemy_id)
			continue

		# Create enemy instance as dictionary
		var enemy = {
			"id": enemy_id,
			"name": enemy_data.get("name", "Unknown Enemy"),
			"max_hp": enemy_data.get("hp", 50),
			"current_hp": enemy_data.get("hp", 50),
			"damage": enemy_data.get("damage", 10),
			"defense": enemy_data.get("defense", 0),
			"block": 0,
			"is_dead": false,
			"attack_pattern": enemy_data.get("attack_pattern", "random"),  # random, weakest, strongest
			"skills": enemy_data.get("skills", [])  # Array of skill IDs
		}

		enemies.append(enemy)


## Load champions from PartyManager
func _load_champions() -> void:
	if not party_manager:
		push_error("Cannot load champions: PartyManager not available")
		return

	var party_ids = party_manager.get_active_party()
	if not party_ids:
		push_error("Failed to get active party from PartyManager")
		return

	for champ_id in party_ids:
		var champion = Champion.new()
		champion.initialize(champ_id)
		add_child(champion)  # Add to scene tree
		champions.append(champion)


## Build deck from party's selected cards (15 total)
func _build_deck() -> void:
	if not party_manager:
		push_error("Cannot build deck: PartyManager not available")
		return

	var party_deck = party_manager.get_party_deck()
	if not party_deck:
		push_error("Failed to get party deck from PartyManager")
		return

	# Ensure deck is properly typed
	deck.clear()
	for card_id in party_deck:
		if card_id is String:
			deck.append(card_id)

	print("Deck built with %d cards" % deck.size())


## Start player turn: Reset blocks, draw 5 cards, set actions_remaining = 3
func start_player_turn() -> void:
	current_phase = "player_turn"
	actions_remaining = 3
	champions_acted.clear()

	# Reset champion blocks
	for champion in champions:
		if not champion.is_ko:
			champion.reset_block()
			# Apply regeneration effects
			champion.apply_regen()
			# Update buff/debuff durations
			champion.update_effects()

	# Reset enemy blocks
	for enemy in enemies:
		if not enemy.get("is_dead", false):
			enemy["block"] = 0

	# Discard current hand
	discard_hand()

	# Draw 5 new cards
	draw_cards(5)

	turn_started.emit("player_turn")
	print("Player turn started - Actions remaining: %d" % actions_remaining)


## Play a card from hand
## Returns true if card was successfully played
func play_card(card_id: String, champion_index: int, target_indices: Array) -> bool:
	# Validate inputs
	if champion_index < 0 or champion_index >= champions.size():
		push_error("Invalid champion index: %d" % champion_index)
		return false

	if current_phase != "player_turn":
		push_error("Cannot play card outside of player turn")
		return false

	if actions_remaining <= 0:
		push_error("No actions remaining")
		return false

	var caster = champions[champion_index]

	# Check if champion is KO'd
	if caster.is_ko:
		push_error("Champion is knocked out")
		return false

	# Check if card is in hand
	if card_id not in hand:
		push_error("Card not in hand: %s" % card_id)
		return false

	# Create card instance and initialize
	var card = Card.new()
	card.initialize(card_id)

	# Validate card can be played
	if not card.can_be_played():
		push_error("Card cannot be played: %s" % card_id)
		return false

	# Get targets
	var targets = _get_targets(card, target_indices)
	if targets.is_empty() and card.target_type != "self":
		push_error("No valid targets for card")
		return false

	# Execute card effect
	var success = card.execute(caster, targets)

	if success:
		# Remove card from hand and add to discard
		hand.erase(card_id)
		discard_pile.append(card_id)

		# Mark champion as acted
		if champion_index not in champions_acted:
			champions_acted.append(champion_index)

		# Decrease actions remaining
		actions_remaining -= 1

		# Emit signals
		card_played.emit(card, caster, targets)
		champion_acted.emit(caster, "card")

		# Check for deaths
		_check_deaths()

		# Check victory/defeat
		if check_victory():
			_end_battle(true)
		elif check_defeat():
			_end_battle(false)

		print("Card played: %s by %s" % [card.card_name, caster.champion_name])
		return true

	return false


## Execute basic attack: Champion attacks enemy
func basic_attack(champion_index: int, enemy_index: int) -> bool:
	# Validate inputs
	if current_phase != "player_turn":
		push_error("Cannot attack outside of player turn")
		return false

	if actions_remaining <= 0:
		push_error("No actions remaining")
		return false

	if champion_index < 0 or champion_index >= champions.size():
		push_error("Invalid champion index: %d" % champion_index)
		return false

	if enemy_index < 0 or enemy_index >= enemies.size():
		push_error("Invalid enemy index: %d" % enemy_index)
		return false

	var champion = champions[champion_index]
	var enemy = enemies[enemy_index]

	# Check if champion is KO'd
	if champion.is_ko:
		push_error("Champion is knocked out")
		return false

	# Check if enemy is dead
	if enemy.is_dead:
		push_error("Enemy is already dead")
		return false

	# Calculate damage
	var base_damage = champion.damage
	var actual_damage = _deal_damage_to_enemy(enemy, base_damage)

	# Mark champion as acted
	if champion_index not in champions_acted:
		champions_acted.append(champion_index)

	# Decrease actions remaining
	actions_remaining -= 1

	# Emit signals
	damage_dealt.emit(champion, enemy, actual_damage)
	champion_acted.emit(champion, "attack")

	# Check for deaths
	_check_deaths()

	# Check victory/defeat
	if check_victory():
		_end_battle(true)
	elif check_defeat():
		_end_battle(false)

	print("%s attacked %s for %d damage" % [champion.champion_name, enemy.name, actual_damage])
	return true


## Execute basic defend: Champion gains block
func basic_defend(champion_index: int) -> bool:
	# Validate inputs
	if current_phase != "player_turn":
		push_error("Cannot defend outside of player turn")
		return false

	if actions_remaining <= 0:
		push_error("No actions remaining")
		return false

	if champion_index < 0 or champion_index >= champions.size():
		push_error("Invalid champion index: %d" % champion_index)
		return false

	var champion = champions[champion_index]

	# Check if champion is KO'd
	if champion.is_ko:
		push_error("Champion is knocked out")
		return false

	# Grant block (base 5 block for basic defend)
	var block_amount = 5 + champion.defense
	champion.add_block(block_amount)

	# Mark champion as acted
	if champion_index not in champions_acted:
		champions_acted.append(champion_index)

	# Decrease actions remaining
	actions_remaining -= 1

	# Emit signal
	champion_acted.emit(champion, "defend")

	print("%s defended and gained %d block" % [champion.champion_name, block_amount])
	return true


## End player turn and switch to enemy phase
func end_player_turn() -> void:
	if current_phase != "player_turn":
		return

	# Discard remaining hand cards
	discard_hand()

	# Switch to enemy turn
	current_phase = "enemy_turn"
	turn_started.emit("enemy_turn")

	print("Player turn ended")

	# Execute enemy turn
	execute_enemy_turn()


## Execute enemy turn: Each enemy chooses attack and executes on random champion
func execute_enemy_turn() -> void:
	if current_phase != "enemy_turn":
		return

	print("Enemy turn started")

	# Each alive enemy performs an action
	for enemy in enemies:
		if enemy.get("is_dead", false):
			continue

		# Choose target based on attack pattern
		var target = _choose_enemy_target(enemy)

		if not target:
			continue

		# Execute attack
		var damage_amount = enemy.get("damage", 0)
		var actual_damage = target.take_damage(damage_amount)

		# Emit signal
		damage_dealt.emit(enemy, target, actual_damage)

		print("%s attacked %s for %d damage" % [enemy.get("name", "Unknown"), target.champion_name, actual_damage])

	# Check for deaths
	_check_deaths()

	# Check defeat
	if check_defeat():
		_end_battle(false)
		return

	# End enemy turn and start new player turn
	current_phase = "player_turn"
	start_player_turn()


## Check if all enemies are dead (victory condition)
func check_victory() -> bool:
	for enemy in enemies:
		if not enemy.is_dead:
			return false
	return true


## Check if all champions are KO'd (defeat condition)
func check_defeat() -> bool:
	for champion in champions:
		if not champion.is_ko:
			return false
	return true


## Shuffle deck array using Fisher-Yates algorithm
func shuffle_deck() -> void:
	var n = deck.size()
	for i in range(n - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = deck[i]
		deck[i] = deck[j]
		deck[j] = temp

	print("Deck shuffled")


## Draw N cards from deck, reshuffle discard if needed
func draw_cards(count: int) -> void:
	for i in range(count):
		# If deck is empty, reshuffle discard pile into deck
		if deck.is_empty():
			if discard_pile.is_empty():
				print("No cards left to draw")
				break

			deck = discard_pile.duplicate()
			discard_pile.clear()
			shuffle_deck()

		# Draw card from top of deck
		var card_id = deck.pop_front()
		hand.append(card_id)
		card_drawn.emit()

	print("Drew %d cards - Hand size: %d" % [count, hand.size()])


## Move all hand cards to discard pile
func discard_hand() -> void:
	discard_pile.append_array(hand)
	hand.clear()


## Calculate rewards after victory
## Returns {xp, gold, unlocked_champion}
func calculate_rewards() -> Dictionary:
	if current_phase != "victory":
		return {}

	var rewards = {
		"xp": 0,
		"gold": 0,
		"unlocked_champion": ""
	}

	# Calculate XP based on enemies defeated
	for enemy in enemies:
		# Base XP per enemy (could be stored in enemy data)
		rewards.xp += 50

	# Calculate gold (random range based on enemy count)
	rewards.gold = randi_range(20, 50) * enemies.size()

	# Check if a new champion is unlocked (placeholder logic)
	# This could be based on story progression or specific battles
	if randf() < 0.1:  # 10% chance for now
		var locked_champions = ["fire_knight"]  # Example
		if not locked_champions.is_empty():
			rewards.unlocked_champion = locked_champions[0]

	return rewards


## Get targets based on card target type and indices
## Returns Array[Variant] since targets can be Champion or Dictionary (enemy)
func _get_targets(card: Card, target_indices: Array[int]) -> Array[Variant]:
	var targets: Array[Variant] = []

	match card.target_type:
		"self":
			# Target is the caster (will be added by caller)
			return []

		"single_enemy":
			if target_indices.is_empty():
				return []
			var enemy_index = target_indices[0]
			if enemy_index >= 0 and enemy_index < enemies.size():
				if not enemies[enemy_index].get("is_dead", false):
					targets.append(enemies[enemy_index])

		"all_enemies":
			for enemy in enemies:
				if not enemy.get("is_dead", false):
					targets.append(enemy)

		"single_ally":
			if target_indices.is_empty():
				return []
			var champ_index = target_indices[0]
			if champ_index >= 0 and champ_index < champions.size():
				if not champions[champ_index].is_ko:
					targets.append(champions[champ_index])

		"all_allies":
			for champion in champions:
				if not champion.is_ko:
					targets.append(champion)

		"dead_ally":
			if target_indices.is_empty():
				return []
			var champ_index = target_indices[0]
			if champ_index >= 0 and champ_index < champions.size():
				if champions[champ_index].is_ko:
					targets.append(champions[champ_index])

	return targets


## Choose target for enemy attack based on attack pattern
func _choose_enemy_target(enemy: Dictionary) -> Champion:
	var alive_champions = []

	# Get all alive champions
	for champion in champions:
		if not champion.is_ko:
			alive_champions.append(champion)

	if alive_champions.is_empty():
		return null

	# Choose based on attack pattern
	match enemy.attack_pattern:
		"random":
			return alive_champions[randi() % alive_champions.size()]

		"weakest":
			# Target champion with lowest HP
			var weakest = alive_champions[0]
			for champion in alive_champions:
				if champion.current_hp < weakest.current_hp:
					weakest = champion
			return weakest

		"strongest":
			# Target champion with highest HP
			var strongest = alive_champions[0]
			for champion in alive_champions:
				if champion.current_hp > strongest.current_hp:
					strongest = champion
			return strongest

		_:
			# Default to random
			return alive_champions[randi() % alive_champions.size()]


## Deal damage to enemy and apply defense/block
## Returns actual damage dealt
func _deal_damage_to_enemy(enemy: Dictionary, amount: int) -> int:
	var total_damage = amount

	# Apply defense reduction (same formula as Champion)
	var defense_reduction = int(total_damage * (float(enemy.defense) * 0.02))
	total_damage = max(1, total_damage - defense_reduction)

	# Apply block first
	if enemy.block > 0:
		if total_damage <= enemy.block:
			enemy.block -= total_damage
			return 0  # Damage fully blocked
		else:
			total_damage -= enemy.block
			enemy.block = 0

	# Apply damage to HP
	var actual_damage = min(total_damage, enemy.current_hp)
	enemy.current_hp -= actual_damage

	# Check for death
	if enemy.current_hp <= 0:
		enemy.current_hp = 0
		enemy.is_dead = true

	return actual_damage


## Check for champion and enemy deaths
func _check_deaths() -> void:
	# Check champion deaths
	for champion in champions:
		if champion.current_hp <= 0 and not champion.is_ko:
			champion.is_ko = true
			champion_died.emit(champion)
			print("%s was knocked out!" % champion.champion_name)

	# Check enemy deaths
	for enemy in enemies:
		if enemy.get("current_hp", 0) <= 0 and not enemy.get("is_dead", false):
			enemy["is_dead"] = true
			enemy_died.emit(enemy)
			print("%s was defeated!" % enemy.get("name", "Unknown"))


## End battle with victory or defeat
func _end_battle(victory: bool) -> void:
	if victory:
		current_phase = "victory"
		print("Victory! All enemies defeated!")
	else:
		current_phase = "defeat"
		print("Defeat! All champions knocked out!")

	battle_ended.emit(victory)
