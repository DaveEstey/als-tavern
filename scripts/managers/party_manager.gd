extends Node
# PartyManager - Manages active party and champion progression

signal party_changed
signal champion_leveled_up(champion_id: String, new_level: int)

# Active party (3 champion IDs)
var active_party: Array = ["warrior", "defender", "healer"]

# Champion progression data {champion_id: {level, current_xp, hp, damage, defense, unlocked_cards}}
var champion_progress: Dictionary = {}

func _ready():
	initialize_champions()

func initialize_champions():
	"""Initialize all champions with starting data"""
	for champ_id in CardDatabase.champions_data.keys():
		if not champion_progress.has(champ_id):
			var champ_data = CardDatabase.get_champion_data(champ_id)
			champion_progress[champ_id] = {
				"level": 1,
				"current_xp": 0,
				"current_hp": champ_data.get("starting_hp", 30),
				"max_hp": champ_data.get("starting_hp", 30),
				"damage": champ_data.get("starting_damage", 5),
				"defense": champ_data.get("starting_defense", 5),
				"unlocked_cards": champ_data.get("core_cards", []).duplicate(),
				"selected_cards": champ_data.get("core_cards", []).duplicate()
			}

func set_active_party(champion_ids: Array):
	"""Set the active party (3 champions)"""
	if champion_ids.size() != 3:
		push_error("Party must have exactly 3 champions")
		return

	active_party = champion_ids.duplicate()
	party_changed.emit()
	print("Active party: ", active_party)

func get_active_party() -> Array:
	"""Get current active party"""
	return active_party

func get_party_deck() -> Array:
	"""Get combined deck of all active party members (15 cards)"""
	var deck = []
	for champ_id in active_party:
		var selected_cards = champion_progress[champ_id].get("selected_cards", [])
		deck.append_array(selected_cards)
	return deck

func get_champion_progress(champion_id: String) -> Dictionary:
	"""Get progress data for a champion"""
	return champion_progress.get(champion_id, {})

func get_champion_data(champion_id: String) -> Dictionary:
	"""Get full champion data including base data and progress"""
	var progress = champion_progress.get(champion_id, {})
	if progress.is_empty():
		return {}

	var base_data = CardDatabase.get_champion_data(champion_id)
	if base_data.is_empty():
		return {}

	# Combine base data with progress data
	return {
		"id": champion_id,
		"name": base_data.get("name", "Unknown"),
		"level": progress.get("level", 1),
		"current_hp": progress.get("current_hp", 30),
		"max_hp": progress.get("max_hp", 30),
		"damage": progress.get("damage", 5),
		"defense": progress.get("defense", 5),
		"unlocked_cards": progress.get("unlocked_cards", []),
		"selected_cards": progress.get("selected_cards", [])
	}

func add_xp_to_party(xp_amount: int):
	"""Add XP to all active party members"""
	for champ_id in active_party:
		add_xp(champ_id, xp_amount)

func add_xp(champion_id: String, xp_amount: int):
	"""Add XP to a champion and check for level up"""
	if not champion_progress.has(champion_id):
		return

	var progress = champion_progress[champion_id]
	progress["current_xp"] += xp_amount

	# Check for level up (simple formula: 100 XP per level)
	var xp_needed = progress["level"] * 100
	while progress["current_xp"] >= xp_needed:
		progress["current_xp"] -= xp_needed
		level_up(champion_id)
		xp_needed = progress["level"] * 100

func level_up(champion_id: String):
	"""Level up a champion"""
	if not champion_progress.has(champion_id):
		return

	var progress = champion_progress[champion_id]
	var champ_data = CardDatabase.get_champion_data(champion_id)

	progress["level"] += 1

	# Increase stats
	var hp_gain = champ_data.get("hp_per_level", 5)
	var dmg_gain = champ_data.get("damage_per_level", 1)
	var def_gain = champ_data.get("defense_per_level", 1)

	progress["max_hp"] += hp_gain
	progress["current_hp"] += hp_gain  # Heal on level up
	progress["damage"] += dmg_gain
	progress["defense"] += def_gain

	champion_leveled_up.emit(champion_id, progress["level"])
	print(champion_id, " leveled up to ", progress["level"])

func heal_champion(champion_id: String, amount: int):
	"""Heal a champion"""
	if not champion_progress.has(champion_id):
		return

	var progress = champion_progress[champion_id]
	progress["current_hp"] = min(progress["current_hp"] + amount, progress["max_hp"])

func damage_champion(champion_id: String, amount: int):
	"""Damage a champion"""
	if not champion_progress.has(champion_id):
		return

	var progress = champion_progress[champion_id]
	progress["current_hp"] = max(0, progress["current_hp"] - amount)

func heal_party_full():
	"""Fully heal all active party members"""
	for champ_id in active_party:
		var progress = champion_progress[champ_id]
		progress["current_hp"] = progress["max_hp"]

func unlock_card(champion_id: String, card_id: String):
	"""Unlock a card for a champion"""
	if not champion_progress.has(champion_id):
		return

	var progress = champion_progress[champion_id]
	if card_id not in progress["unlocked_cards"]:
		progress["unlocked_cards"].append(card_id)

func set_selected_cards(champion_id: String, card_ids: Array):
	"""Set the 5 selected cards for a champion"""
	if not champion_progress.has(champion_id):
		return

	if card_ids.size() != 5:
		push_error("Must select exactly 5 cards")
		return

	champion_progress[champion_id]["selected_cards"] = card_ids.duplicate()

func reset_party():
	"""Reset all champion progress"""
	champion_progress.clear()
	initialize_champions()
	active_party = ["warrior", "defender", "healer"]
	party_changed.emit()
