extends Control

## Rest UI - Map Node Interaction
## Allows players to heal all champions to full HP or upgrade a single card
## Players must choose one option - both cannot be taken at the same rest site

# ========================================
# SCENE STRUCTURE
# ========================================
# RestUI (Control)
# ├── Panel (Panel) - Main background
# │   ├── MarginContainer
# │   │   ├── VBoxContainer
# │   │   │   ├── HeaderContainer (HBoxContainer)
# │   │   │   │   ├── TitleLabel (Label) - "Rest Site"
# │   │   │   │   ├── Spacer (Control) - size_flags_horizontal = EXPAND
# │   │   │   │   ├── GoldLabel (Label) - "Gold: 100"
# │   │   │   │   └── CloseButton (Button) - "X"
# │   │   │   ├── HSeparator
# │   │   │   ├── DescriptionLabel (Label) - "Choose to rest or improve"
# │   │   │   ├── OptionsContainer (HBoxContainer) - size_flags_vertical = EXPAND
# │   │   │   │   ├── HealOption (Panel) - Left option
# │   │   │   │   │   ├── MarginContainer
# │   │   │   │   │   │   ├── VBoxContainer
# │   │   │   │   │   │   │   ├── OptionIcon (TextureRect)
# │   │   │   │   │   │   │   ├── OptionTitle (Label) - "Heal"
# │   │   │   │   │   │   │   ├── OptionDescription (Label)
# │   │   │   │   │   │   │   ├── Spacer
# │   │   │   │   │   │   │   └── HealButton (Button) - "Heal All Champions"
# │   │   │   │   │   VSeparator
# │   │   │   │   │   ├── UpgradeOption (Panel) - Right option
# │   │   │   │   │   │   ├── MarginContainer
# │   │   │   │   │   │   │   ├── VBoxContainer
# │   │   │   │   │   │   │   │   ├── OptionIcon (TextureRect)
# │   │   │   │   │   │   │   │   ├── OptionTitle (Label) - "Upgrade"
# │   │   │   │   │   │   │   │   ├── OptionDescription (Label)
# │   │   │   │   │   │   │   │   ├── CardsScrollContainer (ScrollContainer)
# │   │   │   │   │   │   │   │   │   └── CardsVBox (VBoxContainer)
# │   │   │   │   │   │   │   │   │       └── [Card buttons added dynamically]
# │   │   │   │   │   │   │   │   └── UpgradeInfoLabel (Label)
# │   │   │   ├── HSeparator
# │   │   │   └── FooterContainer (HBoxContainer)
# │   │   │       ├── StatusLabel (Label) - "Choose wisely - you can only pick one"
# │   │   │       └── Spacer
# ========================================

# Signals
signal rest_action_taken(action_type: String, data: Dictionary)
signal rest_closed()

# Node references
@onready var gold_label: Label = $Panel/MarginContainer/VBoxContainer/HeaderContainer/GoldLabel
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/HeaderContainer/CloseButton
@onready var heal_button: Button = $Panel/MarginContainer/VBoxContainer/OptionsContainer/HealOption/MarginContainer/VBoxContainer/HealButton
@onready var cards_vbox: VBoxContainer = $Panel/MarginContainer/VBoxContainer/OptionsContainer/UpgradeOption/MarginContainer/VBoxContainer/CardsScrollContainer/CardsVBox
@onready var status_label: Label = $Panel/MarginContainer/VBoxContainer/FooterContainer/StatusLabel
@onready var upgrade_info_label: Label = $Panel/MarginContainer/VBoxContainer/OptionsContainer/UpgradeOption/MarginContainer/VBoxContainer/UpgradeInfoLabel
@onready var heal_option_panel: Panel = $Panel/MarginContainer/VBoxContainer/OptionsContainer/HealOption
@onready var upgrade_option_panel: Panel = $Panel/MarginContainer/VBoxContainer/OptionsContainer/UpgradeOption

# Card structure for upgrade options
class UpgradeCard:
	var id: String
	var name: String
	var current_level: int
	var description: String
	var upgrade_preview: String

	func _init(p_id: String, p_name: String, p_level: int, p_desc: String, p_preview: String) -> void:
		id = p_id
		name = p_name
		current_level = p_level
		description = p_desc
		upgrade_preview = p_preview

# Properties
var upgrade_options: Array[UpgradeCard] = []
var player_gold: int = 0
var action_taken: bool = false
var selected_action_type: String = ""  # "heal" or "upgrade"

# ========================================
# LIFECYCLE METHODS
# ========================================

func _ready() -> void:
	_setup_connections()
	_populate_upgrade_options()
	update_gold_display()
	_update_status_message()

func _setup_connections() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	if heal_button:
		heal_button.pressed.connect(_on_heal_pressed)

# ========================================
# INITIALIZATION
# ========================================

func _populate_upgrade_options() -> void:
	"""Populate the cards available for upgrade"""
	if not cards_vbox:
		push_error("RestUI: CardsVBox node not found!")
		return

	# Clear existing cards
	for child in cards_vbox.get_children():
		child.queue_free()

	if upgrade_options.is_empty():
		var no_cards_label: Label = Label.new()
		no_cards_label.text = "No cards available for upgrade"
		no_cards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_cards_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		cards_vbox.add_child(no_cards_label)
		if upgrade_info_label:
			upgrade_info_label.text = "No upgradeable cards found"
		return

	# Create a button for each upgradeable card
	for card in upgrade_options:
		var card_panel: Panel = _create_upgrade_card_panel(card)
		cards_vbox.add_child(card_panel)

	if upgrade_info_label:
		upgrade_info_label.text = "Select a card to upgrade (1/" + str(upgrade_options.size()) + ")"

func _create_upgrade_card_panel(card: UpgradeCard) -> Panel:
	"""Create a visual panel for an upgradeable card"""
	var panel: Panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 100)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Card name with level
	var name_label: Label = Label.new()
	name_label.text = card.name + " (Lv." + str(card.current_level) + ")"
	name_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(name_label)

	# Current description
	var desc_label: Label = Label.new()
	desc_label.text = card.description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Upgrade preview
	var preview_label: Label = Label.new()
	preview_label.text = "→ " + card.upgrade_preview
	preview_label.add_theme_font_size_override("font_size", 11)
	preview_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(preview_label)

	# Upgrade button
	var upgrade_btn: Button = Button.new()
	upgrade_btn.text = "Upgrade This Card"
	upgrade_btn.disabled = action_taken
	upgrade_btn.pressed.connect(_on_upgrade_pressed.bind(card.id))
	vbox.add_child(upgrade_btn)

	return panel

# ========================================
# ACTION HANDLERS
# ========================================

func _on_heal_pressed() -> void:
	"""Handle heal action - restore all champions to full HP"""
	if action_taken:
		_update_status_message("You already chose an option!", Color.ORANGE)
		return

	action_taken = true
	selected_action_type = "heal"

	# Disable all options
	_disable_all_options()

	# Show feedback
	_update_status_message("All champions healed to full HP!", Color.GREEN)

	# Emit signal with heal action data
	var action_data: Dictionary = {
		"heal_amount": "full",
		"timestamp": Time.get_unix_time_from_system()
	}
	rest_action_taken.emit("heal", action_data)

	print("RestUI: Heal action taken - All champions restored to full HP")

	# Auto-close after a short delay
	await get_tree().create_timer(1.5).timeout
	close_rest()

func _on_upgrade_pressed(card_id: String) -> void:
	"""Handle card upgrade action"""
	if action_taken:
		_update_status_message("You already chose an option!", Color.ORANGE)
		return

	# Find the card
	var selected_card: UpgradeCard = null
	for card in upgrade_options:
		if card.id == card_id:
			selected_card = card
			break

	if not selected_card:
		push_error("RestUI: Card ID not found: " + card_id)
		return

	action_taken = true
	selected_action_type = "upgrade"

	# Disable all options
	_disable_all_options()

	# Show feedback
	_update_status_message("Upgraded: " + selected_card.name + "!", Color.GREEN)

	# Emit signal with upgrade data
	var action_data: Dictionary = {
		"card_id": selected_card.id,
		"card_name": selected_card.name,
		"previous_level": selected_card.current_level,
		"new_level": selected_card.current_level + 1
	}
	rest_action_taken.emit("upgrade", action_data)

	print("RestUI: Upgrade action taken - Card: ", selected_card.name, " upgraded to level ", selected_card.current_level + 1)

	# Auto-close after a short delay
	await get_tree().create_timer(1.5).timeout
	close_rest()

# ========================================
# UI UPDATES
# ========================================

func _disable_all_options() -> void:
	"""Disable all action buttons after an action is taken"""
	if heal_button:
		heal_button.disabled = true

	# Disable all upgrade buttons
	if cards_vbox:
		for child in cards_vbox.get_children():
			if child is Panel:
				var buttons = _find_buttons_recursive(child)
				for button in buttons:
					button.disabled = true

func _find_buttons_recursive(node: Node) -> Array[Button]:
	"""Recursively find all Button nodes"""
	var buttons: Array[Button] = []
	for child in node.get_children():
		if child is Button:
			buttons.append(child)
		buttons.append_array(_find_buttons_recursive(child))
	return buttons

func update_gold_display() -> void:
	"""Update the gold label with current player gold"""
	if gold_label:
		gold_label.text = "Gold: " + str(player_gold)

func _update_status_message(message: String = "", color: Color = Color.WHITE) -> void:
	"""Update the status label"""
	if not status_label:
		return

	if message.is_empty():
		if action_taken:
			status_label.text = "Action completed - Rest site will close shortly"
		else:
			status_label.text = "Choose wisely - you can only pick one option"
		status_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		status_label.text = message
		status_label.add_theme_color_override("font_color", color)

# ========================================
# PUBLIC API
# ========================================

func set_player_gold(amount: int) -> void:
	"""Set the player's current gold amount"""
	player_gold = max(0, amount)
	update_gold_display()

func set_upgrade_options(cards: Array) -> void:
	"""Set the cards available for upgrade
	Expected format: Array of dictionaries with keys: id, name, level, description, upgrade_preview
	"""
	upgrade_options.clear()

	for card_data in cards:
		if not (card_data is Dictionary):
			push_warning("RestUI: Invalid card data format, expected Dictionary")
			continue

		var card_id: String = card_data.get("id", "")
		var card_name: String = card_data.get("name", "Unknown Card")
		var card_level: int = card_data.get("level", 1)
		var card_desc: String = card_data.get("description", "")
		var upgrade_preview: String = card_data.get("upgrade_preview", "Enhanced version")

		var upgrade_card := UpgradeCard.new(card_id, card_name, card_level, card_desc, upgrade_preview)
		upgrade_options.append(upgrade_card)

	_populate_upgrade_options()

func add_upgrade_option(card_id: String, card_name: String, level: int, description: String, upgrade_preview: String) -> void:
	"""Add a single card to the upgrade options"""
	var card := UpgradeCard.new(card_id, card_name, level, description, upgrade_preview)
	upgrade_options.append(card)
	_populate_upgrade_options()

func get_action_taken() -> bool:
	"""Check if an action has been taken"""
	return action_taken

func get_selected_action() -> String:
	"""Get the type of action taken ('heal' or 'upgrade')"""
	return selected_action_type

# ========================================
# CLOSE HANDLING
# ========================================

func close_rest() -> void:
	"""Close the rest site and emit signal"""
	rest_closed.emit()
	queue_free()

func _on_close_button_pressed() -> void:
	"""Handle close button press"""
	if not action_taken:
		_update_status_message("Leaving without resting...", Color.YELLOW)
		await get_tree().create_timer(0.5).timeout

	close_rest()
