extends Node
# SaveManager - Handles save/load functionality

const SAVE_PATH = "user://als_tavern_save.json"

func _ready():
	print("SaveManager initialized")

func save_game():
	"""Save the current game state"""
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"game_state": {
			"gold": GameManager.player_gold,
			"battles_won": GameManager.battles_won,
			"battles_lost": GameManager.battles_lost,
			"map_position": {
				"x": GameManager.current_map_position.x,
				"y": GameManager.current_map_position.y
			}
		},
		"party": {
			"active_party": PartyManager.active_party,
			"champion_progress": PartyManager.champion_progress
		},
		"champions_unlocked": CardDatabase.champions_data.duplicate()
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("Game saved successfully")
		return true
	else:
		push_error("Failed to save game")
		return false

func load_game() -> bool:
	"""Load the game state"""
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found")
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open save file")
		return false

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)

	if error != OK:
		push_error("Failed to parse save file: " + json.get_error_message())
		return false

	var save_data = json.data

	# Restore game state
	GameManager.player_gold = save_data["game_state"]["gold"]
	GameManager.battles_won = save_data["game_state"]["battles_won"]
	GameManager.battles_lost = save_data["game_state"]["battles_lost"]
	GameManager.current_map_position = Vector2i(
		save_data["game_state"]["map_position"]["x"],
		save_data["game_state"]["map_position"]["y"]
	)

	# Restore party
	PartyManager.active_party = save_data["party"]["active_party"]
	PartyManager.champion_progress = save_data["party"]["champion_progress"]

	# Restore champion unlocks
	CardDatabase.champions_data = save_data["champions_unlocked"]

	print("Game loaded successfully")
	return true

func has_save() -> bool:
	"""Check if a save file exists"""
	return FileAccess.file_exists(SAVE_PATH)

func delete_save():
	"""Delete the save file"""
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("Save file deleted")
