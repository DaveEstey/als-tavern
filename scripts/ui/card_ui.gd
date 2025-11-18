extends Control
# Card UI Widget Script
#
# This script represents a single card displayed in the player's hand.
# It handles card rendering, user interaction, and drag-and-drop functionality.
#
# SCENE STRUCTURE:
# CardUI (Control) - Root node
# ├── BackgroundPanel (ColorRect) - Card background colored by champion
# ├── CardName (Label) - Displays card name
# ├── CostLabel (Label) - Displays mana/cost requirement
# ├── DescriptionLabel (Label) - Displays card effect text
# └── CardTypeIcon (TextureRect) - Visual icon for card type
#
# INTERACTION FLOW:
# 1. User clicks and holds on card → _gui_input detects InputEventMouseButton (pressed)
# 2. is_being_dragged = true, original_position stored, mouse cursor captured
# 3. _process updates card position to follow mouse while dragging
# 4. Hovering over champions triggers champion selection (stored in selected_champion_index)
# 5. Mouse release → check if over champion; if yes, emit card_dropped signal; if no, return to hand


# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when mouse hovers over this card
signal card_hovered(card_id: String)

## Emitted when card is dropped on a champion
## Parameters: card_id, champion_index, target_indices (affected units/areas)
signal card_dropped(card_id: String, champion_index: int, target_indices: Array[int])


# ============================================================================
# PROPERTIES
# ============================================================================

# Card data loaded from CardDatabase
var card_data: Dictionary = {}

# Drag state tracking
var is_being_dragged: bool = false
var original_position: Vector2 = Vector2.ZERO
var original_rotation: float = 0.0

# Base transform set by hand layout (where card should return to)
var base_position: Vector2 = Vector2.ZERO
var base_rotation: float = 0.0

# Current champion target (-1 means no champion selected)
var selected_champion_index: int = -1

# Drag and drop parameters
var drag_offset: Vector2 = Vector2.ZERO
var drag_sensitivity: float = 0.1
var is_hovered: bool = false

# Visual properties
var normal_scale: Vector2 = Vector2(1.0, 1.0)
var hover_scale: Vector2 = Vector2(1.1, 1.1)
var drag_scale: Vector2 = Vector2(0.95, 0.95)
var animation_speed: float = 0.15


# ============================================================================
# ONREADY VARIABLES (Node References)
# ============================================================================

@onready var background_panel: ColorRect = $BackgroundPanel
@onready var card_name_label: Label = $CardName
@onready var cost_label: Label = $CostLabel
@onready var description_label: Label = $DescriptionLabel
@onready var card_type_icon: TextureRect = $CardTypeIcon


# ============================================================================
# GDSCRIPT LIFECYCLE
# ============================================================================

func _ready() -> void:
	"""
	Called when node enters the scene tree.
	Sets up UI signals and initializes visual state.
	"""
	# Connect mouse signals for hover effects
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Set up visual properties
	normal_scale = scale

	# Initialize with no champion selected
	selected_champion_index = -1

	# Make sure we can receive input
	gui_input.connect(_gui_input)


func _gui_input(event: InputEvent) -> void:
	"""
	Handles mouse input for drag-and-drop functionality.

	- Left click: Start dragging the card
	- Left release: Drop card on target or return to hand
	"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging
				_start_drag()
				get_viewport().set_input_as_handled()
			else:
				# Release drag
				_end_drag()
				get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	"""
	Updates card position while dragging.
	Smooth animation for returning to original position when not dragging.
	"""
	if is_being_dragged:
		# Update position to follow mouse
		var mouse_pos = get_global_mouse_position()
		global_position = mouse_pos + drag_offset

		# Check if hovering over a champion
		_check_champion_hover()
	else:
		# Smoothly return to original position
		global_position = global_position.lerp(original_position, delta / animation_speed)


# ============================================================================
# INITIALIZATION
# ============================================================================

func initialize(card_id: String) -> void:
	"""
	Loads card data from CardDatabase and populates UI elements.

	Args:
		card_id: The unique identifier of the card to load
	"""
	# Get card data from CardDatabase (assuming it's a global autoload)
	card_data = CardDatabase.get_card_data(card_id)

	if card_data.is_empty():
		push_error("Card with ID '%s' not found in CardDatabase" % card_id)
		return

	# Populate card name
	if card_name_label:
		card_name_label.text = card_data.get("name", "Unknown Card")

	# Populate cost/mana requirement
	if cost_label:
		var cost = card_data.get("cost", 0)
		cost_label.text = str(cost)

	# Populate description/effect text
	if description_label:
		description_label.text = card_data.get("description", "")

	# Set background color based on champion
	var champion_id = card_data.get("champion", "")
	var champion_color = get_champion_color(champion_id)
	if background_panel:
		background_panel.color = champion_color

	# Load and set card type icon if available
	if card_type_icon and card_data.has("icon_path"):
		card_type_icon.texture = load(card_data.get("icon_path", ""))


# ============================================================================
# DRAG AND DROP LOGIC
# ============================================================================

func _start_drag() -> void:
	"""
	Initiates drag operation.
	Stores original position and calculates mouse offset for smooth dragging.
	"""
	is_being_dragged = true

	# Debug: Print positions before drag
	print("CardUI: Start drag - position: %v, base_position: %v, global_position: %v" % [position, base_position, global_position])
	if get_parent():
		print("  Parent global_position: %v" % get_parent().global_position)

	# Store current GLOBAL position before going top-level
	# This is where the card actually appears on screen
	var current_global_pos = global_position
	original_position = current_global_pos
	original_rotation = base_rotation

	print("  Stored original_position: %v" % original_position)

	# Make this card render on top and move freely
	set_as_top_level(true)
	z_index = 100

	# CRITICAL: Set position to global coordinates after set_as_top_level
	# When top-level, position is in global space, not local to parent
	global_position = current_global_pos

	print("  After set_as_top_level - set global_position to: %v" % global_position)

	# Calculate offset between card center and mouse position
	var mouse_pos = get_global_mouse_position()
	drag_offset = global_position - mouse_pos

	print("  Mouse position: %v, drag_offset: %v" % [mouse_pos, drag_offset])

	# Reset rotation when dragging (cards should be flat when being dragged)
	rotation = 0.0

	# Visual feedback: slightly reduce scale while dragging
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", drag_scale, 0.1)

	# Emit hover signal
	card_hovered.emit(card_data.get("id", ""))


func _end_drag() -> void:
	"""
	Completes drag operation.
	Checks if card was dropped on a champion target.
	If valid target: emit card_dropped signal
	If invalid target: return card to original position in hand
	"""
	is_being_dragged = false

	# Check if we have a valid champion target
	if selected_champion_index >= 0:
		# Valid drop on champion
		var target_indices: Array[int] = []

		# Add any additional target information if needed
		# (e.g., if card targets multiple units)
		if card_data.has("target_indices"):
			var raw_targets = card_data.get("target_indices", [])
			for t in raw_targets:
				if t is int:
					target_indices.append(t)

		# Emit the drop signal
		card_dropped.emit(
			card_data.get("id", ""),
			selected_champion_index,
			target_indices
		)

		# Reset selection
		selected_champion_index = -1

	# Return to normal rendering mode
	set_as_top_level(false)
	z_index = 0

	# IMPORTANT: After set_as_top_level(false), position is now in local space
	# Set position and rotation directly to base transform (no lerp needed)
	position = base_position
	rotation = base_rotation

	# Update original_position to match where we just moved the card
	# This prevents the _process lerp from moving it elsewhere
	original_position = global_position

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", normal_scale, animation_speed)


# ============================================================================
# HOVER EFFECTS
# ============================================================================

func _on_mouse_entered() -> void:
	"""
	Called when mouse enters the card area.
	Enlarges the card for preview and highlights it.
	"""
	is_hovered = true

	# Only apply hover scale if not currently dragging
	if not is_being_dragged:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", hover_scale, animation_speed)


func _on_mouse_exited() -> void:
	"""
	Called when mouse leaves the card area.
	Returns card to normal size.
	"""
	is_hovered = false

	# Only apply normal scale if not currently dragging
	if not is_being_dragged:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", normal_scale, animation_speed)


# ============================================================================
# CHAMPION COLOR MAPPING
# ============================================================================

func get_champion_color(champion_id: String) -> Color:
	"""
	Returns the visual color associated with a champion.
	Colors are used to theme the card background.

	Args:
		champion_id: The unique identifier of the champion

	Returns:
		Color: RGBA color for the champion, or default gray if not found
	"""
	# Color mapping for different champions (matches data/champions.json)
	var champion_colors: Dictionary = {
		"warrior": Color(1.0, 0.2, 0.2, 0.9),      # Red
		"defender": Color(0.2, 0.4, 1.0, 0.9),    # Blue
		"healer": Color(0.2, 1.0, 0.2, 0.9),      # Green
		"fire_knight": Color(1.0, 0.6, 0.2, 0.9)  # Orange
	}

	# Return color if champion exists, otherwise default gray
	if champion_colors.has(champion_id):
		return champion_colors[champion_id]
	else:
		return Color(0.5, 0.5, 0.5, 0.8)  # Default gray


# ============================================================================
# UTILITY METHODS
# ============================================================================

func set_champion_target(champion_index: int) -> void:
	"""
	Sets the currently targeted champion for card dropping.

	Args:
		champion_index: Index of the champion (-1 to clear selection)
	"""
	selected_champion_index = champion_index

	# Visual feedback: highlight when champion is selected
	if selected_champion_index >= 0 and background_panel:
		background_panel.modulate = Color(1.2, 1.2, 1.2, 1.0)  # Brighten
	elif background_panel:
		background_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Normal


func clear_champion_target() -> void:
	"""
	Clears the currently selected champion target.
	"""
	set_champion_target(-1)


func get_card_id() -> String:
	"""
	Returns the ID of the card represented by this widget.

	Returns:
		String: The card's unique identifier
	"""
	return card_data.get("id", "")


func get_card_cost() -> int:
	"""
	Returns the mana/resource cost of the card.

	Returns:
		int: The card's cost
	"""
	return card_data.get("cost", 0)


func set_base_transform(pos: Vector2, rot: float) -> void:
	"""
	Sets the base position and rotation for this card in the hand.
	Called by HandUI when arranging cards in fan layout.

	Args:
		pos: The base position in the hand
		rot: The base rotation angle in radians
	"""
	base_position = pos
	base_rotation = rot

	# Also immediately apply the transform if not currently dragging
	if not is_being_dragged:
		position = base_position
		rotation = base_rotation
		# Update original_position so _process doesn't move it
		original_position = global_position


# ============================================================================
# CHAMPION HOVER DETECTION
# ============================================================================

func _check_champion_hover() -> void:
	"""
	Check if mouse is hovering over a champion display during drag.
	Updates selected_champion_index and highlights the champion.
	"""
	# Find all champion displays in the scene
	var battle_scene = get_tree().current_scene
	if not battle_scene:
		return

	var champions_container = battle_scene.get_node_or_null("ChampionsContainer")
	if not champions_container:
		return

	var mouse_pos = get_global_mouse_position()
	var new_champion_index = -1

	# Check each champion display
	for i in range(champions_container.get_child_count()):
		var champion_display = champions_container.get_child(i)
		if champion_display and champion_display.has_method("get_global_rect"):
			var rect = champion_display.get_global_rect()
			if rect.has_point(mouse_pos):
				new_champion_index = i
				break

	# Update highlight if champion changed
	if new_champion_index != selected_champion_index:
		# Clear old highlight
		if selected_champion_index >= 0 and selected_champion_index < champions_container.get_child_count():
			var old_display = champions_container.get_child(selected_champion_index)
			if old_display and old_display.has_method("set_highlighted"):
				old_display.set_highlighted(false)

		# Set new highlight
		selected_champion_index = new_champion_index
		if selected_champion_index >= 0:
			var new_display = champions_container.get_child(selected_champion_index)
			if new_display and new_display.has_method("set_highlighted"):
				# Highlight with card's champion color
				new_display.set_highlighted(true)
