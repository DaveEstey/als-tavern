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
@export var card_ui_scene: PackedScene  # Should be preloaded with: preload("res://scenes/ui/card_ui.tscn")

# References
@onready var cards_container: HBoxContainer = %CardsContainer

# State properties
var current_cards: Array[Control] = []
var selected_card: Control = null
var targeting_mode: bool = false
var target_type: String = ""
var current_champion_index: int = -1


func _ready() -> void:
	# Verify cards_container exists
	if not cards_container:
		push_error("CardsContainer not found in HandUI scene. Ensure it's named 'CardsContainer' with a UniqueNameInOwner.")


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
	cards_container.add_child(card_ui)
	current_cards.append(card_ui)

	# TODO: Connect card_ui signals when card_ui.gd is ready
	# card_ui.card_selected.connect(_on_card_selected.bind(card_ui))
	# card_ui.card_dropped.connect(_on_card_dropped.bind(card_id))


# Remove a card UI from the hand by card ID
# card_id: The unique identifier for the card to remove
func remove_card_from_hand(card_id: String) -> void:
	for i in range(current_cards.size() - 1, -1, -1):
		var card_ui = current_cards[i]
		# TODO: Match by card_id when card_ui stores this information
		# if card_ui.card_id == card_id:
		card_ui.queue_free()
		current_cards.remove_at(i)
		break

	if selected_card and not selected_card.is_node_valid():
		selected_card = null

	if targeting_mode:
		exit_targeting_mode()


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

	# TODO: Get target_type from card data
	var card_target_type: String = "single_enemy"  # Placeholder

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

	# TODO: Clear highlighting when champion/enemy display systems are ready
	# _clear_target_highlighting()


# Handle ally/champion being clicked during targeting
# champion_index: The index of the champion clicked
func _on_champion_clicked(champion_index: int) -> void:
	if not targeting_mode:
		return

	# Only allow targeting allies if target_type requires it
	if target_type in ["single_ally", "all_allies"]:
		if selected_card:
			# TODO: Get card_id from selected_card
			var card_id: String = ""  # Placeholder
			var target_indices: Array[int] = [champion_index]
			card_play_requested.emit(card_id, current_champion_index, target_indices)
			exit_targeting_mode()


# Handle enemy being clicked during targeting
# enemy_index: The index of the enemy clicked
func _on_enemy_clicked(enemy_index: int) -> void:
	if not targeting_mode:
		return

	# Only allow targeting enemies if target_type requires it
	if target_type in ["single_enemy", "all_enemies"]:
		if selected_card:
			# TODO: Get card_id from selected_card
			var card_id: String = ""  # Placeholder
			var target_indices: Array[int] = [enemy_index]
			card_play_requested.emit(card_id, current_champion_index, target_indices)
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

	if selected_card and not target_indices.is_empty():
		# TODO: Get card_id from selected_card
		var card_id: String = ""  # Placeholder
		card_play_requested.emit(card_id, current_champion_index, target_indices)
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
		# TODO: Match by card_id when card_ui stores this information
		# if card_ui.card_id == card_id:
		#	return card_ui
		pass
	return null
