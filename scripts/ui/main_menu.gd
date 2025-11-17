extends Control
# MainMenu - Main menu scene with new game, continue, and quit functionality
#
# Scene Structure:
# MainMenu (Control)
# ├── BackgroundPanel (Panel)
# │   └── BackgroundTexture (TextureRect) - Optional background image
# ├── VBoxContainer (VBoxContainer)
# │   ├── TitleLabel (Label) - "ALS TAVERN"
# │   ├── VersionLabel (Label) - "v1.0.0"
# │   ├── Spacer1 (Control) - min_size.y = 40
# │   ├── NewGameButton (Button) - "New Game"
# │   ├── ContinueButton (Button) - "Continue" (disabled if no save)
# │   ├── SettingsButton (Button) - "Settings" (optional)
# │   ├── QuitButton (Button) - "Quit"
# │   └── Spacer2 (Control) - min_size.y = 20
# └── FooterLabel (Label) - Copyright/credits text

# ============================================================
# SIGNALS
# ============================================================

signal game_started

# ============================================================
# NODE REFERENCES
# ============================================================

# Background
@onready var background_panel: Panel = $BackgroundPanel
@onready var background_texture: TextureRect = $BackgroundPanel/BackgroundTexture

# Title and version
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var version_label: Label = $VBoxContainer/VersionLabel

# Buttons
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

# Footer
@onready var footer_label: Label = $FooterLabel

# Container
@onready var vbox_container: VBoxContainer = $VBoxContainer

# ============================================================
# CONSTANTS
# ============================================================

const VERSION: String = "1.0.0"
const PARTY_SELECTION_SCENE: String = "res://scenes/ui/party_selection.tscn"
const MAP_SCENE: String = "res://scenes/map/map_scene.tscn"

# ============================================================
# PROPERTIES
# ============================================================

var has_save_file: bool = false

# ============================================================
# LIFECYCLE METHODS
# ============================================================

func _ready() -> void:
	"""Initialize the main menu"""
	_setup_ui()
	_check_save_status()
	_connect_signals()
	_apply_styling()

	# Play menu music if audio manager exists
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_music("menu_theme")

	print("Main Menu initialized")


func _setup_ui() -> void:
	"""Set up UI elements with text and initial state"""
	# Set title and version
	title_label.text = "ALS TAVERN"
	version_label.text = "v" + VERSION

	# Set button text
	new_game_button.text = "New Game"
	continue_button.text = "Continue"
	settings_button.text = "Settings"
	quit_button.text = "Quit"

	# Set footer text
	footer_label.text = "A Champion-Based Card Battle Game"

	# Center the VBoxContainer
	vbox_container.anchor_left = 0.5
	vbox_container.anchor_top = 0.5
	vbox_container.anchor_right = 0.5
	vbox_container.anchor_bottom = 0.5
	vbox_container.offset_left = -150
	vbox_container.offset_top = -200
	vbox_container.offset_right = 150
	vbox_container.offset_bottom = 200


func _apply_styling() -> void:
	"""Apply custom styling to UI elements"""
	# Title styling
	if title_label:
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Version styling
	if version_label:
		version_label.add_theme_font_size_override("font_size", 16)
		version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		version_label.modulate = Color(0.7, 0.7, 0.7, 1.0)

	# Footer styling
	if footer_label:
		footer_label.add_theme_font_size_override("font_size", 14)
		footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		footer_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		footer_label.anchor_bottom = 1.0
		footer_label.offset_bottom = -10

	# Button styling
	for button in [new_game_button, continue_button, settings_button, quit_button]:
		if button:
			button.custom_minimum_size = Vector2(200, 40)


func _check_save_status() -> void:
	"""Check if a save file exists and enable/disable continue button"""
	# Check if SaveManager exists before using it
	if not has_node("/root/SaveManager"):
		push_warning("SaveManager not found, assuming no save file")
		has_save_file = false
	else:
		has_save_file = SaveManager.has_save()

	if continue_button:
		continue_button.disabled = not has_save_file

		if has_save_file:
			continue_button.tooltip_text = "Load your saved game"
		else:
			continue_button.tooltip_text = "No saved game found"

	print("Save file exists: ", has_save_file)


func _connect_signals() -> void:
	"""Connect button signals to handler methods"""
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)

	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)

	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

# ============================================================
# BUTTON HANDLERS
# ============================================================

func _on_new_game_pressed() -> void:
	"""Handle New Game button press
	Flow: Reset game state → Party Selection → Map"""
	print("New Game pressed")

	# Play button sound
	_play_button_sound()

	# Show confirmation if save exists
	if has_save_file:
		_show_new_game_confirmation()
	else:
		_start_new_game()


func _on_continue_pressed() -> void:
	"""Handle Continue button press
	Flow: Load save → Map (or last location)"""
	print("Continue pressed")

	if not has_save_file:
		push_error("No save file to load")
		return

	# Check if SaveManager exists
	if not has_node("/root/SaveManager"):
		push_error("SaveManager not found")
		_show_error_dialog("Game systems not properly initialized.")
		return

	# Play button sound
	_play_button_sound()

	# Load the game
	var load_success: bool = SaveManager.load_game()

	if load_success:
		print("Game loaded successfully, transitioning to map")
		game_started.emit()

		# Transition to map scene
		_transition_to_scene(MAP_SCENE)
	else:
		# Show error dialog
		_show_error_dialog("Failed to load save file. File may be corrupted.")


func _on_settings_pressed() -> void:
	"""Handle Settings button press (optional feature)"""
	print("Settings pressed")
	_play_button_sound()

	# TODO: Implement settings menu
	# const SETTINGS_SCENE: String = "res://scenes/ui/settings_menu.tscn"
	# _transition_to_scene(SETTINGS_SCENE)

	print("Settings menu not yet implemented")


func _on_quit_pressed() -> void:
	"""Handle Quit button press"""
	print("Quit pressed")
	_play_button_sound()

	# Small delay for sound to play
	await get_tree().create_timer(0.1).timeout

	# Quit the game
	get_tree().quit()

# ============================================================
# HELPER METHODS
# ============================================================

func _start_new_game() -> void:
	"""Start a new game from scratch"""
	print("Starting new game...")

	# Reset game state
	if has_node("/root/GameManager"):
		GameManager.reset_game()
	else:
		push_warning("GameManager not found, skipping reset")

	# Delete existing save
	if has_save_file and has_node("/root/SaveManager"):
		SaveManager.delete_save()

	# Emit signal
	game_started.emit()

	# Check if party selection scene exists, otherwise go straight to map
	if ResourceLoader.exists(PARTY_SELECTION_SCENE):
		print("Transitioning to party selection")
		_transition_to_scene(PARTY_SELECTION_SCENE)
	else:
		print("Party selection scene not found, going to map")
		_transition_to_scene(MAP_SCENE)


func _show_new_game_confirmation() -> void:
	"""Show confirmation dialog when starting new game with existing save"""
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "Starting a new game will overwrite your existing save. Continue?"
	dialog.title = "Confirm New Game"
	dialog.ok_button_text = "Start New Game"
	dialog.cancel_button_text = "Cancel"

	add_child(dialog)
	dialog.popup_centered()

	# Connect signals
	dialog.confirmed.connect(func():
		_start_new_game()
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)


func _show_error_dialog(message: String) -> void:
	"""Show error dialog with given message"""
	var dialog := AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Error"
	dialog.ok_button_text = "OK"

	add_child(dialog)
	dialog.popup_centered()

	dialog.confirmed.connect(func():
		dialog.queue_free()
	)


func _transition_to_scene(scene_path: String) -> void:
	"""Transition to another scene with fade effect"""
	# TODO: Add fade transition
	# For now, direct scene change
	get_tree().change_scene_to_file(scene_path)


func _play_button_sound() -> void:
	"""Play button click sound effect"""
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("button_click")

# ============================================================
# PUBLIC API
# ============================================================

func refresh_save_status() -> void:
	"""Public method to refresh the save status (called externally if needed)"""
	_check_save_status()


func show_message(message: String) -> void:
	"""Display a temporary message to the player"""
	print("Main Menu Message: ", message)
	# TODO: Implement toast notification
