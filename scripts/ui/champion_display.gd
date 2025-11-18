extends Control
class_name ChampionDisplay

# ============================================================================
# SCENE STRUCTURE:
# ChampionDisplay (Control)
# ├── VBoxContainer (main layout)
# │   ├── HBoxContainer (header - portrait + info)
# │   │   ├── ColorRect (portrait)
# │   │   └── VBoxContainer (champion info)
# │   │       ├── Label (name)
# │   │       ├── HBoxContainer (HP section)
# │   │       │   ├── ProgressBar (hp_bar)
# │   │       │   └── Label (hp_text)
# │   │       └── Label (block_indicator)
# │   ├── HBoxContainer (status_icons)
# │   └── HBoxContainer (action_buttons)
# │       ├── Button (attack_button)
# │       └── Button (defend_button)
# ============================================================================

# Properties
var champion: Champion
var champion_index: int = -1
var is_highlighted: bool = false
var has_acted: bool = false

# Queued action properties
var queued_action_type: String = ""  # "card", "attack", or "defend"
var queued_card_id: String = ""
var queued_card_name: String = ""

# Visual element references
@onready var highlight_border: Panel = $HighlightBorder
@onready var portrait: ColorRect = $VBoxContainer/HeaderContainer/Portrait
@onready var name_label: Label = $VBoxContainer/HeaderContainer/ChampionInfoContainer/NameLabel
@onready var hp_bar: ProgressBar = $VBoxContainer/HeaderContainer/ChampionInfoContainer/HPSection/HPBar
@onready var hp_text: Label = $VBoxContainer/HeaderContainer/ChampionInfoContainer/HPSection/HPText
@onready var block_indicator: Label = $VBoxContainer/HeaderContainer/ChampionInfoContainer/BlockIndicator
@onready var queued_action_label: Label = $VBoxContainer/HeaderContainer/ChampionInfoContainer/QueuedActionLabel
@onready var status_icons_container: HBoxContainer = $VBoxContainer/StatusIconsContainer
@onready var attack_button: Button = $VBoxContainer/ActionButtonsContainer/AttackButton
@onready var defend_button: Button = $VBoxContainer/ActionButtonsContainer/DefendButton

# Signals
# signal champion_selected(champion_index: int)  # Currently unused
signal attack_pressed(champion_index: int)
signal defend_pressed(champion_index: int)
signal champion_clicked_for_targeting(champion_index: int)

# Constants
const DEFAULT_PORTRAIT_COLOR = Color.WHITE
const HIGHLIGHT_COLOR = Color.YELLOW
const HIGHLIGHT_MODULATE = Color(1.5, 1.5, 1.0)
const ACTED_MODULATE = Color(0.5, 0.5, 0.5)


func _ready() -> void:
	# Connect button signals
	attack_button.pressed.connect(_on_attack_button_pressed)
	defend_button.pressed.connect(_on_defend_button_pressed)

	# Connect portrait click for targeting
	portrait.gui_input.connect(_on_portrait_gui_input)

	# Initialize display as empty
	_initialize_empty_display()


func _initialize_empty_display() -> void:
	"""Initialize display with no champion selected."""
	name_label.text = "Empty"
	hp_bar.value = 0
	hp_bar.max_value = 1
	hp_text.text = "0/0"
	block_indicator.text = ""
	block_indicator.visible = false
	attack_button.disabled = true
	defend_button.disabled = true
	portrait.color = DEFAULT_PORTRAIT_COLOR


func initialize(champ: Champion, index: int) -> void:
	"""
	Initialize the display with a champion reference.

	Args:
		champ: Reference to the Champion object
		index: The index of this champion in the battle
	"""
	champion = champ
	champion_index = index
	has_acted = false
	is_highlighted = false

	# Setup portrait color based on champion (can be extended)
	if champion.has_meta("display_color"):
		portrait.color = champion.get_meta("display_color")
	else:
		portrait.color = DEFAULT_PORTRAIT_COLOR

	# Update all visual elements
	update_display()

	# Enable action buttons
	attack_button.disabled = false
	defend_button.disabled = false


func update_display() -> void:
	"""Refresh all visual elements to match champion's current state."""
	if champion == null:
		_initialize_empty_display()
		return

	# Update name
	name_label.text = str(champion.champion_name) if champion.champion_name else "Champion"

	# Update HP bar and text
	var current_hp = champion.current_hp if champion.current_hp > 0 else 0
	var max_hp = champion.max_hp if champion.max_hp > 0 else 1

	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_text.text = "%d/%d" % [current_hp, max_hp]

	# Update block indicator
	var block_value = champion.block if champion.has_method("get_block") else 0
	if block_value > 0:
		block_indicator.text = "Block: %d" % block_value
		block_indicator.visible = true
	else:
		block_indicator.visible = false

	# Update status icons
	_update_status_icons()

	# Update button states based on champion state
	_update_button_states()


func set_highlighted(value: bool, highlight_color: Color = HIGHLIGHT_COLOR) -> void:
	"""
	Show or hide targeting highlight with optional custom color.

	Args:
		value: True to highlight, False to remove highlight
		highlight_color: Color for the highlight border (defaults to yellow)
	"""
	is_highlighted = value

	if is_highlighted and highlight_border:
		# Make border visible with the specified color
		var style_box = highlight_border.get_theme_stylebox("panel")
		if style_box is StyleBoxFlat:
			style_box.border_color = highlight_color
			# Make border visible by setting alpha to 1
			var visible_color = Color(highlight_color.r, highlight_color.g, highlight_color.b, 1.0)
			style_box.border_color = visible_color
	elif highlight_border:
		# Hide border by making it transparent
		var style_box = highlight_border.get_theme_stylebox("panel")
		if style_box is StyleBoxFlat:
			style_box.border_color = Color(1, 1, 0, 0)  # Transparent


func set_acted(value: bool) -> void:
	"""
	Gray out the display if the champion has acted.

	Args:
		value: True if champion has acted, False otherwise
	"""
	has_acted = value
	_update_button_states()


func _update_status_icons() -> void:
	"""Update status effect icons in the container."""
	# Clear existing status icons
	for child in status_icons_container.get_children():
		child.queue_free()

	if champion == null or not champion.has_method("get_status_effects"):
		return

	var status_effects = champion.get_status_effects()

	for status in status_effects:
		var status_icon = Label.new()
		status_icon.text = _get_status_icon(status)
		status_icon.tooltip_text = status
		status_icons_container.add_child(status_icon)


func _get_status_icon(status: String) -> String:
	"""Get icon representation for a status effect."""
	match status.to_lower():
		"regen":
			return "+"
		"poison":
			return "P"
		"stun":
			return "S"
		"haste":
			return "H"
		"weakness":
			return "W"
		_:
			return "?"


func _update_button_states() -> void:
	"""Update button appearance based on champion state."""
	if has_acted or champion == null:
		portrait.modulate = ACTED_MODULATE
		attack_button.disabled = true
		defend_button.disabled = true
	else:
		portrait.modulate = Color.WHITE
		attack_button.disabled = false
		defend_button.disabled = false


func _on_attack_button_pressed() -> void:
	"""Handle attack button press."""
	if champion == null:
		return

	# Queue attack action and get any replaced card
	var replaced_card_id = queue_attack_action()

	# If a card was replaced, return it to hand
	if replaced_card_id != "":
		_return_card_to_hand(replaced_card_id)

	# Enter targeting mode to select enemy
	var battle_scene = get_tree().current_scene
	if battle_scene:
		var hand_ui = battle_scene.get_node_or_null("Hand")
		if hand_ui and hand_ui.has_method("enter_targeting_mode"):
			# Attack targets a single enemy
			hand_ui.current_champion_index = champion_index
			hand_ui.current_card_id = "basic_attack"  # Placeholder ID for attack action
			hand_ui.enter_targeting_mode(null, "single_enemy")

	# Emit signal for any listeners (optional)
	attack_pressed.emit(champion_index)


func _on_defend_button_pressed() -> void:
	"""Handle defend button press."""
	if champion == null:
		return

	# Queue defend action and get any replaced card
	var replaced_card_id = queue_defend_action()

	# If a card was replaced, return it to hand
	if replaced_card_id != "":
		_return_card_to_hand(replaced_card_id)

	# Defend doesn't need targeting - it's a self-action
	# Store empty targets
	var battle_scene = get_tree().current_scene
	if battle_scene:
		var hand_ui = battle_scene.get_node_or_null("Hand")
		if hand_ui:
			# Store that defend has been confirmed (no targets needed)
			set_meta("queued_targets", [])

	# Emit signal for any listeners (optional)
	defend_pressed.emit(champion_index)


func _return_card_to_hand(card_id: String) -> void:
	"""Helper to return a card to the player's hand."""
	var battle_scene = get_tree().current_scene
	if battle_scene:
		var hand_ui = battle_scene.get_node_or_null("Hand")
		if hand_ui and hand_ui.has_method("add_card_to_hand"):
			hand_ui.add_card_to_hand(card_id)


func _on_portrait_gui_input(event: InputEvent) -> void:
	"""
	Handle mouse clicks on the portrait for targeting.

	Args:
		event: The input event
	"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if champion != null:
			champion_clicked_for_targeting.emit(champion_index)


func queue_card_action(card_id: String, card_name: String) -> String:
	"""
	Queue a card to be played by this champion.
	Returns the previously queued card_id if one existed (so it can be returned to hand).

	Args:
		card_id: The ID of the card to play
		card_name: The display name of the card

	Returns:
		The card_id of the previously queued card, or empty string
	"""
	var previous_card_id = ""

	# If there's already a card queued, return its ID
	if queued_action_type == "card" and queued_card_id != "":
		previous_card_id = queued_card_id

	queued_action_type = "card"
	queued_card_id = card_id
	queued_card_name = card_name

	# Update queued action display
	if queued_action_label:
		queued_action_label.text = "Card: %s" % card_name
		queued_action_label.visible = true

	# Show border when action is queued
	var card_data = CardDatabase.get_card_data(card_id) if CardDatabase else {}
	var champion_id = card_data.get("champion", "")
	var card_color = _get_card_color(champion_id)
	set_highlighted(true, card_color)

	return previous_card_id


func queue_attack_action() -> String:
	"""
	Queue an attack action for this champion.
	Returns the previously queued card_id if one existed.
	"""
	var previous_card_id = ""

	# If there's a card queued, return its ID
	if queued_action_type == "card" and queued_card_id != "":
		previous_card_id = queued_card_id

	queued_action_type = "attack"
	queued_card_id = ""
	queued_card_name = ""

	if queued_action_label:
		queued_action_label.text = "⚔ Attack"
		queued_action_label.visible = true

	# Highlight attack button
	if attack_button:
		attack_button.modulate = Color(1.3, 1.3, 1.0)

	set_highlighted(true, Color(1.0, 0.3, 0.3))  # Red for attack

	return previous_card_id


func queue_defend_action() -> String:
	"""
	Queue a defend action for this champion.
	Returns the previously queued card_id if one existed.
	"""
	var previous_card_id = ""

	# If there's a card queued, return its ID
	if queued_action_type == "card" and queued_card_id != "":
		previous_card_id = queued_card_id

	queued_action_type = "defend"
	queued_card_id = ""
	queued_card_name = ""

	if queued_action_label:
		queued_action_label.text = "🛡 Defend"
		queued_action_label.visible = true

	# Highlight defend button
	if defend_button:
		defend_button.modulate = Color(1.0, 1.3, 1.3)

	set_highlighted(true, Color(0.3, 0.6, 1.0))  # Blue for defend

	return previous_card_id


func clear_queued_action() -> void:
	"""Clear any queued action for this champion."""
	queued_action_type = ""
	queued_card_id = ""
	queued_card_name = ""

	if queued_action_label:
		queued_action_label.visible = false
		queued_action_label.text = ""

	# Reset button highlights
	if attack_button:
		attack_button.modulate = Color.WHITE
	if defend_button:
		defend_button.modulate = Color.WHITE

	# Clear border
	set_highlighted(false)


func get_queued_action() -> Dictionary:
	"""
	Get the currently queued action.

	Returns:
		Dictionary with keys: type, card_id, card_name
	"""
	return {
		"type": queued_action_type,
		"card_id": queued_card_id,
		"card_name": queued_card_name
	}


func _get_card_color(champion_id: String) -> Color:
	"""Get color for a champion's card."""
	var colors = {
		"warrior": Color(1.0, 0.2, 0.2),      # Red
		"defender": Color(0.2, 0.4, 1.0),    # Blue
		"healer": Color(0.2, 1.0, 0.2),      # Green
		"fire_knight": Color(1.0, 0.6, 0.2)  # Orange
	}
	return colors.get(champion_id, Color.YELLOW)
