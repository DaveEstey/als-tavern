extends GutTest
## Unit tests for PartyManager - Champion progression and party management

var party_manager: Node


func before_each():
	"""Setup before each test - create fresh PartyManager instance"""
	# Get the autoloaded PartyManager
	party_manager = get_node("/root/PartyManager")
	# Reset to clean state
	party_manager.reset_party()


func after_each():
	"""Cleanup after each test"""
	# Reset back to default state
	party_manager.reset_party()


# ============================================================================
# PARTY COMPOSITION TESTS
# ============================================================================

func test_default_party_has_3_champions():
	"""Test that default party contains exactly 3 champions"""
	var party = party_manager.get_active_party()
	assert_eq(party.size(), 3, "Default party should have 3 champions")


func test_default_party_composition():
	"""Test that default party is warrior, defender, healer"""
	var party = party_manager.get_active_party()
	assert_eq(party[0], "warrior", "First champion should be warrior")
	assert_eq(party[1], "defender", "Second champion should be defender")
	assert_eq(party[2], "healer", "Third champion should be healer")


func test_set_active_party_with_valid_party():
	"""Test setting a valid 3-champion party"""
	party_manager.set_active_party(["healer", "warrior", "defender"])
	var party = party_manager.get_active_party()

	assert_eq(party.size(), 3, "Party should have 3 champions")
	assert_eq(party[0], "healer", "First champion should be healer")
	assert_eq(party[1], "warrior", "Second champion should be warrior")
	assert_eq(party[2], "defender", "Third champion should be defender")


func test_set_active_party_rejects_wrong_size():
	"""Test that setting party with wrong size fails (doesn't change party)"""
	var original_party = party_manager.get_active_party().duplicate()

	# Disable error checking - we EXPECT push_error to be called for validation
	gut.logger.disable_errors()

	# Try to set party with 2 champions (should fail and log error)
	party_manager.set_active_party(["warrior", "healer"])

	# Re-enable error checking
	gut.logger.enable_errors()

	var party_after = party_manager.get_active_party()
	assert_eq(party_after, original_party, "Party should not change when invalid size given")


# ============================================================================
# DECK BUILDING TESTS
# ============================================================================

func test_get_party_deck_returns_15_cards():
	"""Test that party deck contains exactly 15 cards (3 champions × 5 cards)"""
	var deck = party_manager.get_party_deck()
	assert_eq(deck.size(), 15, "Party deck should have 15 cards (3 champions × 5 cards)")


func test_get_party_deck_combines_all_champions():
	"""Test that deck includes cards from all 3 champions"""
	var deck = party_manager.get_party_deck()

	# Each champion should have 5 cards in the deck
	var warrior_progress = party_manager.get_champion_progress("warrior")
	var defender_progress = party_manager.get_champion_progress("defender")
	var healer_progress = party_manager.get_champion_progress("healer")

	assert_eq(warrior_progress["selected_cards"].size(), 5, "Warrior should have 5 selected cards")
	assert_eq(defender_progress["selected_cards"].size(), 5, "Defender should have 5 selected cards")
	assert_eq(healer_progress["selected_cards"].size(), 5, "Healer should have 5 selected cards")


func test_set_selected_cards_with_5_cards():
	"""Test setting valid 5-card deck for a champion"""
	var card_ids = ["strike", "defend", "reckless_assault", "battle_cry", "power_strike"]
	party_manager.set_selected_cards("warrior", card_ids)

	var progress = party_manager.get_champion_progress("warrior")
	assert_eq(progress["selected_cards"].size(), 5, "Should have 5 selected cards")


func test_set_selected_cards_rejects_wrong_count():
	"""Test that setting wrong number of cards doesn't change selection"""
	var original_cards = party_manager.get_champion_progress("warrior")["selected_cards"].duplicate()

	# Disable error checking - we EXPECT push_error to be called for validation
	gut.logger.disable_errors()

	# Try to set 3 cards (should fail and log error - needs exactly 5)
	party_manager.set_selected_cards("warrior", ["strike", "defend", "reckless_assault"])

	# Re-enable error checking
	gut.logger.enable_errors()

	var cards_after = party_manager.get_champion_progress("warrior")["selected_cards"]
	assert_eq(cards_after, original_cards, "Selected cards should not change when invalid count given")


# ============================================================================
# XP AND LEVELING TESTS
# ============================================================================

func test_champion_starts_at_level_1():
	"""Test that champions start at level 1"""
	var progress = party_manager.get_champion_progress("warrior")
	assert_eq(progress["level"], 1, "Champion should start at level 1")
	assert_eq(progress["current_xp"], 0, "Champion should start with 0 XP")


func test_add_xp_increases_xp():
	"""Test that adding XP increases current_xp"""
	party_manager.add_xp("warrior", 50)

	var progress = party_manager.get_champion_progress("warrior")
	assert_eq(progress["current_xp"], 50, "XP should increase by 50")
	assert_eq(progress["level"], 1, "Should not level up with only 50 XP")


func test_add_xp_levels_up_at_100():
	"""Test that 100 XP triggers level up"""
	party_manager.add_xp("warrior", 100)

	var progress = party_manager.get_champion_progress("warrior")
	assert_eq(progress["level"], 2, "Should level up to 2 at 100 XP")
	assert_eq(progress["current_xp"], 0, "XP should reset to 0 after level up")


func test_add_xp_multiple_levels():
	"""Test that adding lots of XP triggers multiple level ups"""
	# Level 1→2 needs 100 XP, Level 2→3 needs 200 XP, Level 3→4 needs 300 XP
	# Total for 3 levels: 100 + 200 + 300 = 600 XP
	# Give 650 XP → should level up 3 times with 50 XP left over
	party_manager.add_xp("warrior", 650)

	var progress = party_manager.get_champion_progress("warrior")
	assert_eq(progress["level"], 4, "Should level up to 4")
	assert_eq(progress["current_xp"], 50, "Should have 50 XP remaining")


func test_level_up_increases_stats():
	"""Test that leveling up increases champion stats"""
	var progress_before = party_manager.get_champion_progress("warrior")
	var hp_before = progress_before["max_hp"]
	var damage_before = progress_before["damage"]
	var defense_before = progress_before["defense"]

	# Level up
	party_manager.add_xp("warrior", 100)

	var progress_after = party_manager.get_champion_progress("warrior")
	assert_gt(progress_after["max_hp"], hp_before, "Max HP should increase on level up")
	assert_gt(progress_after["damage"], damage_before, "Damage should increase on level up")
	assert_gt(progress_after["defense"], defense_before, "Defense should increase on level up")


func test_level_up_heals_champion():
	"""Test that leveling up heals the champion"""
	# Damage the warrior first
	party_manager.damage_champion("warrior", 10)
	var hp_after_damage = party_manager.get_champion_progress("warrior")["current_hp"]

	# Level up
	party_manager.add_xp("warrior", 100)

	var progress = party_manager.get_champion_progress("warrior")
	assert_gt(progress["current_hp"], hp_after_damage, "Current HP should increase on level up (healing)")


func test_add_xp_to_party_affects_all_champions():
	"""Test that add_xp_to_party gives XP to all 3 active champions"""
	party_manager.add_xp_to_party(100)

	var warrior = party_manager.get_champion_progress("warrior")
	var defender = party_manager.get_champion_progress("defender")
	var healer = party_manager.get_champion_progress("healer")

	assert_eq(warrior["level"], 2, "Warrior should level up")
	assert_eq(defender["level"], 2, "Defender should level up")
	assert_eq(healer["level"], 2, "Healer should level up")


# ============================================================================
# HP MANAGEMENT TESTS
# ============================================================================

func test_heal_champion_restores_hp():
	"""Test that healing restores HP"""
	# Damage first
	party_manager.damage_champion("warrior", 10)
	var hp_after_damage = party_manager.get_champion_progress("warrior")["current_hp"]

	# Heal
	party_manager.heal_champion("warrior", 5)

	var hp_after_heal = party_manager.get_champion_progress("warrior")["current_hp"]
	assert_eq(hp_after_heal, hp_after_damage + 5, "HP should increase by 5")


func test_heal_champion_cannot_exceed_max_hp():
	"""Test that healing cannot exceed max HP"""
	var progress = party_manager.get_champion_progress("warrior")
	var max_hp = progress["max_hp"]

	# Heal by a huge amount
	party_manager.heal_champion("warrior", 9999)

	var hp_after = party_manager.get_champion_progress("warrior")["current_hp"]
	assert_eq(hp_after, max_hp, "HP should not exceed max HP")


func test_damage_champion_reduces_hp():
	"""Test that damaging reduces HP"""
	var hp_before = party_manager.get_champion_progress("warrior")["current_hp"]

	party_manager.damage_champion("warrior", 10)

	var hp_after = party_manager.get_champion_progress("warrior")["current_hp"]
	assert_eq(hp_after, hp_before - 10, "HP should decrease by 10")


func test_damage_champion_cannot_go_below_zero():
	"""Test that damage cannot reduce HP below 0"""
	party_manager.damage_champion("warrior", 9999)

	var hp_after = party_manager.get_champion_progress("warrior")["current_hp"]
	assert_eq(hp_after, 0, "HP should not go below 0")


func test_heal_party_full_restores_all_champions():
	"""Test that heal_party_full restores all champions to max HP"""
	# Damage all champions
	party_manager.damage_champion("warrior", 10)
	party_manager.damage_champion("defender", 15)
	party_manager.damage_champion("healer", 5)

	# Full heal
	party_manager.heal_party_full()

	var warrior = party_manager.get_champion_progress("warrior")
	var defender = party_manager.get_champion_progress("defender")
	var healer = party_manager.get_champion_progress("healer")

	assert_eq(warrior["current_hp"], warrior["max_hp"], "Warrior should be at max HP")
	assert_eq(defender["current_hp"], defender["max_hp"], "Defender should be at max HP")
	assert_eq(healer["current_hp"], healer["max_hp"], "Healer should be at max HP")


# ============================================================================
# CARD UNLOCKING TESTS
# ============================================================================

func test_unlock_card_adds_to_unlocked_cards():
	"""Test that unlocking a card adds it to unlocked_cards array"""
	var progress_before = party_manager.get_champion_progress("warrior")
	var unlocked_count_before = progress_before["unlocked_cards"].size()

	# Unlock a new card
	party_manager.unlock_card("warrior", "new_card_id")

	var progress_after = party_manager.get_champion_progress("warrior")
	assert_eq(progress_after["unlocked_cards"].size(), unlocked_count_before + 1,
		"Unlocked cards should increase by 1")
	assert_has(progress_after["unlocked_cards"], "new_card_id",
		"new_card_id should be in unlocked cards")


func test_unlock_card_does_not_duplicate():
	"""Test that unlocking the same card twice doesn't duplicate it"""
	party_manager.unlock_card("warrior", "duplicate_test")
	party_manager.unlock_card("warrior", "duplicate_test")

	var progress = party_manager.get_champion_progress("warrior")
	var count = 0
	for card in progress["unlocked_cards"]:
		if card == "duplicate_test":
			count += 1

	assert_eq(count, 1, "duplicate_test should only appear once in unlocked cards")
