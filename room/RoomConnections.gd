extends Node
class_name RoomConnections


static func distance_between(start_room: Room, end_room: Room) -> int:
	## Returns the shortest path between two rooms (using a breadth-first search). If no path is found, returns -1.
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
				queue.append([adjacent_room, current[1] + 1])
				explored.append(adjacent_room)

	return -1


static func find_connector_pairing(current_room_connectors: Array[Connector], all_connectors: Array[Connector], max_distance: int) -> Array[Connector]:
	## loop through all connectors (in the entire game),
	## and find first two connectors that are in range of each other.
	## If found, returns a list containing both connectors, and an empty list otherwise.
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
