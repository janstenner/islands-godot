extends State
class_name PlayerIdle

@export var animator : AnimationPlayer

func Enter():
	pass
	
func Update(_delta : float):
	#if(Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown").normalized()):
		#state_transition.emit(self, "Moving")
		
	if Input.is_action_just_pressed("Hammer"):
		state_transition.emit(self, "PlayerHammering")

func Exit():
	var tile_map = get_node("/root/World/TileMap")
	var player = get_node("/root/World/Player")
	
	var tiles_to_remove = []
	var layer_index = 1

	# Iterate through all tiles in layer 1
	for i in tile_map.get_used_cells(layer_index):
		var tile_position = tile_map.map_to_local(i)
		var distance = tile_position.distance_to(player.global_position)
		if distance <= 60:
			tiles_to_remove.append(i)
	
	for tile_pos in tiles_to_remove:
		tile_map.erase_cell(layer_index, tile_pos)
	pass
