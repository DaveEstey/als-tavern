extends Control
## Enemy Display Widget
## Displays an enemy's current state during battle including HP, block, and status
##
## Scene Structure:
## EnemyDisplay (Control)
## ├── SpriteContainer (ColorRect) - Enemy sprite placeholder with type-based color
## ├── NameLabel (Label) - Enemy name display
## ├── HealthContainer (VBoxContainer)
## │   ├── HPBar (ProgressBar) - Health bar visual
## │   └── HPText (Label) - Current HP / Max HP text
## ├── BlockIndicator (Label) - Displays block value when > 0
## └── TypeBadge (Label) - Shows "BOSS", "ELITE", or hidden for trash

# Signals
signal enemy_clicked_for_targeting(enemy_index: int)

# Properties
var enemy_data: Dictionary = {}
var enemy_index: int = -1
var is_highlighted: bool = false
var is_dead: bool = false

# Node references
@onready var sprite_container: ColorRect = $SpriteContainer
@onready var name_label: Label = $NameLabel
@onready var hp_bar: ProgressBar = $HealthContainer/HPBar
@onready var hp_text: Label = $HealthContainer/HPText
@onready var block_indicator: Label = $BlockIndicator
@onready var type_badge: Label = $TypeBadge

# Color palette for different enemy types
const ENEMY_TYPE_COLORS = {
	"trash": Color(0.7, 0.7, 0.7),      # Light gray
	"elite": Color(1.0, 0.65, 0.0),     # Orange
	"boss": Color(0.9, 0.2, 0.2),       # Red
	"default": Color(0.5, 0.5, 0.5)     # Medium gray
}

const HIGHLIGHT_COLOR = Color.YELLOW
const NORMAL_MODULATE = Color.WHITE


func _ready() -> void:
	## Initialize the widget and set up input handling
	gui_input.connect(_on_gui_input)
	mouse_filter = Control.MOUSE_FILTER_STOP


func initialize(enemy: Dictionary, index: int) -> void:
	## Initialize this widget with enemy data
	## Args:
	##   enemy: Dictionary containing enemy information (name, hp, max_hp, type, block, etc.)
	##   index: Integer index of this enemy in the battle
	enemy_data = enemy.duplicate()
	enemy_index = index
	is_dead = false
	is_highlighted = false

	update_display()


func update_display() -> void:
	## Refresh all visual elements based on current enemy data
	if enemy_data.is_empty():
		return

	# Update name
	name_label.text = enemy_data.get("name", "Unknown Enemy")

	# Update sprite container color based on enemy type
	var enemy_type: String = enemy_data.get("type", "default")
	sprite_container.color = ENEMY_TYPE_COLORS.get(enemy_type, ENEMY_TYPE_COLORS["default"])

	# Update HP bar and text
	var current_hp: int = enemy_data.get("current_hp", 0)
	var max_hp: int = enemy_data.get("max_hp", 1)

	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_text.text = "%d / %d" % [current_hp, max_hp]

	# Update block indicator visibility and value
	var block: int = enemy_data.get("block", 0)
	if block > 0:
		block_indicator.text = "Block: %d" % block
		block_indicator.show()
	else:
		block_indicator.hide()

	# Update type badge based on enemy type
	var badge_text: String = _get_type_badge_text(enemy_type)
	if badge_text:
		type_badge.text = badge_text
		type_badge.show()
	else:
		type_badge.hide()


func set_highlighted(value: bool) -> void:
	## Show or hide the targeting highlight effect
	## Args:
	##   value: true to highlight, false to remove highlight
	is_highlighted = value

	if is_highlighted:
		# Add highlight effect
		modulate = HIGHLIGHT_COLOR
		# Optional: add border or outline effect here
	else:
		# Remove highlight
		modulate = NORMAL_MODULATE


func mark_dead() -> void:
	## Play death animation and fade out the enemy display
	is_dead = true

	# Disable input when dead
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Create fade-out animation
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): queue_free())


func _on_gui_input(event: InputEvent) -> void:
	## Handle input events for enemy targeting
	## Emits enemy_clicked_for_targeting signal on left mouse button click
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not is_dead:
				enemy_clicked_for_targeting.emit(enemy_index)
				get_tree().root.set_input_as_handled()


func _get_type_badge_text(enemy_type: String) -> String:
	## Get the badge text for the enemy type
	## Args:
	##   enemy_type: String identifier for the enemy type
	## Returns:
	##   The badge text ("BOSS", "ELITE", or empty string for trash)
	match enemy_type:
		"boss":
			return "BOSS"
		"elite":
			return "ELITE"
		_:
			return ""
