extends Control

## Shop UI - Map Node Interaction
## Allows players to purchase card upgrades, stat items, and card removal services
## Should be instantiated when player enters a shop node on the map

# ========================================
# SCENE STRUCTURE
# ========================================
# ShopUI (Control)
# ├── Panel (Panel) - Main background
# │   ├── MarginContainer
# │   │   ├── VBoxContainer
# │   │   │   ├── HeaderContainer (HBoxContainer)
# │   │   │   │   ├── TitleLabel (Label) - "Merchant's Shop"
# │   │   │   │   ├── Spacer (Control) - size_flags_horizontal = EXPAND
# │   │   │   │   ├── GoldLabel (Label) - "Gold: 100"
# │   │   │   │   └── CloseButton (Button) - "X"
# │   │   │   ├── HSeparator
# │   │   │   ├── ScrollContainer - size_flags_vertical = EXPAND
# │   │   │   │   └── ItemsGrid (GridContainer) - columns = 2
# │   │   │   │       └── [ShopItemCard instances added dynamically]
# │   │   │   └── FooterContainer (HBoxContainer)
# │   │   │       ├── InfoLabel (Label) - "Select an item to purchase"
# │   │   │       └── Spacer
# ========================================

# Signals
signal purchase_completed(item: Dictionary)
signal shop_closed()

# Node references
@onready var items_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ItemsGrid
@onready var gold_label: Label = $Panel/MarginContainer/VBoxContainer/HeaderContainer/GoldLabel
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/HeaderContainer/CloseButton
@onready var info_label: Label = $Panel/MarginContainer/VBoxContainer/FooterContainer/InfoLabel

# Shop item structure
class ShopItem:
	var id: String
	var name: String
	var description: String
	var price: int
	var type: String  # "card_upgrade", "stat_item", "card_removal"
	var icon_path: String

	func _init(p_id: String, p_name: String, p_desc: String, p_price: int, p_type: String, p_icon: String = "") -> void:
		id = p_id
		name = p_name
		description = p_desc
		price = p_price
		type = p_type
		icon_path = p_icon

# Properties
var shop_items: Array[ShopItem] = []
var player_gold: int = 0
var purchased_items: Array[String] = []  # Track purchased item IDs to prevent repurchase

# ========================================
# LIFECYCLE METHODS
# ========================================

func _ready() -> void:
	_initialize_shop_items()
	_setup_connections()
	populate_shop()
	update_gold_display()

func _setup_connections() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

# ========================================
# INITIALIZATION
# ========================================

func _initialize_shop_items() -> void:
	"""Initialize the default shop inventory with various items"""
	shop_items.clear()

	# Card Upgrades (50 gold)
	shop_items.append(ShopItem.new(
		"upgrade_card_1",
		"Card Upgrade Token",
		"Upgrade any card in your deck to its enhanced version. +Damage or special effects.",
		50,
		"card_upgrade",
		"res://assets/icons/card_upgrade.png"
	))

	shop_items.append(ShopItem.new(
		"upgrade_card_2",
		"Rare Card Upgrade",
		"Upgrade a rare card to legendary status. Significantly enhanced effects.",
		50,
		"card_upgrade",
		"res://assets/icons/rare_upgrade.png"
	))

	# Stat Items (100 gold)
	shop_items.append(ShopItem.new(
		"stat_max_hp",
		"Vitality Potion",
		"Permanently increase maximum HP by 10. Champions grow stronger!",
		100,
		"stat_item",
		"res://assets/icons/vitality.png"
	))

	shop_items.append(ShopItem.new(
		"stat_draw_card",
		"Tome of Knowledge",
		"Draw 1 additional card each turn for the rest of your journey.",
		100,
		"stat_item",
		"res://assets/icons/tome.png"
	))

	shop_items.append(ShopItem.new(
		"stat_energy",
		"Energy Crystal",
		"Gain +1 energy at the start of each battle. More actions per turn!",
		100,
		"stat_item",
		"res://assets/icons/energy_crystal.png"
	))

	# Card Removal (75 gold)
	shop_items.append(ShopItem.new(
		"remove_card_1",
		"Card Removal Service",
		"Remove any card from your deck. Streamline your strategy!",
		75,
		"card_removal",
		"res://assets/icons/card_remove.png"
	))

	shop_items.append(ShopItem.new(
		"remove_card_2",
		"Bulk Card Removal",
		"Remove up to 2 cards from your deck. Perfect for deck refinement.",
		75,
		"card_removal",
		"res://assets/icons/bulk_remove.png"
	))

# ========================================
# SHOP POPULATION
# ========================================

func populate_shop() -> void:
	"""Clear and repopulate the shop grid with available items"""
	if not items_grid:
		push_error("ShopUI: ItemsGrid node not found!")
		return

	# Clear existing items
	for child in items_grid.get_children():
		child.queue_free()

	# Create item cards for each shop item
	for item in shop_items:
		var item_card: Control = _create_item_card(item)
		items_grid.add_child(item_card)

	info_label.text = "Browse the merchant's wares - Select an item to purchase"

func _create_item_card(item: ShopItem) -> Control:
	"""Create a visual card for a shop item"""
	var card: Panel = Panel.new()
	card.custom_minimum_size = Vector2(280, 180)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Item type badge
	var type_label: Label = Label.new()
	type_label.text = _get_type_display_name(item.type)
	type_label.add_theme_color_override("font_color", _get_type_color(item.type))
	type_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(type_label)

	# Item name
	var name_label: Label = Label.new()
	name_label.text = item.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	# Item description
	var desc_label: Label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_label)

	# Spacer
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Price and purchase button container
	var bottom_container: HBoxContainer = HBoxContainer.new()
	vbox.add_child(bottom_container)

	# Price label
	var price_label: Label = Label.new()
	price_label.text = str(item.price) + " Gold"
	price_label.add_theme_font_size_override("font_size", 14)
	price_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0))
	bottom_container.add_child(price_label)

	# Spacer
	var h_spacer: Control = Control.new()
	h_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_container.add_child(h_spacer)

	# Purchase button
	var buy_button: Button = Button.new()
	buy_button.text = "Purchase"
	buy_button.disabled = item.id in purchased_items or player_gold < item.price
	buy_button.pressed.connect(_on_item_purchased.bind(item))
	bottom_container.add_child(buy_button)

	return card

func _get_type_display_name(type: String) -> String:
	"""Convert type ID to display name"""
	match type:
		"card_upgrade":
			return "CARD UPGRADE"
		"stat_item":
			return "STAT BOOST"
		"card_removal":
			return "REMOVAL SERVICE"
		_:
			return "ITEM"

func _get_type_color(type: String) -> Color:
	"""Get color for item type badge"""
	match type:
		"card_upgrade":
			return Color(0.4, 0.7, 1.0)  # Blue
		"stat_item":
			return Color(0.8, 0.4, 1.0)  # Purple
		"card_removal":
			return Color(1.0, 0.6, 0.3)  # Orange
		_:
			return Color.WHITE

# ========================================
# PURCHASE HANDLING
# ========================================

func _on_item_purchased(item: ShopItem) -> void:
	"""Handle item purchase attempt"""
	# Validate purchase
	if player_gold < item.price:
		_show_info_message("Not enough gold!", Color.RED)
		return

	if item.id in purchased_items:
		_show_info_message("Already purchased!", Color.ORANGE)
		return

	# Process purchase
	player_gold -= item.price
	purchased_items.append(item.id)

	# Update UI
	update_gold_display()
	populate_shop()  # Refresh to show updated button states

	# Show feedback
	_show_info_message("Purchased: " + item.name, Color.GREEN)

	# Emit signal with item data
	var item_data: Dictionary = {
		"id": item.id,
		"name": item.name,
		"type": item.type,
		"price": item.price,
		"description": item.description
	}
	purchase_completed.emit(item_data)

	print("ShopUI: Item purchased - ", item.name, " for ", item.price, " gold")

# ========================================
# UI UPDATES
# ========================================

func update_gold_display() -> void:
	"""Update the gold label with current player gold"""
	if gold_label:
		gold_label.text = "Gold: " + str(player_gold)

func _show_info_message(message: String, color: Color = Color.WHITE) -> void:
	"""Display a temporary info message"""
	if info_label:
		info_label.text = message
		info_label.add_theme_color_override("font_color", color)

# ========================================
# PUBLIC API
# ========================================

func set_player_gold(amount: int) -> void:
	"""Set the player's current gold amount"""
	player_gold = max(0, amount)
	update_gold_display()
	populate_shop()  # Refresh to update available items

func add_shop_item(id: String, name: String, description: String, price: int, type: String, icon: String = "") -> void:
	"""Add a custom item to the shop inventory"""
	var new_item := ShopItem.new(id, name, description, price, type, icon)
	shop_items.append(new_item)
	populate_shop()

func remove_shop_item(item_id: String) -> void:
	"""Remove an item from the shop inventory"""
	for i in range(shop_items.size()):
		if shop_items[i].id == item_id:
			shop_items.remove_at(i)
			populate_shop()
			return

func clear_purchased_items() -> void:
	"""Reset purchased items tracking (for new shop visit)"""
	purchased_items.clear()
	populate_shop()

# ========================================
# CLOSE HANDLING
# ========================================

func close_shop() -> void:
	"""Close the shop and emit signal"""
	shop_closed.emit()
	queue_free()

func _on_close_button_pressed() -> void:
	"""Handle close button press"""
	close_shop()
