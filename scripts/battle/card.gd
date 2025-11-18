class_name Card
extends Control
## Card class - Represents a playable card with effects and targeting

# Card data properties
var card_id: String = ""
var card_name: String = ""
var champion_owner: String = ""  # Champion ID (warrior, defender, healer, fire_knight)
var card_type: String = ""  # attack, skill
var cost: int = 1  # Action cost (typically 1)
var target_type: String = ""  # single_enemy, all_enemies, single_ally, all_allies, self, dead_ally
var effect_type: String = ""  # damage, heal, block, etc.
var description: String = ""

# Effect values - May contain multiple values depending on effect_type
var value: int = 0  # Primary effect value (damage, heal, block, etc.)
var value2: int = 0  # Secondary effect value (for combined effects)
var value3: int = 0  # Tertiary effect value (for complex effects)
var bonus_value: int = 0  # Bonus value for conditional effects
var self_damage: int = 0  # Damage to caster (for effects like Berserker Rage)
var damage_value: int = 0  # For damage_and_block, damage_and_heal effects
var block_value: int = 0  # For block_and_buff effects
var thorns_value: int = 0  # Counter damage for block_and_thorns
var buff_value: int = 0  # Buff amount for block_and_buff
var burn_value: int = 0  # Burn damage per turn
var heal_value: int = 0  # For damage_and_heal effects
var duration: int = 0  # Duration for regen, burn, buffs, debuffs
var condition: String = ""  # Condition for conditional_damage (hp_below_50_percent)

# Visual properties
var background_color: Color = Color.WHITE
var champion_color: Dictionary = {
	"warrior": Color(1.0, 0.2, 0.2),      # Red
	"defender": Color(0.2, 0.4, 1.0),    # Blue
	"healer": Color(0.2, 1.0, 0.2),      # Green
	"fire_knight": Color(1.0, 0.6, 0.2)  # Orange
}

# References
var card_database: Node


func _ready() -> void:
	## Initialize card database reference
	card_database = get_tree().root.get_child(0).get_node_or_null("CardDatabase")
	if not card_database:
		push_error("CardDatabase not found. Make sure it's set up as an autoload.")


func initialize(id: String) -> void:
	## Load card data from CardDatabase
	self.card_id = id

	if not card_database:
		push_error("CardDatabase not available for card initialization")
		return

	# Get card data from database
	var card_data: Dictionary = card_database.get_card_data(id)
	if card_data.is_empty():
		push_error("Card data not found for ID: %s" % id)
		return

	# Load basic properties
	card_name = card_data.get("name", "Unknown Card")
	champion_owner = card_data.get("champion", "")
	card_type = card_data.get("type", "skill")
	cost = card_data.get("cost", 1)
	target_type = card_data.get("target_type", "single_enemy")
	effect_type = card_data.get("effect_type", "damage")
	description = card_data.get("description", "")

	# Load effect values
	value = card_data.get("value", 0)
	value2 = card_data.get("value2", 0)
	value3 = card_data.get("value3", 0)
	bonus_value = card_data.get("bonus_value", 0)
	self_damage = card_data.get("self_damage", 0)
	damage_value = card_data.get("damage_value", 0)
	block_value = card_data.get("block_value", 0)
	thorns_value = card_data.get("thorns_value", 0)
	buff_value = card_data.get("buff_value", 0)
	burn_value = card_data.get("burn_value", 0)
	heal_value = card_data.get("heal_value", 0)
	duration = card_data.get("duration", 0)
	condition = card_data.get("condition", "")

	# Set visual color based on champion
	_set_background_color()


func _set_background_color() -> void:
	## Set background color based on champion owner
	background_color = champion_color.get(champion_owner, Color.WHITE)


func can_be_played() -> bool:
	## Check if card can be played (basic validation)
	## Returns true if card has valid data and valid target type
	if card_id.is_empty() or effect_type.is_empty():
		return false

	# Validate target type
	var valid_targets: Array[String] = [
		"single_enemy", "all_enemies", "single_ally",
		"all_allies", "self", "dead_ally"
	]

	return target_type in valid_targets


func get_card_description() -> String:
	## Return formatted card description with values (renamed to avoid conflict with Control.get_tooltip)
	var tooltip: String = ""

	# Card name and type
	tooltip += "[b]%s[/b]\n" % card_name
	tooltip += "Type: %s | Cost: %d action\n" % [card_type, cost]
	tooltip += "Target: %s\n" % target_type.to_lower().replace("_", " ")
	tooltip += "\n"

	# Description with values interpolated
	tooltip += _format_description()
	tooltip += "\n"

	# Additional info based on effect type
	if self_damage > 0:
		tooltip += "[color=red]Caster takes %d damage[/color]\n" % self_damage

	if duration > 0 and effect_type in ["regen", "damage_and_burn", "burn", "poison"]:
		tooltip += "Duration: %d turns\n" % duration

	return tooltip


func _format_description() -> String:
	## Format description with interpolated values
	var formatted: String = description

	# Replace common value placeholders with actual values
	formatted = formatted.replace("$value", str(value))
	formatted = formatted.replace("$damage", str(damage_value if damage_value > 0 else value))
	formatted = formatted.replace("$heal", str(heal_value if heal_value > 0 else value))
	formatted = formatted.replace("$block", str(block_value if block_value > 0 else value))
	formatted = formatted.replace("$duration", str(duration))
	formatted = formatted.replace("$bonus", str(bonus_value))
	formatted = formatted.replace("$burn", str(burn_value))
	formatted = formatted.replace("$regen", str(value))

	return formatted


func execute(caster: Champion, targets: Array) -> bool:
	## Execute the card effect on targets
	## Returns true if execution was successful

	if not caster or targets.is_empty():
		return false

	match effect_type:
		"damage":
			return _execute_damage(caster, targets)

		"damage_self_damage":
			return _execute_damage_self_damage(caster, targets)

		"conditional_damage":
			return _execute_conditional_damage(caster, targets)

		"heal":
			return _execute_heal(caster, targets)

		"block":
			return _execute_block(caster, targets)

		"damage_and_block":
			return _execute_damage_and_block(caster, targets)

		"damage_and_heal":
			return _execute_damage_and_heal(caster, targets)

		"aoe_damage":
			return _execute_aoe_damage(caster, targets)

		"taunt":
			return _execute_taunt(caster, targets)

		"counter":
			return _execute_counter(caster, targets)

		"revive":
			return _execute_revive(caster, targets)

		"regen":
			return _execute_regen(caster, targets)

		"cleanse_and_heal":
			return _execute_cleanse_and_heal(caster, targets)

		"damage_and_burn":
			return _execute_damage_and_burn(caster, targets)

		"block_and_thorns":
			return _execute_block_and_thorns(caster, targets)

		"block_and_buff":
			return _execute_block_and_buff(caster, targets)

		_:
			push_error("Unknown effect type: %s" % effect_type)
			return false


func _execute_damage(caster: Champion, targets: Array) -> bool:
	## Execute damage effect
	## Damage = card value + caster's damage stat
	for target in targets:
		if target is Champion:
			var total_damage: int = value + caster.damage
			target.take_damage(total_damage)
	return true


func _execute_damage_self_damage(caster: Champion, targets: Array) -> bool:
	## Execute damage effect with self-damage
	## Damage to target = card value + caster's damage
	## Damage to caster = self_damage value

	# Damage enemies
	for target in targets:
		if target is Champion:
			var total_damage: int = value + caster.damage
			target.take_damage(total_damage)

	# Self damage
	if self_damage > 0:
		caster.take_damage(self_damage)

	return true


func _execute_conditional_damage(caster: Champion, targets: Array) -> bool:
	## Execute conditional damage based on target HP
	for target in targets:
		if target is Champion:
			var total_damage: int = value + caster.damage

			# Check condition and apply bonus if met
			if condition == "hp_below_50_percent":
				var hp_percent: float = float(target.current_hp) / float(target.max_hp) * 100.0
				if hp_percent < 50.0:
					total_damage = bonus_value + caster.damage

			target.take_damage(total_damage)

	return true


func _execute_heal(_caster: Champion, targets: Array) -> bool:
	## Execute heal effect
	## Healing = card value
	for target in targets:
		if target is Champion:
			target.heal(value)
	return true


func _execute_block(_caster: Champion, targets: Array) -> bool:
	## Execute block effect
	## Grant block to target(s)
	for target in targets:
		if target is Champion:
			target.add_block(value)
	return true


func _execute_damage_and_block(caster: Champion, targets: Array) -> bool:
	## Execute damage and block effect
	## Deal damage to first target, grant block to caster
	if targets.is_empty():
		return false

	# Damage to target
	var target = targets[0]
	if target is Champion:
		var total_damage: int = damage_value + caster.damage
		target.take_damage(total_damage)

	# Block to caster
	caster.add_block(block_value)

	return true


func _execute_damage_and_heal(caster: Champion, targets: Array) -> bool:
	## Execute damage and heal effect
	## Deal damage to target, heal caster
	if targets.is_empty():
		return false

	var target = targets[0]
	if target is Champion:
		var total_damage: int = damage_value + caster.damage
		target.take_damage(total_damage)

	caster.heal(heal_value if heal_value > 0 else value)

	return true


func _execute_aoe_damage(caster: Champion, targets: Array) -> bool:
	## Execute AoE damage effect
	## Deal damage to all targets
	for target in targets:
		if target is Champion:
			var total_damage: int = value + caster.damage
			target.take_damage(total_damage)
	return true


func _execute_taunt(caster: Champion, targets: Array) -> bool:
	## Execute taunt effect
	## Add taunt buff to caster (enemies will target this champion next turn)
	caster.add_buff("taunt", 1, duration if duration > 0 else 1)
	return true


func _execute_counter(caster: Champion, targets: Array) -> bool:
	## Execute counter effect
	## Add counter buff (when hit, deal damage back to attacker)
	caster.add_buff("counter", value, duration if duration > 0 else 1)
	return true


func _execute_revive(caster: Champion, targets: Array) -> bool:
	## Execute revive effect
	## Revive a fallen champion with specified HP
	for target in targets:
		if target is Champion and target.is_ko:
			target.revive(value)
			return true
	return false


func _execute_regen(caster: Champion, targets: Array) -> bool:
	## Execute regeneration effect
	## Target heals specified amount per turn for duration
	for target in targets:
		if target is Champion:
			target.add_regen(value, duration if duration > 0 else 1)
	return true


func _execute_cleanse_and_heal(caster: Champion, targets: Array) -> bool:
	## Execute cleanse and heal effect
	## Remove all debuffs from target and heal
	for target in targets:
		if target is Champion:
			# Clear debuffs
			target.debuffs.clear()
			# Heal
			target.heal(value)
	return true


func _execute_damage_and_burn(caster: Champion, targets: Array) -> bool:
	## Execute damage and burn effect
	## Deal damage and apply burn debuff
	for target in targets:
		if target is Champion:
			# Deal damage
			var total_damage: int = damage_value + caster.damage
			target.take_damage(total_damage)
			# Apply burn debuff
			target.add_debuff("burn", burn_value, duration if duration > 0 else 1)
	return true


func _execute_block_and_thorns(caster: Champion, targets: Array) -> bool:
	## Execute block and thorns effect
	## Grant block to caster and apply thorns (attackers take damage)
	caster.add_block(block_value)
	caster.add_buff("thorns", thorns_value, duration if duration > 0 else 1)
	return true


func _execute_block_and_buff(caster: Champion, targets: Array) -> bool:
	## Execute block and buff effect
	## Grant block to caster and buff for next turn
	caster.add_block(block_value)
	caster.add_buff("block_increase", buff_value, duration if duration > 0 else 2)
	return true


## Get card data as a dictionary (useful for UI display)
func get_card_data() -> Dictionary:
	return {
		"card_id": card_id,
		"card_name": card_name,
		"champion_owner": champion_owner,
		"card_type": card_type,
		"cost": cost,
		"target_type": target_type,
		"effect_type": effect_type,
		"value": value,
		"description": description,
		"background_color": background_color
	}


## Get the visual color for this card
func get_background_color() -> Color:
	return background_color
