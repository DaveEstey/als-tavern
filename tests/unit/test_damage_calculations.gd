extends GutTest
## Unit tests for Champion damage calculations - Critical for game balance

var champion: Champion


func before_each():
	"""Setup before each test - create fresh Champion instance"""
	champion = autofree(Champion.new())

	# Don't call initialize() - it tries to access the scene tree
	# Instead, manually set all properties for isolated unit testing
	champion.champion_id = "warrior"
	champion.champion_name = "Test Warrior"
	champion.max_hp = 100
	champion.current_hp = 100
	champion.damage = 10
	champion.defense = 10
	champion.block = 0
	champion.is_ko = false
	champion.level = 1
	champion.regen_stacks = []
	champion.buffs = []
	champion.debuffs = []


func after_each():
	"""Cleanup after each test"""
	# Champion is auto-freed by GUT's autofree()
	champion = null


# ============================================================================
# BASIC DAMAGE TESTS
# ============================================================================

func test_take_damage_reduces_hp():
	"""Test that taking damage reduces HP by the correct amount"""
	# With defense=10, 20 damage becomes 20 - (20 * 0.2) = 20 - 4 = 16 damage
	# But minimum damage is 1, so it calculates: max(1, 20 - 4) = 16
	var damage_dealt = champion.take_damage(20)

	assert_eq(champion.current_hp, 84, "HP should reduce from 100 to 84 (20 damage - 20% defense = 16)")


func test_take_damage_cannot_reduce_hp_below_zero():
	"""Test that damage cannot reduce HP below 0"""
	champion.take_damage(9999)

	assert_eq(champion.current_hp, 0, "HP should not go below 0")


func test_take_damage_sets_ko_when_hp_zero():
	"""Test that champion is marked as KO when HP reaches 0"""
	champion.take_damage(9999)

	assert_true(champion.is_ko, "Champion should be marked as KO")
	assert_eq(champion.current_hp, 0, "HP should be 0")


# ============================================================================
# DEFENSE REDUCTION TESTS
# ============================================================================

func test_defense_reduces_damage():
	"""Test that defense reduces incoming damage"""
	# Champion has defense = 10
	# Defense reduction: damage * (defense * 0.02) = 100 * 0.2 = 20
	# Final damage: max(1, 100 - 20) = 80

	champion.take_damage(100)

	assert_eq(champion.current_hp, 20, "Should take 80 damage (100 - 20% reduction)")


func test_defense_50_reduces_damage_by_100_percent():
	"""Test that 50 defense reduces damage by 100% (immune)"""
	# Defense reduction: damage * (defense * 0.02) = 100 * 1.0 = 100
	# Final damage: max(1, 100 - 100) = 1 (minimum damage)
	champion.defense = 50

	champion.take_damage(100)

	# Note: The implementation ensures minimum 1 damage, so it's not full immunity
	assert_eq(champion.current_hp, 99, "Should take 1 damage minimum (even with 50 defense)")


func test_defense_25_reduces_damage_by_50_percent():
	"""Test that 25 defense reduces damage by 50%"""
	# Defense reduction: 100 * (25 * 0.02) = 100 * 0.5 = 50
	# Final damage: max(1, 100 - 50) = 50
	champion.defense = 25

	champion.take_damage(100)

	assert_eq(champion.current_hp, 50, "Should take 50 damage (100 - 50% reduction)")


func test_defense_0_no_reduction():
	"""Test that 0 defense means no damage reduction"""
	champion.defense = 0

	champion.take_damage(100)

	# With 0 defense, still has minimum 1 damage rule: max(1, 100 - 0) = 100
	assert_eq(champion.current_hp, 0, "Should take full 100 damage with 0 defense")


# ============================================================================
# BLOCK TESTS
# ============================================================================

func test_block_absorbs_damage_fully():
	"""Test that block absorbs damage when block > damage"""
	champion.defense = 0  # Disable defense for clearer testing
	champion.block = 50

	champion.take_damage(30)

	assert_eq(champion.current_hp, 100, "HP should remain at 100 (block absorbed all damage)")
	assert_eq(champion.block, 20, "Block should reduce from 50 to 20")


func test_block_absorbs_damage_partially():
	"""Test that block absorbs partially when damage > block"""
	champion.defense = 0  # Disable defense for clearer testing
	champion.block = 30

	# 100 damage, block absorbs 30, remaining 70 goes to HP
	champion.take_damage(100)

	assert_eq(champion.block, 0, "Block should be depleted")
	assert_eq(champion.current_hp, 30, "Should take 70 damage after block absorbed 30")


func test_block_with_defense():
	"""Test block behavior with defense reduction"""
	# Defense = 10 (20% reduction)
	# 100 damage - 20% = 80 damage after defense
	# Block = 40
	# Block absorbs 40, remaining 40 goes to HP
	champion.defense = 10
	champion.block = 40

	champion.take_damage(100)

	assert_eq(champion.block, 0, "Block should be depleted")
	assert_eq(champion.current_hp, 60, "Should take 40 damage after defense and block")


func test_block_exactly_equals_damage():
	"""Test edge case where block exactly equals incoming damage"""
	champion.defense = 10  # 100 damage becomes 80 after 20% reduction
	champion.block = 80

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


func test_heal_from_low_hp():
	"""Test healing from low HP"""
	champion.current_hp = 10

	champion.heal(30)

	assert_eq(champion.current_hp, 40, "Should heal from 10 to 40")


func test_heal_does_not_work_on_ko():
	"""Test that healing doesn't work on KO'd champions"""
	champion.current_hp = 0
	champion.is_ko = true

	champion.heal(50)

	assert_eq(champion.current_hp, 0, "KO'd champion should not heal")
	assert_true(champion.is_ko, "Should still be KO'd")


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
	champion.defense = 10  # 20% reduction
	champion.block = 100

	# First attack: 100 damage - 20% = 80 damage, block absorbs
	champion.take_damage(100)
	assert_eq(champion.block, 20, "Block should be 20 after first attack")
	assert_eq(champion.current_hp, 100, "HP should still be full")

	# Second attack: 80 damage, block has 20
	# Block absorbs 20, 60 goes to HP
	champion.take_damage(100)
	assert_eq(champion.block, 0, "Block should be depleted")
	assert_eq(champion.current_hp, 40, "HP should be reduced by 60")


func test_damage_heal_damage_sequence():
	"""Test sequence of damage and healing"""
	champion.defense = 0  # Simplify for testing

	# Take damage
	champion.take_damage(40)
	assert_eq(champion.current_hp, 60, "Should have 60 HP after first damage")

	# Heal
	champion.heal(20)
	assert_eq(champion.current_hp, 80, "Should have 80 HP after heal")

	# Take more damage
	champion.take_damage(30)
	assert_eq(champion.current_hp, 50, "Should have 50 HP after second damage")


func test_very_high_defense():
	"""Test behavior with defense > 50 (would be >100% reduction)"""
	champion.defense = 100

	champion.take_damage(100)

	# With very high defense, minimum damage is still 1
	assert_eq(champion.current_hp, 99, "Should take minimum 1 damage with very high defense")


func test_ko_champion_state():
	"""Test that KO'd champion has correct state"""
	champion.defense = 0  # Remove defense for clearer test
	champion.take_damage(100)

	assert_true(champion.is_ko, "Should be marked as KO")
	assert_eq(champion.current_hp, 0, "Should have 0 HP")


func test_revive_from_ko():
	"""Test revival mechanics"""
	# Kill the champion (disable defense for clearer test)
	champion.defense = 0
	champion.take_damage(100)
	assert_true(champion.is_ko, "Should be KO'd")

	# Revive with 50 HP
	champion.revive(50)

	assert_false(champion.is_ko, "Should no longer be KO'd")
	assert_eq(champion.current_hp, 50, "Should have 50 HP after revival")


func test_revive_cannot_exceed_max_hp():
	"""Test that revival respects max HP"""
	champion.defense = 0  # Remove defense for clearer test
	champion.take_damage(100)

	champion.revive(150)  # Try to revive with more than max HP

	assert_eq(champion.current_hp, 100, "Revival HP should cap at max HP")
	assert_false(champion.is_ko, "Should be revived")
