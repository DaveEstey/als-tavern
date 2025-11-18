extends Control

# Hand UI Manager
# Manages the player's hand of cards and handles the targeting flow
#
# Scene Structure:
#   HandUI (Control) - This script
#   ├── CardsContainer (HBoxContainer) - Holds card UI instances
#   └── [Card UI nodes dynamically added]
#
# Targeting Flow:
# 1. Card dragged onto champion → enter_targeting_mode()
# 2. Highlight valid targets based on card's target_type
# 3. Player clicks enemy/ally → _on_champion_clicked() or _on_enemy_clicked()
# 4. If target_type is "all_enemies" or "all_allies", auto-execute without click
# 5. card_play_requested signal emitted with card_id, champion_index, target_indices

# Signals
signal card_play_requested(card_id: String, champion_index: int, target_indices: Array[int])

# Exported/Inspector properties
@export var card_ui_scene: PackedScene = preload("res://scenes/ui/card_ui.tscn")

# Card fan layout parameters
@export var max_rotation: float = 0.15  # Maximum rotation in radians at edges
@export var arc_height: float = 40.0    # Height of the arc curve
@export var card_spacing: float = 100.0 # Base spacing between cards
@export var max_card_spacing: float = 140.0  # Maximum spacing to prevent cards from being too far apart

# References (no longer using HBoxContainer)
# Cards are added directly to this Control node

# State properties
var current_cards: Array[Control] = []
var selected_card: Control = null
var targeting_mode: bool = false
var target_type: String = ""
var current_champion_index: int = -1
var current_card_id: String = ""


func _ready() -> void:
	# Cards are now added directly to this Control node
	# Allow cards to render outside hand bounds for arc effect
	clip_contents = false


# Clear all cards from the hand
func clear_hand() -> void:
	for card_ui in current_cards:
		card_ui.queue_free()
	current_cards.clear()
	selected_card = null
	exit_targeting_mode()


# Add a card UI to the hand
# card_id: The unique identifier for the card
func add_card_to_hand(card_id: String) -> void:
	if not card_ui_scene:
		push_error("card_ui_scene not set in HandUI. Ensure card_ui_scene is assigned in inspector or preloaded.")
		return

	var card_ui: Control = card_ui_scene.instantiate()
	add_child(card_ui)  # Add directly to Hand Control, not CardsContainer
	current_cards.append(card_ui)

	# Initialize card with data
	if card_ui.has_method("initialize"):
		card_ui.initialize(card_id)

	# Connect card signals
	if card_ui.has_signal("card_dropped"):
		card_ui.card_dropped.connect(_on_card_dropped)

	# Arrange all cards in fan layout
	_arrange_cards()


# Remove a card UI from the hand by card ID
# card_id: The unique identifier for the card to remove
func remove_card_from_hand(card_id: String) -> void:
	for i in range(current_cards.size() - 1, -1, -1):
		var card_ui = current_cards[i]
		# Match by card_id using the get_card_id() method
		if card_ui.has_method("get_card_id") and card_ui.get_card_id() == card_id:
			card_ui.queue_free()
			current_cards.remove_at(i)
			break

	if selected_card and not selected_card.is_node_valid():
		selected_card = null

	if targeting_mode:
		exit_targeting_mode()

	# Rearrange remaining cards
	_arrange_cards()


# Update the hand with a new list of card IDs
# card_ids: Array of card IDs to display
func update_hand(card_ids: Array) -> void:
	clear_hand()
	for card_id in card_ids:
		add_card_to_hand(card_id)


# Handle card being dropped onto a champion
# Called when a card is dragged and dropped onto a champion
# card_id: The card being played
# champion_index: The index of the champion who will play the card
# target_indices: The target indices (empty array if targeting mode needed)
func _on_card_dropped(card_id: String, champion_index: int, target_indices: Array[int]) -> void:
	current_champion_index = champion_index
	current_card_id = card_id

	# Get target_type from card data
	var card_data: Dictionary = CardDatabase.get_card_data(card_id)
	var card_target_type: String = card_data.get("target_type", "single_enemy")

	# For single target types, enter targeting mode
	if target_indices.is_empty() and card_target_type not in ["all_enemies", "all_allies"]:
		enter_targeting_mode(selected_card, card_target_type)
	else:
		# For all targets types or if targets already selected, execute immediately
		card_play_requested.emit(card_id, champion_index, target_indices)
		exit_targeting_mode()


# Enter targeting mode for a card
# card: The card UI instance being targeted
# target_type: The type of targets (single_enemy, all_enemies, single_ally, all_allies, etc.)
func enter_targeting_mode(card: Control, target_type_param: String) -> void:
	if targeting_mode:
		exit_targeting_mode()

	targeting_mode = true
	target_type = target_type_param
	selected_card = card

	# Highlight valid targets based on target_type
	_highlight_valid_targets()

	# If targeting all enemies or all allies, auto-execute
	if target_type in ["all_enemies", "all_allies"]:
		_auto_execute_all_targets()


# Exit targeting mode
func exit_targeting_mode() -> void:
	targeting_mode = false
	target_type = ""
	selected_card = null
	current_champion_index = -1
	current_card_id = ""

	# TODO: Clear highlighting when champion/enemy display systems are ready
	# _clear_target_highlighting()


# Handle ally/champion being clicked during targeting
# champion_index: The index of the champion clicked
func _on_champion_clicked(champion_index: int) -> void:
	if not targeting_mode:
		return

	# Only allow targeting allies if target_type requires it
	if target_type in ["single_ally", "all_allies"]:
		var target_indices: Array[int] = [champion_index]
		card_play_requested.emit(current_card_id, current_champion_index, target_indices)
		exit_targeting_mode()


# Handle enemy being clicked during targeting
# enemy_index: The index of the enemy clicked
func _on_enemy_clicked(enemy_index: int) -> void:
	if not targeting_mode:
		return

	# Only allow targeting enemies if target_type requires it
	if target_type in ["single_enemy", "all_enemies"]:
		var target_indices: Array[int] = [enemy_index]
		card_play_requested.emit(current_card_id, current_champion_index, target_indices)
		exit_targeting_mode()


# Highlight valid targets based on target_type
# TODO: Integrate with champion_display.gd and enemy_display.gd
func _highlight_valid_targets() -> void:
	match target_type:
		"single_enemy":
			# Highlight all enemies
			pass
		"all_enemies":
			# Highlight all enemies
			pass
		"single_ally":
			# Highlight all allies/champions
			pass
		"all_allies":
			# Highlight all allies/champions
			pass
		_:
			push_warning("Unknown target type: %s" % target_type)


# Auto-execute card targeting all targets
# Used when target_type is "all_enemies" or "all_allies"
func _auto_execute_all_targets() -> void:
	var target_indices: Array[int] = []

	match target_type:
		"all_enemies":
			# TODO: Get enemy count from battle manager
			var enemy_count: int = 0
			for i in range(enemy_count):
				target_indices.append(i)

		"all_allies":
			# TODO: Get champion count from battle manager
			var champion_count: int = 0
			for i in range(champion_count):
				target_indices.append(i)

	if not target_indices.is_empty():
		card_play_requested.emit(current_card_id, current_champion_index, target_indices)
		exit_targeting_mode()


# Clear target highlighting
# TODO: Integrate with champion_display.gd and enemy_display.gd
func _clear_target_highlighting() -> void:
	# Remove visual highlighting from all potential targets
	pass


# Get the card UI by card ID
# Returns null if card not found
func get_card_ui_by_id(card_id: String) -> Control:
	for card_ui in current_cards:
		# Match by card_id using the get_card_id() method
		if card_ui.has_method("get_card_id") and card_ui.get_card_id() == card_id:
			return card_ui
	return null


# Arrange cards in a fan layout
# Uses normalized positioning (-1 to 1) to create consistent fan shape
func _arrange_cards() -> void:
	var card_count = current_cards.size()
	if card_count == 0:
		return

	# Wait for Hand to be properly sized by layout system
	# Use get_rect() which is more reliable than size property during initialization
	await get_tree().process_frame

	# Get hand dimensions - use get_rect() to ensure we have correct size
	var hand_rect = get_rect()
	var hand_width = hand_rect.size.x
	var hand_height = hand_rect.size.y

	# If still zero, use the offset-based dimensions as fallback
	if hand_width == 0 or hand_height == 0:
		print("HandUI: Warning - Hand size still zero, using fallback dimensions")
		# From battle_scene.tscn: offset_right (1040) - offset_left (240) = 800
		hand_width = 800.0
		hand_height = 180.0

	print("HandUI: Arranging %d cards in hand (size: %.0fx%.0f)" % [card_count, hand_width, hand_height])

	var hand_center_x = hand_width / 2.0
	var hand_center_y = hand_height / 2.0

	# Calculate spacing (limit to max_card_spacing)
	var spacing = min(card_spacing, max_card_spacing)
	if card_count > 1:
		# Adjust spacing based on available width
		var total_width_needed = (card_count - 1) * card_spacing
		var available_width = hand_width - 140  # Leave margins (card width is ~120)
		if total_width_needed > available_width:
			spacing = available_width / (card_count - 1)

	# Position each card
	for i in range(card_count):
		var card = current_cards[i]

		# Normalize position from -1 to 1 (0 is center)
		var t: float = 0.0
		if card_count > 1:
			t = (float(i) / float(card_count - 1)) * 2.0 - 1.0

		# Calculate horizontal position
		var x_offset = t * spacing * (card_count - 1) / 2.0
		var card_x = hand_center_x + x_offset - 60.0  # 60 is half card width

		# Calculate arc offset (parabolic curve - makes middle cards higher)
		var arc_offset = -arc_height * (t * t) + arc_height
		var card_y = hand_center_y - arc_offset - 90.0  # 90 is half card height

		# Calculate rotation (fan effect)
		var rotation_angle = t * max_rotation

		# Set card transform
		card.position = Vector2(card_x, card_y)
		card.rotation = rotation_angle

		# Debug: Print card position
		if i == 0:  # Only print first card to avoid spam
			print("  Card %d positioned at: %v, rotation: %.2f" % [i, card.position, rotation_angle])

		# Store base position for drag/drop (if card has this method)
		if card.has_method("set_base_transform"):
			card.set_base_transform(Vector2(card_x, card_y), rotation_angle)
