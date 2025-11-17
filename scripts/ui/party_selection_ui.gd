extends Control
# Party Selection UI Script
#
# This script manages the party selection screen where players choose 3 champions
# from their unlocked roster and select 5 cards for each champion's deck.
#
# SCENE STRUCTURE:
# PartySelectionUI (Control) - Root node (anchors: Full Rect)
# ├── BackgroundPanel (ColorRect) - Full screen background
# ├── TitleLabel (Label) - "SELECT YOUR PARTY" header
# ├── ChampionSlotsContainer (HBoxContainer) - Holds 3 champion slots
# │   ├── ChampionSlot1 (Panel) - First champion slot
# │   │   ├── SelectButton (Button) - Click to select champion
# │   │   ├── PortraitRect (TextureRect) - Champion portrait
# │   │   ├── NameLabel (Label) - Champion name
# │   │   ├── StatsLabel (Label) - HP/DMG/DEF display
# │   │   ├── CardsContainer (HBoxContainer) - 5 card mini-icons
# │   │   │   ├── CardSlot1 (TextureRect) - Card 1 icon
# │   │   │   ├── CardSlot2 (TextureRect) - Card 2 icon
# │   │   │   ├── CardSlot3 (TextureRect) - Card 3 icon
# │   │   │   ├── CardSlot4 (TextureRect) - Card 4 icon
# │   │   │   └── CardSlot5 (TextureRect) - Card 5 icon
# │   │   └── EditCardsButton (Button) - Open deck builder for this slot
# │   ├── ChampionSlot2 (Panel) - Second champion slot (same structure)
# │   └── ChampionSlot3 (Panel) - Third champion slot (same structure)
# ├── ChampionPickerPanel (Panel) - Modal panel for champion selection
# │   ├── PickerTitle (Label) - "Choose a Champion"
# │   ├── ChampionGridContainer (GridContainer) - Grid of available champions
# │   │   └── [ChampionButtons] - Dynamically created champion selection buttons
# │   └── ClosePickerButton (Button) - Close without selecting
# ├── DeckBuilderPanel (Panel) - Modal panel for card selection
# │   ├── BuilderTitle (Label) - "Build Deck for [Champion Name]"
# │   ├── SelectedCardsLabel (Label) - "Selected: X/5"
# │   ├── CardGridContainer (GridContainer) - Grid of available cards
# │   │   └── [CardButtons] - Dynamically created card selection buttons
# │   ├── CloseDeckBuilderButton (Button) - Save and close
# │   └── ClearSelectionButton (Button) - Deselect all cards
# └── ConfirmButton (Button) - Start game with current party
#
# INTERACTION FLOW:
# 1. Player clicks on one of 3 champion slots → Opens champion picker
# 2. Player selects a champion from picker → Champion assigned to slot, deck builder opens
# 3. Player selects 5 cards from available cards → Cards assigned to champion
# 4. Repeat for all 3 slots
# 5. Player clicks Confirm → Validates party (3 champions, 15 total cards), saves to PartyManager
# 6. Emits party_confirmed signal with party data


# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when party selection is confirmed and valid
## Parameters: champion_ids (Array[String]), deck_data (Dictionary[champion_id -> Array[card_ids]])
signal party_confirmed(champion_ids: Array, deck_data: Dictionary)


# ============================================================================
# PROPERTIES
# ============================================================================

# Unlocked champions (loaded from PartyManager)
var unlocked_champions: Array = []

# Currently selected champions (3 slots, empty string if unassigned)
var selected_champions: Array[String] = ["", "", ""]

# Deck data for each champion {champion_id: [card_id1, card_id2, ...]}
var deck_data: Dictionary = {}

# UI state tracking
var current_editing_slot: int = -1  # Which slot is being edited (-1 = none)
var current_editing_champion: String = ""  # Champion ID being edited

# Temporary card selection (used during deck building)
var temp_selected_cards: Array[String] = []


# ============================================================================
# ONREADY VARIABLES (Node References)
# ============================================================================

# Champion slot containers
@onready var champion_slots_container: HBoxContainer = $ChampionSlotsContainer
var champion_slot_buttons: Array[Button] = []
var champion_slot_panels: Array[Panel] = []

# Modal panels
@onready var champion_picker_panel: Panel = $ChampionPickerPanel
@onready var deck_builder_panel: Panel = $DeckBuilderPanel

# Champion picker elements
@onready var champion_grid_container: GridContainer = $ChampionPickerPanel/ChampionGridContainer
@onready var close_picker_button: Button = $ChampionPickerPanel/ClosePickerButton

# Deck builder elements
@onready var deck_builder_title: Label = $DeckBuilderPanel/BuilderTitle
@onready var selected_cards_label: Label = $DeckBuilderPanel/SelectedCardsLabel
@onready var card_grid_container: GridContainer = $DeckBuilderPanel/CardGridContainer
@onready var close_deck_builder_button: Button = $DeckBuilderPanel/CloseDeckBuilderButton
@onready var clear_selection_button: Button = $DeckBuilderPanel/ClearSelectionButton

# Confirm button
@onready var confirm_button: Button = $ConfirmButton


# ============================================================================
# GDSCRIPT LIFECYCLE
# ============================================================================

func _ready() -> void:
	"""
	Called when node enters the scene tree.
	Loads unlocked champions from PartyManager and initializes UI.
	"""
	# Hide modal panels initially
	champion_picker_panel.visible = false
	deck_builder_panel.visible = false

	# Load unlocked champions from PartyManager
	load_unlocked_champions()

	# Initialize champion slots
	initialize_champion_slots()

	# Connect button signals
	connect_signals()

	# Update UI state
	update_all_slots()
	update_confirm_button_state()


# ============================================================================
# INITIALIZATION
# ============================================================================

func load_unlocked_champions() -> void:
	"""
	Loads unlocked champions from PartyManager's champion_progress.
	All champions in champion_progress are considered unlocked.
	"""
	unlocked_champions.clear()

	if not PartyManager:
		push_error("PartyManager not found. Make sure it's set up as an autoload.")
		return

	# Get all champions from PartyManager's champion_progress
	for champion_id in PartyManager.champion_progress.keys():
		unlocked_champions.append(champion_id)

	print("Loaded unlocked champions: ", unlocked_champions)


func initialize_champion_slots() -> void:
	"""
	Finds and stores references to the 3 champion slot panels and their buttons.
	These should be manually created in the scene editor.
	"""
	# Find champion slot panels (ChampionSlot1, ChampionSlot2, ChampionSlot3)
	for i in range(3):
		var slot_name = "ChampionSlot" + str(i + 1)
		var slot_panel = champion_slots_container.get_node_or_null(slot_name)

		if slot_panel:
			champion_slot_panels.append(slot_panel)

			# Find the select button within the slot
			var select_button = slot_panel.get_node_or_null("SelectButton")
			if select_button:
				champion_slot_buttons.append(select_button)
			else:
				push_warning("SelectButton not found in " + slot_name)


func connect_signals() -> void:
	"""
	Connects UI button signals to handler methods.
	"""
	# Connect champion slot buttons
	for i in range(champion_slot_buttons.size()):
		champion_slot_buttons[i].pressed.connect(_on_champion_slot_clicked.bind(i))

	# Connect champion picker buttons
	if close_picker_button:
		close_picker_button.pressed.connect(_on_close_picker_pressed)

	# Connect deck builder buttons
	if close_deck_builder_button:
		close_deck_builder_button.pressed.connect(_on_close_deck_builder_pressed)

	if clear_selection_button:
		clear_selection_button.pressed.connect(_on_clear_selection_pressed)

	# Connect confirm button
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_button_pressed)


# ============================================================================
# CHAMPION SLOT INTERACTION
# ============================================================================

func _on_champion_slot_clicked(slot_index: int) -> void:
	"""
	Called when a champion slot button is clicked.
	Opens the champion picker to select/change the champion for this slot.

	Args:
		slot_index: Index of the slot that was clicked (0-2)
	"""
	current_editing_slot = slot_index
	populate_champion_picker()
	champion_picker_panel.visible = true


func update_champion_slot(slot_index: int) -> void:
	"""
	Updates the visual display of a champion slot with current data.

	Args:
		slot_index: Index of the slot to update (0-2)
	"""
	if slot_index < 0 or slot_index >= champion_slot_panels.size():
		return

	var slot_panel = champion_slot_panels[slot_index]
	var champion_id = selected_champions[slot_index]

	# Get references to slot UI elements
	var portrait_rect = slot_panel.get_node_or_null("PortraitRect")
	var name_label = slot_panel.get_node_or_null("NameLabel")
	var stats_label = slot_panel.get_node_or_null("StatsLabel")
	var cards_container = slot_panel.get_node_or_null("CardsContainer")
	var edit_cards_button = slot_panel.get_node_or_null("EditCardsButton")

	if champion_id == "":
		# Empty slot - show placeholder
		if name_label:
			name_label.text = "Empty Slot"
		if stats_label:
			stats_label.text = "Click to select"
		if portrait_rect:
			portrait_rect.texture = null
		if edit_cards_button:
			edit_cards_button.visible = false

		# Clear card slots
		if cards_container:
			for card_slot in cards_container.get_children():
				if card_slot is TextureRect:
					card_slot.texture = null
	else:
		# Get champion data
		var champ_progress = PartyManager.get_champion_progress(champion_id)
		var champ_data = CardDatabase.get_champion_data(champion_id)

		# Update portrait and name
		if name_label:
			name_label.text = champ_data.get("name", champion_id)

		# Update stats
		if stats_label:
			var hp = champ_progress.get("max_hp", 0)
			var dmg = champ_progress.get("damage", 0)
			var def = champ_progress.get("defense", 0)
			stats_label.text = "HP: %d | DMG: %d | DEF: %d" % [hp, dmg, def]

		# Update portrait (if available)
		if portrait_rect and champ_data.has("portrait_path"):
			var portrait_path = champ_data.get("portrait_path", "")
			if FileAccess.file_exists(portrait_path):
				portrait_rect.texture = load(portrait_path)

		# Show edit cards button
		if edit_cards_button:
			edit_cards_button.visible = true
			# Connect edit button if not already connected
			if not edit_cards_button.pressed.is_connected(_on_edit_cards_clicked):
				edit_cards_button.pressed.connect(_on_edit_cards_clicked.bind(slot_index))

		# Update card mini-icons
		update_card_slots(slot_index)


func update_card_slots(slot_index: int) -> void:
	"""
	Updates the 5 card mini-icon displays for a champion slot.

	Args:
		slot_index: Index of the champion slot (0-2)
	"""
	if slot_index < 0 or slot_index >= champion_slot_panels.size():
		return

	var slot_panel = champion_slot_panels[slot_index]
	var cards_container = slot_panel.get_node_or_null("CardsContainer")

	if not cards_container:
		return

	var champion_id = selected_champions[slot_index]
	var selected_cards = deck_data.get(champion_id, [])

	# Update each card slot (5 total)
	var card_slot_nodes = cards_container.get_children()
	for i in range(min(5, card_slot_nodes.size())):
		var card_slot = card_slot_nodes[i]

		if i < selected_cards.size():
			# Show card icon
			var card_id = selected_cards[i]
			var card_data = CardDatabase.get_card_data(card_id)

			if card_slot is TextureRect and card_data.has("icon_path"):
				var icon_path = card_data.get("icon_path", "")
				if FileAccess.file_exists(icon_path):
					card_slot.texture = load(icon_path)
				else:
					# Use placeholder or color indicator
					card_slot.texture = null
		else:
			# Empty card slot
			if card_slot is TextureRect:
				card_slot.texture = null


func update_all_slots() -> void:
	"""
	Updates the visual display of all 3 champion slots.
	"""
	for i in range(3):
		update_champion_slot(i)


func _on_edit_cards_clicked(slot_index: int) -> void:
	"""
	Called when the "Edit Cards" button is clicked on a champion slot.
	Opens the deck builder for that champion.

	Args:
		slot_index: Index of the champion slot (0-2)
	"""
	var champion_id = selected_champions[slot_index]
	if champion_id != "":
		open_deck_builder(champion_id, slot_index)


# ============================================================================
# CHAMPION PICKER
# ============================================================================

func populate_champion_picker() -> void:
	"""
	Populates the champion picker panel with all unlocked champions.
	Creates a button for each unlocked champion.
	"""
	# Clear existing champion buttons
	for child in champion_grid_container.get_children():
		child.queue_free()

	# Create button for each unlocked champion
	for champion_id in unlocked_champions:
		var champ_data = CardDatabase.get_champion_data(champion_id)
		var champ_progress = PartyManager.get_champion_progress(champion_id)

		# Create champion selection button
		var button = Button.new()
		button.text = champ_data.get("name", champion_id)
		button.custom_minimum_size = Vector2(150, 80)

		# Add level and stats info
		var level = champ_progress.get("level", 1)
		var hp = champ_progress.get("max_hp", 0)
		button.text += "\nLv.%d | HP: %d" % [level, hp]

		# Connect button signal
		button.pressed.connect(_on_champion_selected.bind(champion_id))

		# Add to grid
		champion_grid_container.add_child(button)


func _on_champion_selected(champion_id: String) -> void:
	"""
	Called when a champion is selected from the picker.
	Assigns the champion to the current slot and opens deck builder.

	Args:
		champion_id: ID of the selected champion
	"""
	if current_editing_slot < 0 or current_editing_slot >= 3:
		return

	# Assign champion to slot
	selected_champions[current_editing_slot] = champion_id

	# Initialize deck data if not present
	if not deck_data.has(champion_id):
		# Use default selected cards from PartyManager
		var champ_progress = PartyManager.get_champion_progress(champion_id)
		var default_cards = champ_progress.get("selected_cards", [])
		deck_data[champion_id] = default_cards.duplicate()

	# Update slot display
	update_champion_slot(current_editing_slot)

	# Close champion picker
	champion_picker_panel.visible = false

	# Open deck builder for card selection
	open_deck_builder(champion_id, current_editing_slot)


func _on_close_picker_pressed() -> void:
	"""
	Called when the close picker button is pressed.
	Closes the champion picker without selecting a champion.
	"""
	champion_picker_panel.visible = false
	current_editing_slot = -1


# ============================================================================
# DECK BUILDER
# ============================================================================

func open_deck_builder(champion_id: String, slot_index: int) -> void:
	"""
	Opens the deck builder panel for a specific champion.
	Allows player to select 5 cards from the champion's unlocked cards.

	Args:
		champion_id: ID of the champion to build deck for
		slot_index: Index of the champion slot (0-2)
	"""
	current_editing_slot = slot_index
	current_editing_champion = champion_id

	# Load current deck selection into temp array
	temp_selected_cards = deck_data.get(champion_id, []).duplicate()

	# Update deck builder title
	var champ_data = CardDatabase.get_champion_data(champion_id)
	deck_builder_title.text = "Build Deck for " + champ_data.get("name", champion_id)

	# Populate card grid
	populate_card_grid(champion_id)

	# Update selected cards counter
	update_selected_cards_label()

	# Show deck builder panel
	deck_builder_panel.visible = true


func populate_card_grid(champion_id: String) -> void:
	"""
	Populates the card grid with all unlocked cards for the champion.

	Args:
		champion_id: ID of the champion
	"""
	# Clear existing card buttons
	for child in card_grid_container.get_children():
		child.queue_free()

	# Get unlocked cards for this champion
	var champ_progress = PartyManager.get_champion_progress(champion_id)
	var unlocked_cards = champ_progress.get("unlocked_cards", [])

	# Create button for each unlocked card
	for card_id in unlocked_cards:
		var card_data = CardDatabase.get_card_data(card_id)

		# Create card selection button
		var button = Button.new()
		button.text = card_data.get("name", card_id)
		button.custom_minimum_size = Vector2(120, 60)
		button.toggle_mode = true

		# Set button state if card is already selected
		if card_id in temp_selected_cards:
			button.button_pressed = true

		# Add cost info
		var cost = card_data.get("cost", 0)
		button.text += "\n[%d]" % cost

		# Connect button signal
		button.toggled.connect(_on_card_toggled.bind(card_id, button))

		# Add to grid
		card_grid_container.add_child(button)


func _on_card_toggled(is_pressed: bool, card_id: String, button: Button) -> void:
	"""
	Called when a card button is toggled in the deck builder.

	Args:
		is_pressed: Whether the button is now pressed
		card_id: ID of the card
		button: The button that was toggled
	"""
	if is_pressed:
		# Add card if we haven't reached the limit
		if temp_selected_cards.size() < 5:
			temp_selected_cards.append(card_id)
		else:
			# Can't add more than 5 cards
			button.button_pressed = false
			print("Cannot select more than 5 cards")
	else:
		# Remove card from selection
		var index = temp_selected_cards.find(card_id)
		if index >= 0:
			temp_selected_cards.remove_at(index)

	# Update counter
	update_selected_cards_label()


func update_selected_cards_label() -> void:
	"""
	Updates the "Selected: X/5" label in the deck builder.
	"""
	if selected_cards_label:
		selected_cards_label.text = "Selected: %d/5" % temp_selected_cards.size()


func _on_clear_selection_pressed() -> void:
	"""
	Called when the clear selection button is pressed.
	Deselects all cards in the deck builder.
	"""
	temp_selected_cards.clear()

	# Unpress all card buttons
	for button in card_grid_container.get_children():
		if button is Button:
			button.button_pressed = false

	update_selected_cards_label()


func _on_close_deck_builder_pressed() -> void:
	"""
	Called when the close deck builder button is pressed.
	Saves the card selection and closes the deck builder.
	"""
	# Only save if exactly 5 cards are selected
	if temp_selected_cards.size() == 5:
		deck_data[current_editing_champion] = temp_selected_cards.duplicate()
		update_card_slots(current_editing_slot)
		deck_builder_panel.visible = false
		current_editing_champion = ""
		update_confirm_button_state()
	else:
		print("You must select exactly 5 cards. Currently selected: ", temp_selected_cards.size())
		# Could show a warning label here


# ============================================================================
# PARTY CONFIRMATION
# ============================================================================

func _on_confirm_button_pressed() -> void:
	"""
	Called when the confirm button is pressed.
	Validates the party composition and emits the party_confirmed signal.
	"""
	if not is_party_valid():
		print("Party is not valid. Ensure 3 champions are selected with 5 cards each.")
		return

	# Save party to PartyManager
	PartyManager.set_active_party(selected_champions)

	# Save card selections for each champion
	for champion_id in selected_champions:
		var cards = deck_data.get(champion_id, [])
		PartyManager.set_selected_cards(champion_id, cards)

	# Emit signal with party data
	party_confirmed.emit(selected_champions, deck_data)

	print("Party confirmed!")
	print("Champions: ", selected_champions)
	print("Deck data: ", deck_data)


func is_party_valid() -> bool:
	"""
	Checks if the current party composition is valid.
	Valid = 3 champions selected, each with exactly 5 cards.

	Returns:
		bool: True if party is valid, false otherwise
	"""
	# Check if all 3 slots are filled
	for champion_id in selected_champions:
		if champion_id == "":
			return false

	# Check if each champion has exactly 5 cards selected
	for champion_id in selected_champions:
		var cards = deck_data.get(champion_id, [])
		if cards.size() != 5:
			return false

	return true


func update_confirm_button_state() -> void:
	"""
	Updates the confirm button's enabled/disabled state based on party validity.
	"""
	if confirm_button:
		confirm_button.disabled = not is_party_valid()
