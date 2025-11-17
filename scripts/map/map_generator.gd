extends Node
class_name MapGenerator

## Generates a procedural node-based map (Slay the Spire style)

# Map dimensions
@export var map_width: int = 6
@export var map_height: int = 20

# Available node types
var node_types: Array = ["battle", "elite", "boss", "rest", "shop", "shrine", "treasure"]

# Internal storage
var nodes: Array[Dictionary] = []
var node_id_counter: int = 0


## Generate a complete map with connected nodes
func generate_map() -> Array[Dictionary]:
	nodes.clear()
	node_id_counter = 0

	# Generate nodes in a grid-like structure with branching paths
	_generate_node_grid()

	# Generate connections between nodes
	_generate_paths()

	# Place special nodes according to rules
	_place_special_nodes()

	return nodes


## Create a single node with given parameters
func _create_node(id: int, type: String, pos: Vector2i) -> Dictionary:
	return {
		"id": id,
		"type": type,
		"position": pos,
		"connections": [],
		"visited": false,
		"encounter_chance": 0.3 if type == "battle" else 0.0
	}


## Generate the initial grid of nodes
func _generate_node_grid() -> void:
	# Calculate nodes per row (varies for branching)
	var rows: int = map_height

	# Start node at bottom (row 0)
	var start_node: Dictionary = _create_node(
		node_id_counter,
		"rest",  # Will be set in _place_special_nodes, but starting as rest
		Vector2i(map_width / 2, 0)
	)
	nodes.append(start_node)
	node_id_counter += 1

	# Generate middle rows with varying column positions
	for row in range(1, rows - 1):
		# Number of nodes in this row (2-4 nodes for branching paths)
		var nodes_in_row: int = randi_range(2, min(4, map_width))

		# Distribute nodes across columns
		var column_spacing: float = float(map_width - 1) / float(nodes_in_row - 1) if nodes_in_row > 1 else 0.0

		for i in range(nodes_in_row):
			var column: int = int(i * column_spacing) if nodes_in_row > 1 else map_width / 2
			# Add some randomness to column position
			if nodes_in_row > 1 and row > 1:
				column = clampi(column + randi_range(-1, 1), 0, map_width - 1)

			var node: Dictionary = _create_node(
				node_id_counter,
				"battle",  # Default type, will be overridden in _place_special_nodes
				Vector2i(column, row)
			)
			nodes.append(node)
			node_id_counter += 1

	# Boss node at top (last row)
	var boss_node: Dictionary = _create_node(
		node_id_counter,
		"boss",
		Vector2i(map_width / 2, rows - 1)
	)
	nodes.append(boss_node)
	node_id_counter += 1


## Connect nodes to create paths through the map
func _generate_paths() -> void:
	# Group nodes by row
	var rows: Dictionary = {}
	for node in nodes:
		var row: int = node["position"].y
		if not rows.has(row):
			rows[row] = []
		rows[row].append(node)

	# Connect each row to the next
	for row in range(map_height - 1):
		if not rows.has(row) or not rows.has(row + 1):
			continue

		var current_row: Array = rows[row]
		var next_row: Array = rows[row + 1]

		# Each node connects to 1-3 nodes in the next row
		for node in current_row:
			var connections_made: int = 0
			var target_connections: int = randi_range(1, min(3, next_row.size()))

			# Find closest nodes in next row
			var next_nodes_by_distance: Array = next_row.duplicate()
			next_nodes_by_distance.sort_custom(func(a, b):
				var dist_a = abs(a["position"].x - node["position"].x)
				var dist_b = abs(b["position"].x - node["position"].x)
				return dist_a < dist_b
			)

			# Connect to closest nodes
			for i in range(min(target_connections, next_nodes_by_distance.size())):
				var target_node: Dictionary = next_nodes_by_distance[i]
				if not node["connections"].has(target_node["id"]):
					node["connections"].append(target_node["id"])
					connections_made += 1

		# Ensure all nodes in next row have at least one incoming connection
		for next_node in next_row:
			var has_incoming: bool = false
			for node in current_row:
				if node["connections"].has(next_node["id"]):
					has_incoming = true
					break

			if not has_incoming and current_row.size() > 0:
				# Connect from nearest node in current row
				var nearest_node: Dictionary = current_row[0]
				var min_dist: int = abs(nearest_node["position"].x - next_node["position"].x)

				for node in current_row:
					var dist: int = abs(node["position"].x - next_node["position"].x)
					if dist < min_dist:
						min_dist = dist
						nearest_node = node

				if not nearest_node["connections"].has(next_node["id"]):
					nearest_node["connections"].append(next_node["id"])


## Place special nodes according to game rules
func _place_special_nodes() -> void:
	# Start node is already rest (set in generation)
	# Boss node is already set

	# Find indices of non-start, non-boss nodes
	var middle_nodes: Array[int] = []
	for i in range(nodes.size()):
		var node: Dictionary = nodes[i]
		if node["position"].y > 0 and node["position"].y < map_height - 1:
			middle_nodes.append(i)

	# Shuffle for random placement
	middle_nodes.shuffle()

	# Calculate number of special nodes
	var num_rest: int = int(map_height / 6.0)  # Every ~5-7 nodes
	var num_shop: int = int(map_height / 7.0)  # Every ~6-8 nodes
	var num_shrine: int = randi_range(1, 2)
	var num_treasure: int = randi_range(1, 2)
	var num_elite: int = max(2, int(map_height / 8.0))  # Elite nodes before boss

	var placement_index: int = 0

	# Place rest nodes (evenly distributed)
	var rest_spacing: int = max(1, middle_nodes.size() / (num_rest + 1))
	for i in range(num_rest):
		if placement_index < middle_nodes.size():
			var node_idx: int = middle_nodes[min(placement_index, middle_nodes.size() - 1)]
			nodes[node_idx]["type"] = "rest"
			placement_index += rest_spacing

	# Place shop nodes (evenly distributed, offset from rest)
	placement_index = rest_spacing / 2
	var shop_spacing: int = max(1, middle_nodes.size() / (num_shop + 1))
	for i in range(num_shop):
		if placement_index < middle_nodes.size():
			var node_idx: int = middle_nodes[min(placement_index, middle_nodes.size() - 1)]
			if nodes[node_idx]["type"] == "battle":  # Don't override rest nodes
				nodes[node_idx]["type"] = "shop"
			placement_index += shop_spacing

	# Place elite nodes (in upper third of map)
	var upper_third_start: int = int(middle_nodes.size() * 0.66)
	for i in range(num_elite):
		var idx: int = randi_range(upper_third_start, middle_nodes.size() - 1)
		if idx < middle_nodes.size():
			var node_idx: int = middle_nodes[idx]
			if nodes[node_idx]["type"] == "battle":  # Don't override special nodes
				nodes[node_idx]["type"] = "elite"

	# Place shrine and treasure nodes randomly
	var special_placed: int = 0
	for i in range(middle_nodes.size()):
		if special_placed >= num_shrine + num_treasure:
			break

		var node_idx: int = middle_nodes[i]
		if nodes[node_idx]["type"] == "battle":
			if special_placed < num_shrine:
				nodes[node_idx]["type"] = "shrine"
			else:
				nodes[node_idx]["type"] = "treasure"
			special_placed += 1

	# Remaining nodes stay as "battle"


## Get all nodes connected to the given node
func get_available_nodes(current_node_id: int) -> Array[Dictionary]:
	var current_node: Dictionary = get_node_by_id(current_node_id)
	if current_node.is_empty():
		return []

	var available: Array[Dictionary] = []
	for connected_id in current_node["connections"]:
		var connected_node: Dictionary = get_node_by_id(connected_id)
		if not connected_node.is_empty():
			available.append(connected_node)

	return available


## Find a node by its ID
func get_node_by_id(node_id: int) -> Dictionary:
	for node in nodes:
		if node["id"] == node_id:
			return node
	return {}


## Mark a node as visited
func mark_node_visited(node_id: int) -> void:
	var node: Dictionary = get_node_by_id(node_id)
	if not node.is_empty():
		node["visited"] = true


## Get the start node (always ID 0)
func get_start_node() -> Dictionary:
	return get_node_by_id(0)


## Get all boss nodes
func get_boss_nodes() -> Array[Dictionary]:
	var boss_nodes: Array[Dictionary] = []
	for node in nodes:
		if node["type"] == "boss":
			boss_nodes.append(node)
	return boss_nodes


## Check if a path exists from start to any boss node
func validate_map() -> bool:
	if nodes.is_empty():
		return false

	var boss_nodes: Array[Dictionary] = get_boss_nodes()
	if boss_nodes.is_empty():
		return false

	# Simple BFS to check connectivity
	var visited: Dictionary = {}
	var queue: Array[int] = [0]  # Start from node 0
	visited[0] = true

	while queue.size() > 0:
		var current_id: int = queue.pop_front()
		var current_node: Dictionary = get_node_by_id(current_id)

		if current_node["type"] == "boss":
			return true  # Found a path to boss

		for connected_id in current_node["connections"]:
			if not visited.has(connected_id):
				visited[connected_id] = true
				queue.append(connected_id)

	return false  # No path to boss found
