class_name Champion
extends Node2D

# Properties
var champion_id: String
var champion_name: String
var current_hp: int
var max_hp: int
var damage: int
var defense: int
var block: int  # Temporary block that resets each turn
var is_ko: bool
var level: int

# Status effects
var regen_stacks: Array[Dictionary]  # Array of {value: int, duration: int}
var buffs: Array[Dictionary]  # Array of {type: String, value: int, duration: int}
var debuffs: Array[Dictionary]  # Array of {type: String, value: int, duration: int}

# References
var party_manager: Node


func _ready() -> void:
	# Get reference to PartyManager (autoload)
	party_manager = get_tree().root.get_child(0).get_node_or_null("PartyManager")
	if not party_manager:
		push_error("PartyManager not found. Make sure it's set up as an autoload.")


## Initialize champion with data from PartyManager
func initialize(champ_id: String) -> void:
	champion_id = champ_id

	# Load champion data from PartyManager
	if party_manager and party_manager.has_method("get_champion_data"):
		var champ_data = party_manager.get_champion_data(champ_id)
		if champ_data:
			champion_name = champ_data.get("name", "Unknown")
			max_hp = champ_data.get("max_hp", 100)
			current_hp = max_hp
			damage = champ_data.get("damage", 10)
			defense = champ_data.get("defense", 5)
			level = champ_data.get("level", 1)
		else:
			push_error("Champion data not found for ID: %s" % champ_id)
			_set_default_values()
	else:
		push_warning("PartyManager not available, using default values")
		_set_default_values()

	# Initialize status arrays
	block = 0
	is_ko = false
	regen_stacks = []
	buffs = []
	debuffs = []


## Set default values for champion
func _set_default_values() -> void:
	champion_name = "Champion"
	max_hp = 100
	current_hp = 100
	damage = 10
	defense = 5
	level = 1
	block = 0
	is_ko = false


## Apply damage to champion after defense and block
## Returns the actual damage taken
func take_damage(amount: int) -> int:
	if is_ko:
		return 0

	var total_damage = amount

	# Apply defense reduction (20% reduction per defense point)
	var defense_reduction = int(total_damage * (float(defense) * 0.02))
	total_damage = max(1, total_damage - defense_reduction)

	# Apply block first (absorbs damage before HP)
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

	# Check for KO
	if current_hp <= 0:
		current_hp = 0
		is_ko = true

	return actual_damage


## Restore HP to champion (cannot exceed max_hp)
func heal(amount: int) -> void:
	if is_ko:
		return

	current_hp = min(current_hp + amount, max_hp)


## Add temporary block that lasts until reset_block() is called
func add_block(amount: int) -> void:
	block += amount


## Reset block at the start of a turn
func reset_block() -> void:
	block = 0


## Apply all regeneration effects and decrease their duration
func apply_regen() -> void:
	if is_ko or regen_stacks.is_empty():
		return

	var total_regen = 0
	var expired_indices: Array[int] = []

	for i in range(regen_stacks.size()):
		var regen = regen_stacks[i]
		total_regen += regen.get("value", 0)

		# Decrease duration
		regen["duration"] -= 1

		# Mark for removal if duration expired
		if regen["duration"] <= 0:
			expired_indices.append(i)

	# Remove expired regeneration stacks (iterate backwards to maintain indices)
	for i in range(expired_indices.size() - 1, -1, -1):
		regen_stacks.remove_at(expired_indices[i])

	# Apply healing
	if total_regen > 0:
		heal(total_regen)


## Check if champion is knocked out (HP <= 0)
func check_ko() -> bool:
	return is_ko


## Revive champion with specified HP amount
func revive(hp_amount: int) -> void:
	if hp_amount <= 0:
		push_error("Revive HP amount must be greater than 0")
		return

	is_ko = false
	current_hp = min(hp_amount, max_hp)


## Get all current stats as a dictionary
func get_stats() -> Dictionary:
	return {
		"champion_id": champion_id,
		"champion_name": champion_name,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"damage": damage,
		"defense": defense,
		"block": block,
		"is_ko": is_ko,
		"level": level,
		"hp_percentage": float(current_hp) / float(max_hp) * 100.0,
		"regen_stacks": regen_stacks.duplicate(),
		"buffs": buffs.duplicate(),
		"debuffs": debuffs.duplicate()
	}


## Add a regeneration effect
func add_regen(value: int, duration: int) -> void:
	regen_stacks.append({
		"value": value,
		"duration": duration
	})


## Add a buff effect
func add_buff(buff_type: String, value: int, duration: int) -> void:
	buffs.append({
		"type": buff_type,
		"value": value,
		"duration": duration
	})


## Add a debuff effect
func add_debuff(debuff_type: String, value: int, duration: int) -> void:
	debuffs.append({
		"type": debuff_type,
		"value": value,
		"duration": duration
	})


## Update buff and debuff durations (call once per turn)
func update_effects() -> void:
	_update_effect_list(buffs)
	_update_effect_list(debuffs)


## Helper function to update effect durations
func _update_effect_list(effects: Array[Dictionary]) -> void:
	var expired_indices: Array[int] = []

	for i in range(effects.size()):
		var effect = effects[i]
		effect["duration"] -= 1

		if effect["duration"] <= 0:
			expired_indices.append(i)

	# Remove expired effects (iterate backwards)
	for i in range(expired_indices.size() - 1, -1, -1):
		effects.remove_at(expired_indices[i])
