extends Control

## Shrine UI - Map Node Interaction
## Allows players to choose one blessing from three random options
## Blessings provide temporary buffs for the next battle

# ========================================
# SCENE STRUCTURE
# ========================================
# ShrineUI (Control)
# ├── Panel (Panel) - Main background with mystical theme
# │   ├── MarginContainer
# │   │   ├── VBoxContainer
# │   │   │   ├── HeaderContainer (HBoxContainer)
# │   │   │   │   ├── TitleLabel (Label) - "Ancient Shrine"
# │   │   │   │   ├── Spacer (Control) - size_flags_horizontal = EXPAND
# │   │   │   │   ├── GoldLabel (Label) - "Gold: 100"
# │   │   │   │   └── CloseButton (Button) - "X"
# │   │   │   ├── HSeparator
# │   │   │   ├── DescriptionLabel (Label) - "The shrine offers its blessings"
# │   │   │   ├── BlessingsContainer (HBoxContainer) - size_flags_vertical = EXPAND
# │   │   │   │   ├── Blessing1Panel (Panel)
# │   │   │   │   │   ├── MarginContainer
# │   │   │   │   │   │   ├── VBoxContainer
# │   │   │   │   │   │   │   ├── IconContainer (CenterContainer)
# │   │   │   │   │   │   │   │   └── BlessingIcon (Label) - emoji/symbol
# │   │   │   │   │   │   │   ├── BlessingName (Label)
# │   │   │   │   │   │   │   ├── BlessingDescription (Label)
# │   │   │   │   │   │   │   ├── Spacer
# │   │   │   │   │   │   │   └── ChooseButton (Button) - "Choose Blessing"
# │   │   │   │   │   ├── Blessing2Panel (Panel) - same structure
# │   │   │   │   │   └── Blessing3Panel (Panel) - same structure
# │   │   │   ├── HSeparator
# │   │   │   └── FooterContainer (HBoxContainer)
# │   │   │       ├── StatusLabel (Label) - "Choose one blessing for your next battle"
# │   │   │       └── Spacer
# ========================================

# Signals
signal blessing_chosen(blessing_type: String, blessing_data: Dictionary)
signal shrine_closed()

# Node references
@onready var gold_label: Label = $Panel/MarginContainer/VBoxContainer/HeaderContainer/GoldLabel
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/HeaderContainer/CloseButton
@onready var blessings_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/BlessingsContainer
@onready var status_label: Label = $Panel/MarginContainer/VBoxContainer/FooterContainer/StatusLabel
@onready var description_label: Label = $Panel/MarginContainer/VBoxContainer/DescriptionLabel

# Blessing structure
class Blessing:
	var id: String
	var name: String
	var description: String
	var effect_type: String  # "damage", "health", "card_draw", etc.
	var effect_value: int
	var icon: String

	func _init(p_id: String, p_name: String, p_desc: String, p_type: String, p_value: int, p_icon: String) -> void:
		id = p_id
		name = p_name
		description = p_desc
		effect_type = p_type
		effect_value = p_value
		icon = p_icon

# All possible blessings
const ALL_BLESSINGS: Array[Dictionary] = [
	{
		"id": "blessing_damage",
		"name": "Warrior's Fury",
		"description": "Gain +5 damage to all attacks in your next battle. Strike with greater force!",
		"type": "damage",
		"value": 5,
		"icon": "⚔"
	},
	{
		"id": "blessing_health",
		"name": "Divine Protection",
		"description": "Gain +10 HP at the start of your next battle. Face danger with renewed vigor!",
		"type": "health",
		"value": 10,
		"icon": "❤"
	},
	{
		"id": "blessing_draw",
		"name": "Sage's Insight",
		"description": "Draw +2 additional cards at the start of your next battle. More options, more power!",
		"type": "card_draw",
		"value": 2,
		"icon": "📜"
	},
	{
		"id": "blessing_energy",
		"name": "Eternal Vigor",
		"description": "Start your next battle with +2 energy. Take more actions from the beginning!",
		"type": "energy",
		"value": 2,
		"icon": "✨"
	},
	{
		"id": "blessing_defense",
		"name": "Stone Skin",
		"description": "Gain +3 armor at the start of your next battle. Reduce incoming damage!",
		"type": "defense",
		"value": 3,
		"icon": "🛡"
	},
	{
		"id": "blessing_critical",
		"name": "Lucky Strike",
		"description": "Next battle: 25% chance for attacks to deal double damage. Fortune favors the bold!",
		"type": "critical",
		"value": 25,
		"icon": "🎲"
	},
	{
		"id": "blessing_healing",
		"name": "Regeneration",
		"description": "Heal 2 HP at the end of each turn during your next battle. Outlast your foes!",
		"type": "healing",
		"value": 2,
		"icon": "💚"
	},
	{
		"id": "blessing_first_strike",
		"name": "Swift Initiative",
		"description": "Take an extra turn at the start of your next battle. Strike before they can react!",
		"type": "first_strike",
		"value": 1,
		"icon": "⚡"
	}
]

# Properties
var available_blessings: Array[Blessing] = []
var player_gold: int = 0
var blessing_chosen_flag: bool = false
var blessing_panels: Array[Panel] = []

# ========================================
# LIFECYCLE METHODS
# ========================================

func _ready() -> void:
	_setup_connections()
	populate_blessings()
	update_gold_display()
	_update_status_message()

func _setup_connections() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

# ========================================
# BLESSINGS POPULATION
# ========================================

func populate_blessings() -> void:
	"""Generate 3 random blessings and display them"""
	if not blessings_container:
		push_error("ShrineUI: BlessingsContainer node not found!")
		return

	# Clear existing blessing panels
	for child in blessings_container.get_children():
		child.queue_free()
	blessing_panels.clear()

	# Generate 3 random unique blessings
	available_blessings = _generate_random_blessings(3)

	# Create a panel for each blessing
	for blessing in available_blessings:
		var blessing_panel: Panel = _create_blessing_panel(blessing)
		blessings_container.add_child(blessing_panel)
		blessing_panels.append(blessing_panel)

	if description_label:
		description_label.text = "The ancient shrine radiates with mystical energy. Choose your blessing wisely..."

func _generate_random_blessings(count: int) -> Array[Blessing]:
	"""Generate a specified number of random unique blessings"""
	var blessings: Array[Blessing] = []
	var available_indices: Array[int] = []

	# Create array of available indices
	for i in range(ALL_BLESSINGS.size()):
		available_indices.append(i)

	# Shuffle and pick
	available_indices.shuffle()

	for i in range(min(count, available_indices.size())):
		var blessing_data: Dictionary = ALL_BLESSINGS[available_indices[i]]
		var blessing := Blessing.new(
			blessing_data.id,
			blessing_data.name,
			blessing_data.description,
			blessing_data.type,
			blessing_data.value,
			blessing_data.icon
		)
		blessings.append(blessing)

	return blessings

func _create_blessing_panel(blessing: Blessing) -> Panel:
	"""Create a visual panel for a blessing option"""
	var panel: Panel = Panel.new()
	panel.custom_minimum_size = Vector2(200, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Icon container
	var icon_container: CenterContainer = CenterContainer.new()
	vbox.add_child(icon_container)

	var icon_label: Label = Label.new()
	icon_label.text = blessing.icon
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_container.add_child(icon_label)

	# Blessing name
	var name_label: Label = Label.new()
	name_label.text = blessing.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	# Effect type badge
	var type_label: Label = Label.new()
	type_label.text = _get_effect_type_display(blessing.effect_type)
	type_label.add_theme_font_size_override("font_size", 11)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_color_override("font_color", _get_effect_type_color(blessing.effect_type))
	vbox.add_child(type_label)

	# Blessing description
	var desc_label: Label = Label.new()
	desc_label.text = blessing.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_label)

	# Spacer
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.custom_minimum_size.y = 10
	vbox.add_child(spacer)

	# Choose button
	var choose_button: Button = Button.new()
	choose_button.text = "Choose Blessing"
	choose_button.disabled = blessing_chosen_flag
	choose_button.pressed.connect(_on_blessing_selected.bind(blessing))
	vbox.add_child(choose_button)

	return panel

func _get_effect_type_display(effect_type: String) -> String:
	"""Get display name for effect type"""
	match effect_type:
		"damage":
			return "OFFENSIVE BUFF"
		"health":
			return "VITALITY BUFF"
		"card_draw":
			return "TACTICAL BUFF"
		"energy":
			return "RESOURCE BUFF"
		"defense":
			return "DEFENSIVE BUFF"
		"critical":
			return "FORTUNE BUFF"
		"healing":
			return "RECOVERY BUFF"
		"first_strike":
			return "INITIATIVE BUFF"
		_:
			return "BLESSING"

func _get_effect_type_color(effect_type: String) -> Color:
	"""Get color for effect type"""
	match effect_type:
		"damage":
			return Color(1.0, 0.3, 0.3)  # Red
		"health":
			return Color(0.3, 1.0, 0.3)  # Green
		"card_draw":
			return Color(0.4, 0.7, 1.0)  # Blue
		"energy":
			return Color(1.0, 0.9, 0.3)  # Yellow
		"defense":
			return Color(0.7, 0.7, 0.7)  # Gray
		"critical":
			return Color(1.0, 0.6, 0.0)  # Orange
		"healing":
			return Color(0.3, 0.9, 0.6)  # Teal
		"first_strike":
			return Color(0.9, 0.3, 1.0)  # Purple
		_:
			return Color.WHITE

# ========================================
# BLESSING SELECTION
# ========================================

func _on_blessing_selected(blessing: Blessing) -> void:
	"""Handle blessing selection"""
	if blessing_chosen_flag:
		_update_status_message("You already chose a blessing!", Color.ORANGE)
		return

	blessing_chosen_flag = true

	# Disable all blessing buttons
	_disable_all_blessings()

	# Show feedback
	_update_status_message("Blessing received: " + blessing.name + "!", Color(0.4, 1.0, 0.8))

	# Prepare blessing data
	var blessing_data: Dictionary = {
		"id": blessing.id,
		"name": blessing.name,
		"effect_type": blessing.effect_type,
		"effect_value": blessing.effect_value,
		"description": blessing.description,
		"duration": "next_battle"
	}

	# Emit signal
	blessing_chosen.emit(blessing.effect_type, blessing_data)

	print("ShrineUI: Blessing chosen - ", blessing.name, " (", blessing.effect_type, " +", blessing.effect_value, ")")

	# Auto-close after a short delay
	await get_tree().create_timer(2.0).timeout
	close_shrine()

# ========================================
# UI UPDATES
# ========================================

func _disable_all_blessings() -> void:
	"""Disable all blessing choice buttons"""
	for panel in blessing_panels:
		var buttons = _find_buttons_recursive(panel)
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
		if blessing_chosen_flag:
			status_label.text = "Blessing bestowed - May it aid you in battle"
		else:
			status_label.text = "Choose one blessing for your next battle"
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

func set_available_blessings(blessing_ids: Array) -> void:
	"""Set specific blessings by their IDs instead of random generation"""
	available_blessings.clear()

	for blessing_id in blessing_ids:
		for blessing_data in ALL_BLESSINGS:
			if blessing_data.id == blessing_id:
				var blessing := Blessing.new(
					blessing_data.id,
					blessing_data.name,
					blessing_data.description,
					blessing_data.type,
					blessing_data.value,
					blessing_data.icon
				)
				available_blessings.append(blessing)
				break

	# Repopulate with specific blessings
	_display_current_blessings()

func _display_current_blessings() -> void:
	"""Display the current available_blessings array"""
	if not blessings_container:
		return

	# Clear existing
	for child in blessings_container.get_children():
		child.queue_free()
	blessing_panels.clear()

	# Create panels
	for blessing in available_blessings:
		var blessing_panel: Panel = _create_blessing_panel(blessing)
		blessings_container.add_child(blessing_panel)
		blessing_panels.append(blessing_panel)

func get_blessing_chosen() -> bool:
	"""Check if a blessing has been chosen"""
	return blessing_chosen_flag

func refresh_blessings() -> void:
	"""Generate new random blessings (useful if player revisits shrine)"""
	blessing_chosen_flag = false
	populate_blessings()
	_update_status_message()

# ========================================
# CLOSE HANDLING
# ========================================

func close_shrine() -> void:
	"""Close the shrine and emit signal"""
	shrine_closed.emit()
	queue_free()

func _on_close_button_pressed() -> void:
	"""Handle close button press"""
	if not blessing_chosen_flag:
		_update_status_message("Leaving the shrine without a blessing...", Color.YELLOW)
		await get_tree().create_timer(0.5).timeout

	close_shrine()
