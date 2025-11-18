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

# Visual element references
@onready var portrait: ColorRect = $VBoxContainer/HeaderContainer/Portrait
@onready var name_label: Label = $VBoxContainer/HeaderContainer/ChampionInfoContainer/NameLabel
@onready var hp_bar: ProgressBar = $VBoxContainer/HeaderContainer/ChampionInfoContainer/HPSection/HPBar
@onready var hp_text: Label = $VBoxContainer/HeaderContainer/ChampionInfoContainer/HPSection/HPText
@onready var block_indicator: Label = $VBoxContainer/HeaderContainer/ChampionInfoContainer/BlockIndicator
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


func set_highlighted(value: bool) -> void:
	"""
	Show or hide targeting highlight.

	Args:
		value: True to highlight, False to remove highlight
	"""
	is_highlighted = value

	if is_highlighted:
		portrait.modulate = HIGHLIGHT_MODULATE
		portrait.add_theme_color_override("border_color", HIGHLIGHT_COLOR)
	else:
		_update_button_states()  # Reapply normal modulation


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

	attack_pressed.emit(champion_index)


func _on_defend_button_pressed() -> void:
	"""Handle defend button press."""
	if champion == null:
		return

	defend_pressed.emit(champion_index)


func _on_portrait_gui_input(event: InputEvent) -> void:
	"""
	Handle mouse clicks on the portrait for targeting.

	Args:
		event: The input event
	"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if champion != null:
			champion_clicked_for_targeting.emit(champion_index)
