extends Control
## MapScene - Main map exploration scene controller
##
## This script attaches to the root Control node of the map scene and manages
## the map exploration interface, allowing players to navigate between nodes
## and triggering various encounters (battles, shops, rest sites, etc.)
##
## SCENE TREE STRUCTURE (to be created in Godot editor):
## ========================================================
## MapScene (Control) - this script
## ├── MapGenerator (Node - map_generator.gd)
## ├── Background (ColorRect) - full screen background
## │   └── [Properties] anchors_preset = 15 (full rect), color = dark blue/purple
## ├── MapContainer (Control) - holds all map node visuals
## │   └── [Properties] anchors_preset = 15 (full rect)
## │   └── NodeGrid (Control) - visual container for nodes
## │       └── [Properties] custom_minimum_size for scrolling
## ├── PlayerMarker (Control) - visual indicator of player position
## │   └── [Properties] size = Vector2(40, 40)
## │   └── Icon (TextureRect or ColorRect)
## │   └── Label (Label) - "YOU"
## ├── PathLines (Control) - draws connections between nodes
## │   └── [Properties] mouse_filter = MOUSE_FILTER_IGNORE
## ├── UIElements (Control) - overlay UI
## │   ├── GoldLabel (Label) - top left
## │   │   └── [Properties] text = "Gold: 0", anchors_preset = 0 (top left)
## │   ├── FloorLabel (Label) - top center
## │   │   └── [Properties] text = "Floor 1", anchors_preset = 5 (top center)
## │   ├── PartyButton (Button) - top right
## │   │   └── [Properties] text = "Party", anchors_preset = 1 (top right)
## │   └── MapInfoLabel (Label) - bottom center
## │       └── [Properties] text = "Select a node to continue", anchors_preset = 7 (bottom center)
## └── EventPanel (Panel) - overlay for events, initially hidden
##     └── [Properties] visible = false, anchors_preset = 8 (center)
##     └── VBoxContainer
##         ├── EventTitle (Label)
##         ├── EventDescription (Label)
##         └── EventOptions (VBoxContainer) - dynamic buttons

# Signals
signal node_entered(node_id: int, node_type: String)
signal battle_requested(enemy_ids: Array)
signal map_completed()

# Node references - Map generation
@onready var map_generator: Node = $MapGenerator

# Node references - UI containers
@onready var map_container: Control = $MapContainer
@onready var node_grid: Control = $MapContainer/NodeGrid
@onready var player_marker: Control = $PlayerMarker
@onready var path_lines: Control = $PathLines

# Node references - UI elements
@onready var gold_label: Label = $UIElements/GoldLabel
@onready var floor_label: Label = $UIElements/FloorLabel
@onready var party_button: Button = $UIElements/PartyButton
@onready var map_info_label: Label = $UIElements/MapInfoLabel

# Node references - Event panel
@onready var event_panel: Panel = $EventPanel
@onready var event_title: Label = $EventPanel/VBoxContainer/EventTitle
@onready var event_description: Label = $EventPanel/VBoxContainer/EventDescription
@onready var event_options: VBoxContainer = $EventPanel/VBoxContainer/EventOptions

# Manager references
var game_manager: Node

# Map state
var current_map: Array[Dictionary] = []
var current_node_id: int = 0
var current_floor: int = 1
var node_ui_instances: Dictionary = {}  # {node_id: Control}
var available_nodes: Array[int] = []

# Map visual settings
const NODE_SIZE: Vector2 = Vector2(80, 80)
const LAYER_SPACING: float = 150.0
const NODE_SPACING: float = 100.0
const PATH_COLOR: Color = Color(0.6, 0.6, 0.8, 0.5)
const PATH_WIDTH: float = 3.0


func _ready() -> void:
	# Get reference to GameManager (autoload)
	game_manager = get_tree().root.get_child(0).get_node_or_null("GameManager")
	if not game_manager:
		push_error("GameManager not found. Make sure it's set up as an autoload.")
		return

	# Connect UI signals
	_connect_ui_signals()

	# Hide event panel initially
	if event_panel:
		event_panel.hide()

	# Generate and display the map
	generate_and_display_map()

	# Update UI
	_update_ui()

	print("MapScene: Ready - Map generated with %d nodes" % current_map.size())


## Connect UI element signals
func _connect_ui_signals() -> void:
	if party_button:
		party_button.pressed.connect(_on_party_button_pressed)


## Generate map data and create visual representation
func generate_and_display_map() -> void:
	# Clear existing map
	current_map.clear()
	node_ui_instances.clear()
	available_nodes.clear()

	# Clear existing visual nodes
	if node_grid:
		for child in node_grid.get_children():
			child.queue_free()

	# Generate map structure
	if map_generator and map_generator.has_method("generate_map"):
		current_map = map_generator.generate_map(current_floor)
	else:
		# Fallback: create a simple test map if generator not available
		push_warning("MapGenerator not found or missing generate_map method, using test map")
		current_map = _generate_test_map()

	if current_map.is_empty():
		push_error("Failed to generate map")
		return

	# Find starting node
	current_node_id = _find_starting_node()

	# Create visual nodes for all map nodes
	for node_data in current_map:
		var node_ui = create_node_ui(node_data)
		if node_ui:
			node_ui_instances[node_data.id] = node_ui
			if node_grid:
				node_grid.add_child(node_ui)

	# Position player marker at starting node
	_update_player_position()

	# Update available nodes (nodes player can click)
	update_available_nodes()

	# Draw paths between nodes
	if path_lines:
		path_lines.queue_redraw()


## Create visual UI node for a map node
func create_node_ui(node_data: Dictionary) -> Control:
	var node_ui = Control.new()
	node_ui.custom_minimum_size = NODE_SIZE
	node_ui.size = NODE_SIZE

	# Position based on layer and position in layer
	var layer: int = node_data.get("layer", 0)
	var layer_position: int = node_data.get("layer_position", 0)
	var nodes_in_layer: int = node_data.get("nodes_in_layer", 1)

	# Calculate position (centered in layer)
	var x_offset = (node_grid.size.x / 2.0) - ((nodes_in_layer - 1) * NODE_SPACING / 2.0)
	var x_pos = x_offset + (layer_position * NODE_SPACING)
	var y_pos = 100.0 + (layer * LAYER_SPACING)

	node_ui.position = Vector2(x_pos, y_pos)

	# Create background panel
	var panel = Panel.new()
	panel.custom_minimum_size = NODE_SIZE
	panel.size = NODE_SIZE
	node_ui.add_child(panel)

	# Create icon/visual based on node type
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(60, 60)
	icon.size = Vector2(60, 60)
	icon.position = Vector2(10, 10)
	icon.color = _get_node_color(node_data.get("type", "unknown"))
	panel.add_child(icon)

	# Create label for node type
	var label = Label.new()
	label.text = _get_node_label(node_data.get("type", "unknown"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = NODE_SIZE
	label.add_theme_font_size_override("font_size", 12)
	panel.add_child(label)

	# Make node clickable
	var button = Button.new()
	button.custom_minimum_size = NODE_SIZE
	button.size = NODE_SIZE
	button.flat = true
	button.modulate = Color(1, 1, 1, 0)  # Invisible but clickable
	button.pressed.connect(_on_node_clicked.bind(node_data.id))
	panel.add_child(button)

	# Store reference to button for enabling/disabling
	node_ui.set_meta("button", button)
	node_ui.set_meta("panel", panel)
	node_ui.set_meta("node_id", node_data.id)

	return node_ui


## Get color for node type
func _get_node_color(node_type: String) -> Color:
	match node_type:
		"start":
			return Color(0.2, 1.0, 0.2)  # Green
		"battle":
			return Color(1.0, 0.2, 0.2)  # Red
		"elite":
			return Color(1.0, 0.5, 0.0)  # Orange
		"boss":
			return Color(0.8, 0.0, 0.8)  # Purple
		"shop":
			return Color(1.0, 1.0, 0.2)  # Yellow
		"rest":
			return Color(0.2, 0.5, 1.0)  # Blue
		"shrine":
			return Color(0.5, 0.0, 1.0)  # Violet
		"treasure":
			return Color(1.0, 0.8, 0.2)  # Gold
		"event":
			return Color(0.5, 1.0, 0.5)  # Light green
		_:
			return Color(0.5, 0.5, 0.5)  # Gray


## Get label text for node type
func _get_node_label(node_type: String) -> String:
	match node_type:
		"start":
			return "START"
		"battle":
			return "FIGHT"
		"elite":
			return "ELITE"
		"boss":
			return "BOSS"
		"shop":
			return "SHOP"
		"rest":
			return "REST"
		"shrine":
			return "SHRINE"
		"treasure":
			return "CHEST"
		"event":
			return "EVENT"
		_:
			return "???"


## Handle node click
func _on_node_clicked(node_id: int) -> void:
	print("MapScene: Node clicked - ID: %d" % node_id)

	# Check if node is available for selection
	if node_id not in available_nodes:
		print("MapScene: Node %d is not available" % node_id)
		return

	# Move to the node
	move_to_node(node_id)


## Move player to a specific node and trigger its event
func move_to_node(node_id: int) -> void:
	print("MapScene: Moving to node %d" % node_id)

	# Update current position
	current_node_id = node_id

	# Update player marker position
	_update_player_position()

	# Find node data
	var node: Dictionary = _find_node_by_id(node_id)
	if node.is_empty():
		push_error("Node %d not found in current_map" % node_id)
		return

	# Emit signal
	var node_type: String = node.get("type", "unknown")
	node_entered.emit(node_id, node_type)

	# Trigger node event
	trigger_node_event(node)

	# Update available nodes
	update_available_nodes()


## Trigger the event/encounter for a specific node
func trigger_node_event(node: Dictionary) -> void:
	var node_type: String = node.get("type", "unknown")

	print("MapScene: Triggering event - Type: %s" % node_type)

	match node_type:
		"start":
			# Starting node - no event, just update UI
			if map_info_label:
				map_info_label.text = "Journey begins! Choose your path."

		"battle":
			_start_battle(node)

		"elite":
			_start_battle(node)

		"boss":
			_start_battle(node)

		"shop":
			_open_shop()

		"rest":
			_open_rest_site()

		"shrine":
			_open_shrine()

		"treasure":
			_open_treasure()

		"event":
			_trigger_random_event(node)

		_:
			push_warning("Unknown node type: %s" % node_type)


## Update which nodes are available for player to click
func update_available_nodes() -> void:
	available_nodes.clear()

	# Find current node
	var current_node: Dictionary = _find_node_by_id(current_node_id)
	if current_node.is_empty():
		return

	# Get connected nodes
	var connected_ids: Array = current_node.get("connected_to", [])
	available_nodes.assign(connected_ids)

	# Update visual state of all nodes
	for node_id in node_ui_instances.keys():
		var node_ui = node_ui_instances[node_id]
		var button = node_ui.get_meta("button") if node_ui.has_meta("button") else null
		var panel = node_ui.get_meta("panel") if node_ui.has_meta("panel") else null

		if button:
			button.disabled = (node_id not in available_nodes)

		# Highlight available nodes
		if panel:
			if node_id == current_node_id:
				panel.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Current node - full brightness
			elif node_id in available_nodes:
				panel.modulate = Color(1.2, 1.2, 1.2, 1.0)  # Available - highlighted
			else:
				panel.modulate = Color(0.5, 0.5, 0.5, 0.7)  # Unavailable - dimmed

	print("MapScene: Available nodes updated - %d nodes available" % available_nodes.size())


## Start a battle encounter
func _start_battle(node: Dictionary) -> void:
	var node_type: String = node.get("type", "battle")
	var enemy_ids: Array = []

	# Determine enemies based on node type
	match node_type:
		"battle":
			# Regular battle - 1-3 trash enemies
			enemy_ids = _generate_battle_enemies("trash", randi_range(1, 3))

		"elite":
			# Elite battle - 1 elite enemy
			enemy_ids = _generate_battle_enemies("elite", 1)

		"boss":
			# Boss battle - 1 boss enemy
			enemy_ids = _generate_battle_enemies("boss", 1)

	# Override with node-specific enemies if provided
	if node.has("enemies"):
		enemy_ids = node.get("enemies", [])

	print("MapScene: Starting battle with enemies: %s" % str(enemy_ids))

	# Emit battle requested signal
	battle_requested.emit(enemy_ids)

	# Start battle through GameManager
	if game_manager and game_manager.has_method("start_battle"):
		game_manager.start_battle(enemy_ids)
	else:
		push_error("Cannot start battle - GameManager not available")


## Generate random enemies for battle
func _generate_battle_enemies(enemy_type: String, count: int) -> Array:
	var enemies: Array = []

	# These would normally come from CardDatabase or enemy pool
	var trash_pool = ["goblin", "skeleton", "slime"]
	var elite_pool = ["orc_warrior", "dark_mage", "minotaur"]
	var boss_pool = ["dragon", "lich_king", "demon_lord"]

	var pool: Array = []
	match enemy_type:
		"trash":
			pool = trash_pool
		"elite":
			pool = elite_pool
		"boss":
			pool = boss_pool

	if pool.is_empty():
		pool = ["goblin"]  # Fallback

	for i in range(count):
		var random_enemy = pool[randi() % pool.size()]
		enemies.append(random_enemy)

	return enemies


## Open shop interface
func _open_shop() -> void:
	print("MapScene: Opening shop")

	if map_info_label:
		map_info_label.text = "Welcome to the shop!"

	# TODO: Implement shop UI
	# For now, show a simple event panel
	_show_event_panel(
		"Shop",
		"A merchant offers their wares.\n(Shop UI not yet implemented)",
		["Continue"]
	)


## Open rest site interface
func _open_rest_site() -> void:
	print("MapScene: Opening rest site")

	if map_info_label:
		map_info_label.text = "You rest and recover."

	# Heal all champions
	if game_manager and game_manager.has("party_manager"):
		var party_manager = game_manager.party_manager
		if party_manager and party_manager.has_method("heal_all_champions"):
			party_manager.heal_all_champions(9999)  # Full heal

	_show_event_panel(
		"Rest Site",
		"You take a moment to rest.\nAll champions restored to full health!",
		["Continue"]
	)


## Open shrine interface
func _open_shrine() -> void:
	print("MapScene: Opening shrine")

	if map_info_label:
		map_info_label.text = "You approach the mysterious shrine."

	_show_event_panel(
		"Shrine",
		"A mystical shrine pulses with ancient power.\n(Shrine effects not yet implemented)",
		["Pray", "Leave"]
	)


## Open treasure chest
func _open_treasure() -> void:
	print("MapScene: Opening treasure")

	# Give random reward
	var gold_reward = randi_range(20, 50)

	if game_manager and game_manager.has_method("add_gold"):
		game_manager.add_gold(gold_reward)

	if map_info_label:
		map_info_label.text = "You found treasure!"

	_update_ui()

	_show_event_panel(
		"Treasure!",
		"You open the chest and find %d gold!" % gold_reward,
		["Continue"]
	)


## Trigger a random event
func _trigger_random_event(node: Dictionary) -> void:
	print("MapScene: Random event triggered")

	var events = [
		{
			"title": "Mysterious Stranger",
			"description": "A hooded figure offers you a deal...",
			"options": ["Accept", "Decline"]
		},
		{
			"title": "Ancient Fountain",
			"description": "A fountain glows with magical energy.",
			"options": ["Drink", "Ignore"]
		}
	]

	var event = events[randi() % events.size()]

	_show_event_panel(event.title, event.description, event.options)


## Show event panel with options
func _show_event_panel(title: String, description: String, options: Array) -> void:
	if not event_panel:
		push_error("Event panel not found")
		return

	# Set title and description
	if event_title:
		event_title.text = title

	if event_description:
		event_description.text = description

	# Clear existing option buttons
	if event_options:
		for child in event_options.get_children():
			child.queue_free()

		# Create new option buttons
		for option_text in options:
			var button = Button.new()
			button.text = option_text
			button.pressed.connect(_on_event_option_pressed.bind(option_text))
			event_options.add_child(button)

	# Show panel
	event_panel.show()


## Handle event option button press
func _on_event_option_pressed(option: String) -> void:
	print("MapScene: Event option selected - %s" % option)

	# Hide event panel
	if event_panel:
		event_panel.hide()

	# Check if this was the boss node (map completion)
	var current_node = _find_node_by_id(current_node_id)
	if current_node.get("type", "") == "boss" and option == "Continue":
		_complete_map()


## Complete the current map floor
func _complete_map() -> void:
	print("MapScene: Map floor completed!")

	map_completed.emit()

	# Progress to next floor
	current_floor += 1

	# Regenerate map for next floor
	generate_and_display_map()


## Update player marker position
func _update_player_position() -> void:
	if not player_marker or not node_ui_instances.has(current_node_id):
		return

	var current_node_ui = node_ui_instances[current_node_id]
	player_marker.position = current_node_ui.position + Vector2(NODE_SIZE.x / 2.0 - 20, -50)


## Update UI elements
func _update_ui() -> void:
	# Update gold label
	if gold_label and game_manager:
		gold_label.text = "Gold: %d" % game_manager.get("player_gold", 0)

	# Update floor label
	if floor_label:
		floor_label.text = "Floor %d" % current_floor


## Called when Party button is pressed
func _on_party_button_pressed() -> void:
	print("MapScene: Party button pressed")
	# TODO: Open party management screen


## Find node by ID in current_map
func _find_node_by_id(node_id: int) -> Dictionary:
	for node in current_map:
		if node.get("id", -1) == node_id:
			return node
	return {}


## Find the starting node ID
func _find_starting_node() -> int:
	for node in current_map:
		if node.get("type", "") == "start":
			return node.get("id", 0)
	return 0


## Generate a simple test map for development
func _generate_test_map() -> Array[Dictionary]:
	var test_map: Array[Dictionary] = []

	# Layer 0 - Start
	test_map.append({
		"id": 0,
		"type": "start",
		"layer": 0,
		"layer_position": 0,
		"nodes_in_layer": 1,
		"connected_to": [1, 2]
	})

	# Layer 1 - Two battles
	test_map.append({
		"id": 1,
		"type": "battle",
		"layer": 1,
		"layer_position": 0,
		"nodes_in_layer": 2,
		"connected_to": [3]
	})

	test_map.append({
		"id": 2,
		"type": "battle",
		"layer": 1,
		"layer_position": 1,
		"nodes_in_layer": 2,
		"connected_to": [3, 4]
	})

	# Layer 2 - Shop and Rest
	test_map.append({
		"id": 3,
		"type": "shop",
		"layer": 2,
		"layer_position": 0,
		"nodes_in_layer": 2,
		"connected_to": [5]
	})

	test_map.append({
		"id": 4,
		"type": "rest",
		"layer": 2,
		"layer_position": 1,
		"nodes_in_layer": 2,
		"connected_to": [5]
	})

	# Layer 3 - Boss
	test_map.append({
		"id": 5,
		"type": "boss",
		"layer": 3,
		"layer_position": 0,
		"nodes_in_layer": 1,
		"connected_to": []
	})

	return test_map


## Draw paths between connected nodes (called via queue_redraw)
func _draw() -> void:
	if not path_lines:
		return

	# Draw lines between connected nodes
	for node_data in current_map:
		var node_id = node_data.get("id", -1)
		var connected_ids: Array = node_data.get("connected_to", [])

		if not node_ui_instances.has(node_id):
			continue

		var start_ui = node_ui_instances[node_id]
		var start_pos = start_ui.position + NODE_SIZE / 2.0

		for connected_id in connected_ids:
			if not node_ui_instances.has(connected_id):
				continue

			var end_ui = node_ui_instances[connected_id]
			var end_pos = end_ui.position + NODE_SIZE / 2.0

			# Draw line on path_lines control
			path_lines.draw_line(start_pos, end_pos, PATH_COLOR, PATH_WIDTH)
