extends Control
# VictoryDefeatUI - Victory/Defeat screen shown after battle completion
#
# Scene Structure:
# VictoryDefeatUI (Control)
# ├── DimOverlay (ColorRect) - Semi-transparent black background
# ├── ResultPanel (Panel)
# │   ├── VBoxContainer (VBoxContainer)
# │   │   ├── TitleContainer (HBoxContainer)
# │   │   │   ├── TitleIcon (TextureRect) - Trophy/Skull icon
# │   │   │   └── TitleLabel (Label) - "VICTORY!" or "DEFEAT"
# │   │   ├── Separator1 (HSeparator)
# │   │   ├── MessageLabel (RichTextLabel) - Main message/encouragement
# │   │   ├── Spacer1 (Control) - min_size.y = 20
# │   │   ├── RewardsContainer (VBoxContainer) - Only visible on victory
# │   │   │   ├── RewardsTitle (Label) - "Rewards"
# │   │   │   ├── XPContainer (HBoxContainer)
# │   │   │   │   ├── XPIcon (TextureRect)
# │   │   │   │   └── XPLabel (Label) - "XP Gained: +XXX"
# │   │   │   ├── GoldContainer (HBoxContainer)
# │   │   │   │   ├── GoldIcon (TextureRect)
# │   │   │   │   └── GoldLabel (Label) - "Gold Earned: +XXX"
# │   │   │   └── UnlockContainer (HBoxContainer) - Only visible if champion unlocked
# │   │   │       ├── UnlockIcon (TextureRect)
# │   │   │       └── UnlockLabel (Label) - "Champion Unlocked: [Name]"
# │   │   ├── PenaltyContainer (VBoxContainer) - Only visible on defeat
# │   │   │   ├── PenaltyTitle (Label) - "Consequences"
# │   │   │   ├── GoldLostContainer (HBoxContainer)
# │   │   │   │   ├── GoldLostIcon (TextureRect)
# │   │   │   │   └── GoldLostLabel (Label) - "Gold Lost: -XXX"
# │   │   │   └── LocationLabel (Label) - "Gold dropped at: [Location Name]"
# │   │   ├── Spacer2 (Control) - min_size.y = 30
# │   │   ├── StatsContainer (GridContainer) - Battle statistics
# │   │   │   ├── TurnsLabel (Label) - "Turns Taken:"
# │   │   │   ├── TurnsValue (Label)
# │   │   │   ├── DamageLabel (Label) - "Total Damage:"
# │   │   │   └── DamageValue (Label)
# │   │   ├── Spacer3 (Control) - min_size.y = 20
# │   │   ├── Separator2 (HSeparator)
# │   │   └── ButtonContainer (HBoxContainer)
# │   │       └── ContinueButton (Button) - "Continue"
# └── AnimationPlayer (AnimationPlayer) - For fade in/out effects

# ============================================================
# SIGNALS
# ============================================================

signal continue_pressed

# ============================================================
# NODE REFERENCES
# ============================================================

# Background and panel
@onready var dim_overlay: ColorRect = $DimOverlay
@onready var result_panel: Panel = $ResultPanel

# Title elements
@onready var title_container: HBoxContainer = $ResultPanel/VBoxContainer/TitleContainer
@onready var title_icon: TextureRect = $ResultPanel/VBoxContainer/TitleContainer/TitleIcon
@onready var title_label: Label = $ResultPanel/VBoxContainer/TitleContainer/TitleLabel
@onready var message_label: RichTextLabel = $ResultPanel/VBoxContainer/MessageLabel

# Victory rewards
@onready var rewards_container: VBoxContainer = $ResultPanel/VBoxContainer/RewardsContainer
@onready var rewards_title: Label = $ResultPanel/VBoxContainer/RewardsContainer/RewardsTitle
@onready var xp_label: Label = $ResultPanel/VBoxContainer/RewardsContainer/XPContainer/XPLabel
@onready var gold_label: Label = $ResultPanel/VBoxContainer/RewardsContainer/GoldContainer/GoldLabel
@onready var unlock_container: HBoxContainer = $ResultPanel/VBoxContainer/RewardsContainer/UnlockContainer
@onready var unlock_label: Label = $ResultPanel/VBoxContainer/RewardsContainer/UnlockContainer/UnlockLabel

# Defeat penalties
@onready var penalty_container: VBoxContainer = $ResultPanel/VBoxContainer/PenaltyContainer
@onready var penalty_title: Label = $ResultPanel/VBoxContainer/PenaltyContainer/PenaltyTitle
@onready var gold_lost_label: Label = $ResultPanel/VBoxContainer/PenaltyContainer/GoldLostContainer/GoldLostLabel
@onready var location_label: Label = $ResultPanel/VBoxContainer/PenaltyContainer/LocationLabel

# Statistics
@onready var stats_container: GridContainer = $ResultPanel/VBoxContainer/StatsContainer
@onready var turns_value: Label = $ResultPanel/VBoxContainer/StatsContainer/TurnsValue
@onready var damage_value: Label = $ResultPanel/VBoxContainer/StatsContainer/DamageValue

# Button
@onready var continue_button: Button = $ResultPanel/VBoxContainer/ButtonContainer/ContinueButton

# Animation
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# ============================================================
# CONSTANTS
# ============================================================

const MAP_SCENE: String = "res://scenes/map/map_scene.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/main_menu.tscn"

# Victory messages
const VICTORY_MESSAGES: Array[String] = [
	"[center][color=gold]Outstanding performance![/color][/center]",
	"[center][color=gold]Your champions fought with honor![/color][/center]",
	"[center][color=gold]A glorious triumph![/color][/center]",
	"[center][color=gold]Victory is yours![/color][/center]",
]

# Defeat messages
const DEFEAT_MESSAGES: Array[String] = [
	"[center][color=gray]The battle is lost, but not the war...[/color][/center]",
	"[center][color=gray]Your champions fought bravely, but fell in battle.[/color][/center]",
	"[center][color=gray]Defeat is a harsh teacher. Learn and return stronger.[/color][/center]",
	"[center][color=gray]Even the mightiest warriors face setbacks.[/color][/center]",
]

# ============================================================
# PROPERTIES
# ============================================================

var is_victory: bool = false
var rewards: Dictionary = {}
var battle_stats: Dictionary = {}
var return_to_main_menu: bool = false

# ============================================================
# LIFECYCLE METHODS
# ============================================================

func _ready() -> void:
	"""Initialize the UI (hidden by default)"""
	hide()
	_setup_ui()
	_connect_signals()


func _setup_ui() -> void:
	"""Set up initial UI state"""
	# Center the result panel
	if result_panel:
		result_panel.anchor_left = 0.5
		result_panel.anchor_top = 0.5
		result_panel.anchor_right = 0.5
		result_panel.anchor_bottom = 0.5
		result_panel.offset_left = -300
		result_panel.offset_top = -250
		result_panel.offset_right = 300
		result_panel.offset_bottom = 250
		result_panel.custom_minimum_size = Vector2(600, 500)

	# Set up dim overlay
	if dim_overlay:
		dim_overlay.color = Color(0, 0, 0, 0.7)
		dim_overlay.anchor_right = 1.0
		dim_overlay.anchor_bottom = 1.0

	# Set up button
	if continue_button:
		continue_button.text = "Continue"
		continue_button.custom_minimum_size = Vector2(200, 50)

	# Hide containers initially
	if rewards_container:
		rewards_container.hide()
	if penalty_container:
		penalty_container.hide()
	if unlock_container:
		unlock_container.hide()


func _connect_signals() -> void:
	"""Connect button signals"""
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

# ============================================================
# PUBLIC API
# ============================================================

func show_victory(victory_rewards: Dictionary) -> void:
	"""Display victory screen with rewards

	Args:
		victory_rewards: Dictionary containing:
			- xp: int - Experience points gained
			- gold: int - Gold earned
			- unlock_champion: String (optional) - Champion ID if boss defeated
			- location: String (optional) - Location name
			- turns: int (optional) - Number of turns taken
			- total_damage: int (optional) - Total damage dealt
	"""
	is_victory = true
	rewards = victory_rewards
	battle_stats = victory_rewards.get("stats", {})
	return_to_main_menu = false

	print("Showing victory screen with rewards: ", rewards)

	# Set title
	if title_label:
		title_label.text = "VICTORY!"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))  # Gold color
		title_label.add_theme_font_size_override("font_size", 48)

	# Set victory message
	if message_label:
		message_label.text = VICTORY_MESSAGES[randi() % VICTORY_MESSAGES.size()]
		message_label.fit_content = true

	# Show and populate rewards
	_display_victory_rewards()

	# Display statistics if available
	_display_statistics()

	# Show the UI
	show()

	# Play victory animation
	if animation_player and animation_player.has_animation("victory_appear"):
		animation_player.play("victory_appear")

	# Play victory sound
	_play_sound("victory")


func show_defeat(defeat_info: Dictionary = {}) -> void:
	"""Display defeat screen with penalties

	Args:
		defeat_info: Dictionary containing:
			- gold_lost: int - Amount of gold lost
			- location: String - Location where gold was dropped
			- can_retrieve: bool - Whether player can retrieve their gold
			- turns: int (optional) - Number of turns survived
			- total_damage: int (optional) - Total damage dealt before defeat
	"""
	is_victory = false
	rewards = defeat_info
	battle_stats = defeat_info.get("stats", {})
	return_to_main_menu = defeat_info.get("game_over", false)

	print("Showing defeat screen with info: ", defeat_info)

	# Set title
	if title_label:
		title_label.text = "DEFEAT"
		title_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))  # Red color
		title_label.add_theme_font_size_override("font_size", 48)

	# Set defeat message
	if message_label:
		message_label.text = DEFEAT_MESSAGES[randi() % DEFEAT_MESSAGES.size()]
		message_label.fit_content = true

	# Show and populate penalties
	_display_defeat_penalties(defeat_info)

	# Display statistics if available
	_display_statistics()

	# Update continue button text
	if continue_button:
		if return_to_main_menu:
			continue_button.text = "Return to Main Menu"
		else:
			continue_button.text = "Continue"

	# Show the UI
	show()

	# Play defeat animation
	if animation_player and animation_player.has_animation("defeat_appear"):
		animation_player.play("defeat_appear")

	# Play defeat sound
	_play_sound("defeat")

# ============================================================
# BUTTON HANDLERS
# ============================================================

func _on_continue_pressed() -> void:
	"""Handle continue button press"""
	print("Continue pressed from ", "victory" if is_victory else "defeat", " screen")

	# Play button sound
	_play_sound("button_click")

	# Emit signal
	continue_pressed.emit()

	# Hide the UI
	hide()

	# Determine where to go
	if return_to_main_menu:
		# Full party wipe or game over - return to main menu
		_transition_to_scene(MAIN_MENU_SCENE)
	else:
		# Return to map
		_transition_to_scene(MAP_SCENE)

# ============================================================
# DISPLAY METHODS
# ============================================================

func _display_victory_rewards() -> void:
	"""Display victory rewards section"""
	if not rewards_container:
		return

	rewards_container.show()

	# Set rewards title
	if rewards_title:
		rewards_title.text = "Rewards"
		rewards_title.add_theme_font_size_override("font_size", 24)
		rewards_title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))

	# Display XP
	var xp_gained: int = rewards.get("xp", 0)
	if xp_label:
		xp_label.text = "XP Gained: +" + str(xp_gained)
		xp_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		xp_label.add_theme_font_size_override("font_size", 20)

	# Display Gold
	var gold_earned: int = rewards.get("gold", 0)
	if gold_label:
		gold_label.text = "Gold Earned: +" + str(gold_earned)
		gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		gold_label.add_theme_font_size_override("font_size", 20)

	# Display champion unlock if boss defeated
	if rewards.has("unlock_champion") and unlock_container and unlock_label:
		unlock_container.show()
		var champion_name: String = _get_champion_name(rewards["unlock_champion"])
		unlock_label.text = "Champion Unlocked: " + champion_name + "!"
		unlock_label.add_theme_color_override("font_color", Color(1.0, 0.4, 1.0))  # Purple/pink
		unlock_label.add_theme_font_size_override("font_size", 22)

		# Play special unlock sound/animation
		_play_sound("champion_unlock")


func _display_defeat_penalties(defeat_info: Dictionary) -> void:
	"""Display defeat penalties section"""
	if not penalty_container:
		return

	penalty_container.show()

	# Set penalty title
	if penalty_title:
		penalty_title.text = "Consequences"
		penalty_title.add_theme_font_size_override("font_size", 24)
		penalty_title.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))

	# Display gold lost
	var gold_lost: int = defeat_info.get("gold_lost", 0)
	if gold_lost_label:
		gold_lost_label.text = "Gold Lost: -" + str(gold_lost)
		gold_lost_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		gold_lost_label.add_theme_font_size_override("font_size", 20)

	# Display location where gold was dropped
	var location: String = defeat_info.get("location", "Unknown Location")
	if location_label:
		if defeat_info.get("can_retrieve", true):
			location_label.text = "Gold dropped at: " + location
			location_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
		else:
			location_label.text = "Gold lost forever at: " + location
			location_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		location_label.add_theme_font_size_override("font_size", 16)


func _display_statistics() -> void:
	"""Display battle statistics"""
	if not stats_container:
		return

	# Only show if we have stats
	if battle_stats.is_empty():
		stats_container.hide()
		return

	stats_container.show()

	# Display turns taken
	if battle_stats.has("turns") and turns_value:
		turns_value.text = str(battle_stats["turns"])

	# Display total damage
	if battle_stats.has("total_damage") and damage_value:
		damage_value.text = str(battle_stats["total_damage"])

# ============================================================
# HELPER METHODS
# ============================================================

func _get_champion_name(champion_id: String) -> String:
	"""Get champion display name from ID"""
	# Query CardDatabase for champion name
	if CardDatabase.champions_data.has(champion_id):
		return CardDatabase.champions_data[champion_id].get("name", champion_id)

	# Fallback to formatted ID
	return champion_id.capitalize()


func _transition_to_scene(scene_path: String) -> void:
	"""Transition to another scene"""
	# TODO: Add fade transition
	get_tree().change_scene_to_file(scene_path)


func _play_sound(sound_name: String) -> void:
	"""Play sound effect"""
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx(sound_name)


# ============================================================
# ANIMATION CALLBACKS
# ============================================================

func _on_animation_finished(anim_name: String) -> void:
	"""Called when animation finishes"""
	print("Animation finished: ", anim_name)

# ============================================================
# PUBLIC UTILITY METHODS
# ============================================================

func hide_ui() -> void:
	"""Hide the victory/defeat UI"""
	hide()


func is_showing() -> bool:
	"""Check if the UI is currently visible"""
	return visible


func get_result_type() -> String:
	"""Get the current result type (victory or defeat)"""
	return "victory" if is_victory else "defeat"


func set_continue_destination(to_main_menu: bool) -> void:
	"""Set whether continue button returns to main menu or map

	Args:
		to_main_menu: If true, return to main menu. If false, return to map.
	"""
	return_to_main_menu = to_main_menu

	if continue_button:
		if return_to_main_menu:
			continue_button.text = "Return to Main Menu"
		else:
			continue_button.text = "Continue"
