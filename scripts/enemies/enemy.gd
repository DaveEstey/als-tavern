class_name Enemy
extends Node2D
## Enemy class - Represents an enemy in battle with AI attack selection

# Enemy data properties
var enemy_id: String = ""
var enemy_name: String = ""
var enemy_type: String = ""  # trash, elite, or boss
var current_hp: int = 0
var max_hp: int = 0
var damage: int = 0
var defense: int = 0
var block: int = 0  # Temporary block that resets each turn
var is_dead: bool = false

# Attack data
var attacks: Array[Dictionary] = []

# Boss-specific properties (card-based combat)
var uses_cards: bool = false
var card_deck: Array[String] = []

# References
var card_database: Node


func _ready() -> void:
	## Initialize card database reference
	if has_node("/root/CardDatabase"):
		card_database = get_node("/root/CardDatabase")
	else:
		push_error("CardDatabase not found. Make sure it's set up as an autoload.")


## Initialize enemy with data from CardDatabase
func initialize(enemy_id_param: String) -> void:
	enemy_id = enemy_id_param

	if not card_database:
		push_error("CardDatabase not available for enemy initialization")
		return

	# Get enemy data from database
	var enemy_data: Dictionary = card_database.get_enemy_data(enemy_id)
	if enemy_data.is_empty():
		push_error("Enemy data not found for ID: %s" % enemy_id)
		return

	# Load basic properties
	enemy_name = enemy_data.get("name", "Unknown Enemy")
	enemy_type = enemy_data.get("type", "trash")
	max_hp = enemy_data.get("hp", 10)
	current_hp = max_hp
	damage = enemy_data.get("damage", 5)
	defense = enemy_data.get("defense", 0)

	# Load attacks
	var attacks_data: Array = enemy_data.get("attacks", [])
	attacks.clear()
	for attack_data in attacks_data:
		attacks.append(attack_data as Dictionary)

	# Load boss-specific properties
	uses_cards = enemy_data.get("uses_cards", false)
	card_deck = enemy_data.get("card_deck", []) as Array[String]

	# Initialize status
	block = 0
	is_dead = false


## Apply damage to enemy after defense and block
## Returns the actual damage taken
func take_damage(amount: int) -> int:
	if is_dead:
		return 0

	var total_damage = amount

	# Apply defense reduction (20% reduction per defense point, minimum 1 damage)
	var defense_reduction = int(total_damage * (float(defense) * 0.02))
	total_damage = max(1, total_damage - defense_reduction)

	# Apply block first (absorbs damage before HP)
	var remaining_block = block
	if block > 0:
		if total_damage <= block:
			block -= total_damage
			return 0  # Damage fully blocked
		else:
			total_damage -= block
			block = 0

	# Apply damage to HP
	var actual_damage = min(total_damage, current_hp)
	current_hp -= actual_damage

	# Check for death
	if current_hp <= 0:
		current_hp = 0
		is_dead = true

	return actual_damage


## Add temporary block that lasts until reset_block() is called
func add_block(amount: int) -> void:
	block += amount


## Reset block at the start of a turn
func reset_block() -> void:
	block = 0


## Randomly select an attack from attacks array
## Returns a dictionary with attack data, or empty dict if no attacks available
func choose_attack() -> Dictionary:
	if attacks.is_empty():
		push_warning("Enemy %s has no attacks available" % enemy_name)
		return {}

	# Randomly select an attack
	var random_index: int = randi() % attacks.size()
	return attacks[random_index].duplicate()


## Execute the chosen attack on target champions
## Returns a dictionary with attack result {type, damage, target_index, etc}
func execute_attack(targets: Array) -> Dictionary:
	if targets.is_empty():
		return {
			"success": false,
			"message": "No targets available for attack"
		}

	# Choose an attack
	var attack: Dictionary = choose_attack()
	if attack.is_empty():
		return {
			"success": false,
			"message": "No attack available"
		}

	# Execute based on attack type
	var result: Dictionary = {
		"success": true,
		"attack_name": attack.get("name", "Unknown Attack"),
		"attack_type": attack.get("type", "damage"),
		"target_index": 0,
		"damage": 0,
		"damage_dealt": 0,
		"block_value": 0
	}

	match attack.get("type", ""):
		"damage":
			result = _execute_damage_attack(attack, targets, result)

		"aoe_damage":
			result = _execute_aoe_damage_attack(attack, targets, result)

		"block":
			result = _execute_block_attack(attack, result)

		"buff_self":
			result = _execute_buff_self_attack(attack, result)

		"damage_and_heal":
			result = _execute_damage_and_heal_attack(attack, targets, result)

		"damage_and_poison":
			result = _execute_damage_and_poison_attack(attack, targets, result)

		_:
			push_warning("Unknown attack type: %s" % attack.get("type", ""))
			result["success"] = false

	return result


## Execute a single-target damage attack
func _execute_damage_attack(attack: Dictionary, targets: Array, result: Dictionary) -> Dictionary:
	# Select a random target
	var target_index: int = randi() % targets.size()
	var target = targets[target_index]

	# Calculate damage
	var attack_damage: int = attack.get("value", 0) + damage
	var actual_damage: int = 0

	# Apply damage to target if it has take_damage method
	if target.has_method("take_damage"):
		actual_damage = target.take_damage(attack_damage)

	result["target_index"] = target_index
	result["damage"] = attack_damage
	result["damage_dealt"] = actual_damage

	return result


## Execute an area-of-effect damage attack
func _execute_aoe_damage_attack(attack: Dictionary, targets: Array, result: Dictionary) -> Dictionary:
	var attack_damage: int = attack.get("value", 0) + damage
	var total_damage_dealt: int = 0
	var affected_targets: Array[int] = []

	# Apply damage to all targets
	for i in range(targets.size()):
		var target = targets[i]
		if target.has_method("take_damage"):
			var actual_damage = target.take_damage(attack_damage)
			total_damage_dealt += actual_damage
			affected_targets.append(i)

	result["damage"] = attack_damage
	result["damage_dealt"] = total_damage_dealt
	result["affected_targets"] = affected_targets

	return result


## Execute a block (self-protection) attack
func _execute_block_attack(attack: Dictionary, result: Dictionary) -> Dictionary:
	var block_value: int = attack.get("value", 0)
	add_block(block_value)

	result["block_value"] = block_value
	result["message"] = "%s gains %d block" % [enemy_name, block_value]

	return result


## Execute a self-buff attack
func _execute_buff_self_attack(attack: Dictionary, result: Dictionary) -> Dictionary:
	var buff_type: String = attack.get("buff_type", "")
	var buff_value: int = attack.get("value", 0)

	result["buff_type"] = buff_type
	result["buff_value"] = buff_value
	result["message"] = "%s uses %s and gains %d %s" % [
		enemy_name,
		attack.get("name", "buff"),
		buff_value,
		buff_type
	]

	return result


## Execute damage and heal attack
func _execute_damage_and_heal_attack(attack: Dictionary, targets: Array, result: Dictionary) -> Dictionary:
	if targets.is_empty():
		return result

	# Select a random target
	var target_index: int = randi() % targets.size()
	var target = targets[target_index]

	# Calculate and apply damage
	var attack_damage: int = attack.get("damage_value", 0) + damage
	var actual_damage: int = 0

	if target.has_method("take_damage"):
		actual_damage = target.take_damage(attack_damage)

	# Heal self
	var heal_value: int = attack.get("heal_value", 0)
	current_hp = min(current_hp + heal_value, max_hp)

	result["target_index"] = target_index
	result["damage"] = attack_damage
	result["damage_dealt"] = actual_damage
	result["heal_value"] = heal_value
	result["message"] = "%s drains %d HP from target and heals %d" % [
		enemy_name,
		actual_damage,
		heal_value
	]

	return result


## Execute damage and poison attack
func _execute_damage_and_poison_attack(attack: Dictionary, targets: Array, result: Dictionary) -> Dictionary:
	if targets.is_empty():
		return result

	# Select a random target
	var target_index: int = randi() % targets.size()
	var target = targets[target_index]

	# Calculate and apply damage
	var attack_damage: int = attack.get("damage_value", 0) + damage
	var actual_damage: int = 0

	if target.has_method("take_damage"):
		actual_damage = target.take_damage(attack_damage)

	# Apply poison debuff if target supports it
	var poison_value: int = attack.get("poison_value", 0)
	var duration: int = attack.get("duration", 1)

	if target.has_method("add_debuff"):
		target.add_debuff("poison", poison_value, duration)

	result["target_index"] = target_index
	result["damage"] = attack_damage
	result["damage_dealt"] = actual_damage
	result["poison_value"] = poison_value
	result["poison_duration"] = duration
	result["message"] = "%s poisons target for %d damage per turn" % [enemy_name, poison_value]

	return result


## Check if enemy is dead (HP <= 0)
func check_death() -> bool:
	return is_dead


## Get all current stats as a dictionary
func get_stats() -> Dictionary:
	return {
		"enemy_id": enemy_id,
		"enemy_name": enemy_name,
		"enemy_type": enemy_type,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"damage": damage,
		"defense": defense,
		"block": block,
		"is_dead": is_dead,
		"hp_percentage": float(current_hp) / float(max_hp) * 100.0 if max_hp > 0 else 0.0,
		"uses_cards": uses_cards,
		"card_deck_size": card_deck.size(),
		"attack_count": attacks.size()
	}
