extends GutTest
## Unit tests for Champion damage calculations - Critical for game balance

var champion: Champion


func before_each():
	"""Setup before each test - create fresh Champion instance"""
	champion = Champion.new()
	# Initialize with test data
	champion.initialize({
		"id": "test_warrior",
		"name": "Test Warrior",
		"max_hp": 100,
		"current_hp": 100,
		"damage": 10,
		"defense": 10,
		"block": 0
	})


func after_each():
	"""Cleanup after each test"""
	champion.queue_free()
	champion = null


# ============================================================================
# BASIC DAMAGE TESTS
# ============================================================================

func test_take_damage_reduces_hp():
	"""Test that taking damage reduces HP by the correct amount"""
	champion.take_damage(20)

	assert_eq(champion.current_hp, 80, "HP should reduce from 100 to 80")


func test_take_damage_cannot_reduce_hp_below_zero():
	"""Test that damage cannot reduce HP below 0"""
	champion.take_damage(9999)

	assert_eq(champion.current_hp, 0, "HP should not go below 0")


func test_take_damage_sets_dead_when_hp_zero():
	"""Test that champion is marked dead when HP reaches 0"""
	champion.take_damage(100)

	assert_true(champion.is_dead, "Champion should be marked as dead")
	assert_eq(champion.current_hp, 0, "HP should be 0")


# ============================================================================
# DEFENSE REDUCTION TESTS
# ============================================================================

func test_defense_reduces_damage():
	"""Test that defense reduces incoming damage"""
	# Champion has defense = 10
	# Defense reduction: damage * (defense * 0.02) = damage * 0.2
	# 100 damage with 10 defense = 100 * 0.2 = 20 damage reduction
	# Final damage: 100 - 20 = 80

	champion.take_damage(100)

	assert_eq(champion.current_hp, 20, "Should take 80 damage (100 - 20% reduction)")


func test_defense_50_reduces_damage_by_100_percent():
	"""Test that 50 defense reduces damage by 100% (immune)"""
	# Defense reduction: damage * (defense * 0.02) = damage * 1.0 = full immunity
	champion.defense = 50

	champion.take_damage(100)

	assert_eq(champion.current_hp, 100, "Should take 0 damage with 50 defense")


func test_defense_25_reduces_damage_by_50_percent():
	"""Test that 25 defense reduces damage by 50%"""
	# Defense reduction: damage * (25 * 0.02) = damage * 0.5
	champion.defense = 25

	champion.take_damage(100)

	assert_eq(champion.current_hp, 50, "Should take 50 damage (100 - 50% reduction)")


func test_defense_0_no_reduction():
	"""Test that 0 defense means no damage reduction"""
	champion.defense = 0

	champion.take_damage(100)

	assert_eq(champion.current_hp, 0, "Should take full 100 damage with 0 defense")


# ============================================================================
# BLOCK TESTS
# ============================================================================

func test_block_absorbs_damage_fully():
	"""Test that block absorbs damage when block > damage"""
	champion.block = 50

	champion.take_damage(30)

	assert_eq(champion.current_hp, 100, "HP should remain at 100 (block absorbed all damage)")
	assert_eq(champion.block, 20, "Block should reduce from 50 to 20")


func test_block_absorbs_damage_partially():
	"""Test that block absorbs partially when damage > block"""
	champion.block = 30

	# Damage after defense: 100 - 20 = 80
	# Block absorbs: 30
	# Remaining damage to HP: 50
	champion.take_damage(100)

	assert_eq(champion.block, 0, "Block should be depleted")
	assert_eq(champion.current_hp, 50, "Should take 50 damage after block absorbed 30")


func test_block_with_zero_defense():
	"""Test block behavior with no defense"""
	champion.defense = 0
	champion.block = 40

	# No defense reduction, so 100 damage
	# Block absorbs 40, remaining 60 goes to HP
	champion.take_damage(100)

	assert_eq(champion.block, 0, "Block should be depleted")
	assert_eq(champion.current_hp, 40, "Should take 60 damage after block")


func test_block_exactly_equals_damage():
	"""Test edge case where block exactly equals incoming damage"""
	champion.block = 80  # After defense, 100 damage becomes 80

	champion.take_damage(100)

	assert_eq(champion.current_hp, 100, "HP should remain full")
	assert_eq(champion.block, 0, "Block should be fully depleted")


# ============================================================================
# HEALING TESTS
# ============================================================================

func test_heal_restores_hp():
	"""Test that healing restores HP"""
	champion.current_hp = 50

	champion.heal(30)

	assert_eq(champion.current_hp, 80, "HP should increase from 50 to 80")


func test_heal_cannot_exceed_max_hp():
	"""Test that healing cannot exceed max HP"""
	champion.current_hp = 90

	champion.heal(50)

	assert_eq(champion.current_hp, 100, "HP should cap at max HP (100)")


func test_heal_from_zero():
	"""Test healing from 0 HP"""
	champion.current_hp = 0

	champion.heal(30)

	assert_eq(champion.current_hp, 30, "Should heal from 0 to 30")


# ============================================================================
# BLOCK MANAGEMENT TESTS
# ============================================================================

func test_add_block():
	"""Test that add_block increases block value"""
	champion.add_block(20)

	assert_eq(champion.block, 20, "Block should increase to 20")


func test_add_block_stacks():
	"""Test that multiple add_block calls stack"""
	champion.add_block(10)
	champion.add_block(15)
	champion.add_block(5)

	assert_eq(champion.block, 30, "Block should stack to 30")


func test_reset_block():
	"""Test that reset_block clears all block"""
	champion.add_block(50)
	champion.reset_block()

	assert_eq(champion.block, 0, "Block should be reset to 0")


# ============================================================================
# EDGE CASES AND COMPLEX SCENARIOS
# ============================================================================

func test_multiple_attacks_with_block():
	"""Test multiple attacks depleting block over time"""
	champion.block = 100

	# First attack (100 damage - 20 defense = 80 damage)
	champion.take_damage(100)
	assert_eq(champion.block, 20, "Block should be 20 after first attack")
	assert_eq(champion.current_hp, 100, "HP should still be full")

	# Second attack (80 damage after defense, block has 20)
	# Block absorbs 20, 60 goes to HP
	champion.take_damage(100)
	assert_eq(champion.block, 0, "Block should be depleted")
	assert_eq(champion.current_hp, 40, "HP should be reduced by 60")


func test_damage_heal_damage_sequence():
	"""Test sequence of damage and healing"""
	# Take damage
	champion.take_damage(50)
	assert_eq(champion.current_hp, 60, "Should have 60 HP after first damage")

	# Heal
	champion.heal(20)
	assert_eq(champion.current_hp, 80, "Should have 80 HP after heal")

	# Take more damage
	champion.take_damage(30)
	assert_eq(champion.current_hp, 56, "Should have 56 HP after second damage")


func test_very_high_defense():
	"""Test behavior with defense > 50 (would be >100% reduction)"""
	# This is an edge case - defense values shouldn't go this high
	# but we should handle it gracefully
	champion.defense = 100

	champion.take_damage(100)

	# With defense formula, this would be negative damage
	# Should be capped at 0 damage taken
	assert_eq(champion.current_hp, 100, "Should take 0 damage with very high defense")


func test_dead_champion_state():
	"""Test that dead champion has correct state"""
	champion.take_damage(100)

	assert_true(champion.is_dead, "Should be marked as dead")
	assert_eq(champion.current_hp, 0, "Should have 0 HP")


func test_revive_from_death():
	"""Test revival mechanics (if implemented)"""
	# Kill the champion
	champion.take_damage(100)
	assert_true(champion.is_dead, "Should be dead")

	# Revive (set HP and clear death flag)
	champion.current_hp = 50
	champion.is_dead = false

	assert_false(champion.is_dead, "Should no longer be dead")
	assert_eq(champion.current_hp, 50, "Should have 50 HP after revival")
