extends Node
class_name RoomConnections


static var RoomCategory = RoomData.RoomCategory
static var RoomType = RoomData.RoomType

## Returns true if <placed_room> can be placed adjacent to <connecting_room>, or false otherwise.
static func check_placement_rules(placed_room: Room, connecting_room: Room) -> bool:
	# these two exist to make checking easier when e.g. comparing only the categories with has()
	var room_categories = [placed_room.room_category, connecting_room.room_category]
	var room_types = [placed_room.room_type, connecting_room.room_type]

	if room_categories.has(RoomCategory.LUXURY_ROOM) and room_categories.has(RoomCategory.MAINTENANCE_ROOM):
		print("Room placement failed: Cannot place Luxury Room next to a Maintenance Room.")
		return false

	if placed_room.room_type == RoomType.CANTEEN:
		if connecting_room.room_category != RoomCategory.CREW_ROOM:
			print("Room placement failed: Canteens must be adjacent to Crew Rooms.")
			return false
	elif connecting_room.room_type == RoomType.CANTEEN:
		if placed_room.room_category != RoomCategory.CREW_ROOM:
			print("Room placement failed: Canteens must be adjacent to Crew Rooms.")
			return false

	return true



## Returns the length of the shortest path between two rooms (using a breadth-first search). If no path is found, returns -1.
## If <allowed_rooms> is set, only rooms that are included in the array are considered for the path.
static func distance_between(start_room: Room, end_room: Room, allowed_rooms: Array[RoomData.RoomCategory] = []) -> int:
	var queue = [] # Contains [room: Room, distance_from_starting_room: int] pairs
	var explored = []

	queue.append([start_room, 0])
	explored.append(start_room)

	while len(queue) > 0:
		var current: Array[Variant] = queue.pop_front()
		if current[0] == end_room:
			return current[1]
		for adjacent_room: Room in current[0].adjacent_rooms:
			if adjacent_room not in explored:
				if len(allowed_rooms) > 0 and adjacent_room.room_category not in allowed_rooms:
					continue
				queue.append([adjacent_room, current[1] + 1])
				explored.append(adjacent_room)
	return -1


## Returns the nearest room of type <end_room_type>, and the path length. If no path is found, returns an empty Array.
## If <allowed_rooms> is set, only rooms that are included in the array are considered for the path.
static func find_nearest_room_type(start_room: Room, end_room_type: RoomData.RoomType, allowed_rooms: Array[RoomData.RoomCategory] = []) -> Array:
	var queue = [] # Contains [room: Room, distance_from_starting_room: int] pairs
	var explored = []

	queue.append([start_room, 0])
	explored.append(start_room)

	while len(queue) > 0:
		var current: Array[Variant] = queue.pop_front()
		if current[0].room_type == end_room_type:
			return [current[0], current[1]]
		for adjacent_room: Room in current[0].adjacent_rooms:
			if adjacent_room not in explored:
				if len(allowed_rooms) > 0 and adjacent_room.room_category not in allowed_rooms:
					continue
				queue.append([adjacent_room, current[1] + 1])
				explored.append(adjacent_room)
	return []


## Returns all rooms within <range> of <start_room>, not including <start_room>.
static func get_nearby_rooms(start_room: Room, search_range: int) -> Array[Room]:
	var queue = [] # Contains [room: Room, distance_from_starting_room: int] pairs
	var explored: Array[Room] = []

	queue.append([start_room, 0])
	explored.append(start_room)

	while len(queue) > 0:
		var current: Array[Variant] = queue.pop_front()
		if current[1] == search_range:
			explored.erase(start_room)
			return explored
		for adjacent_room: Room in current[0].adjacent_rooms:
			if adjacent_room not in explored:
				queue.append([adjacent_room, current[1] + 1])
				explored.append(adjacent_room)

	explored.erase(start_room)
	return explored


## loop through all connectors (in the entire game),
## and find first two connectors that are in range of each other.
## If found, returns a list containing both connectors, and an empty list otherwise.
static func find_connector_pairing(current_room_connectors: Array[Connector], all_connectors: Array[Connector], max_distance: int) -> Array[Connector]:
	var closest_pair: Array[Connector] = []
	var closest_pair_distance = null
	for own_connector: Area2D in current_room_connectors:
		for other_connector: Area2D in all_connectors:
			if other_connector in current_room_connectors:
				continue
			var distance = own_connector.global_position.distance_to(other_connector.global_position)
			if distance < max_distance and (len(closest_pair) == 0 or distance < closest_pair_distance):
				## NOTE: Remember that own_connector must be first in the list!
				closest_pair = [own_connector, other_connector]
				closest_pair_distance = distance
	if closest_pair:
		return closest_pair
	return []
