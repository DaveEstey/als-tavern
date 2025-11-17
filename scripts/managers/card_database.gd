extends Node
# CardDatabase - Loads and manages all card and champion data

var champions_data: Dictionary = {}
var cards_data: Dictionary = {}
var enemies_data: Dictionary = {}

func _ready():
	load_all_data()

func load_all_data():
	"""Load all JSON data files"""
	champions_data = load_json("res://data/champions.json")
	cards_data = load_json("res://data/cards.json")
	enemies_data = load_json("res://data/enemies.json")

	print("CardDatabase loaded:")
	print("  Champions: ", champions_data.size())
	print("  Cards: ", cards_data.size())
	print("  Enemies: ", enemies_data.size())

func load_json(file_path: String) -> Dictionary:
	"""Load a JSON file and return as Dictionary"""
	if not FileAccess.file_exists(file_path):
		push_error("File not found: " + file_path)
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)

	if error != OK:
		push_error("JSON parse error in " + file_path + ": " + json.get_error_message())
		return {}

	return json.data

func get_champion_data(champion_id: String) -> Dictionary:
	"""Get champion data by ID"""
	return champions_data.get(champion_id, {})

func get_card_data(card_id: String) -> Dictionary:
	"""Get card data by ID"""
	return cards_data.get(card_id, {})

func get_enemy_data(enemy_id: String) -> Dictionary:
	"""Get enemy data by ID"""
	return enemies_data.get(enemy_id, {})

func get_unlocked_champions() -> Array:
	"""Get list of unlocked champion IDs"""
	var unlocked = []
	for champ_id in champions_data.keys():
		if champions_data[champ_id].get("unlocked", false):
			unlocked.append(champ_id)
	return unlocked

func get_champion_cards(champion_id: String) -> Array:
	"""Get all card IDs for a champion"""
	var champion_cards = []
	for card_id in cards_data.keys():
		if cards_data[card_id].get("champion") == champion_id:
			champion_cards.append(card_id)
	return champion_cards

func get_core_cards(champion_id: String) -> Array:
	"""Get core card IDs for a champion"""
	var champ_data = get_champion_data(champion_id)
	return champ_data.get("core_cards", [])
