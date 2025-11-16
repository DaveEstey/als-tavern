extends Node
# GameManager - Global game state management

signal battle_started
signal battle_ended(victory: bool)
signal champion_unlocked(champion_id: String)

# Game state
var current_scene: String = ""
var player_gold: int = 100
var current_map_position: Vector2i = Vector2i.ZERO
var battles_won: int = 0
var battles_lost: int = 0

# Battle state
var current_battle_enemies: Array = []
var battle_rewards: Dictionary = {}

func _ready():
	print("GameManager initialized")

func start_battle(enemies: Array):
	"""Start a battle with given enemies"""
	current_battle_enemies = enemies
	battle_started.emit()
	get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")

func end_battle(victory: bool, rewards: Dictionary = {}):
	"""End the current battle"""
	if victory:
		battles_won += 1
		player_gold += rewards.get("gold", 0)
		battle_rewards = rewards

		# Check if boss unlocked a champion
		if rewards.has("unlock_champion"):
			unlock_champion(rewards["unlock_champion"])
	else:
		battles_lost += 1

	battle_ended.emit(victory)

func unlock_champion(champion_id: String):
	"""Unlock a new champion"""
	var champ_data = CardDatabase.champions_data.get(champion_id)
	if champ_data:
		champ_data["unlocked"] = true
		champion_unlocked.emit(champion_id)
		print("Champion unlocked: ", champion_id)

func add_gold(amount: int):
	"""Add gold to player"""
	player_gold += amount
	player_gold = max(0, player_gold)

func spend_gold(amount: int) -> bool:
	"""Spend gold, returns true if successful"""
	if player_gold >= amount:
		player_gold -= amount
		return true
	return false

func reset_game():
	"""Reset game to initial state"""
	player_gold = 100
	battles_won = 0
	battles_lost = 0
	current_map_position = Vector2i.ZERO
	PartyManager.reset_party()
