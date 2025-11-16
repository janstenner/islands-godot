extends State
class_name PlayerHammering

@onready var animation_player = $"../../AnimationPlayer"
@onready var player : Player = $"../.."

var particle_scene = preload("res://scenes/explosion_land.tscn")
const HAMMER_RADIUS : float = 60.0
var _is_hammering : bool = false


func Enter():
	# TODO add AudioManager to Player
	# AudioManager.play_sound(AudioManager.PLAYER_ATTACK_SWING, 0.3, 1)
	
	_is_hammering = true
	await _hammer_loop()
	if player and player.consume_jump_request():
		state_transition.emit(self, "PlayerJumping")
	else:
		state_transition.emit(self, "PlayerIdle")


func Exit():
	_is_hammering = false


func _hammer_loop():
	while _is_hammering:
		animation_player.play("hammer_animation")
		await animation_player.animation_finished
		_perform_hammer_hit()
		if not Input.is_action_pressed("Hammer"):
			_is_hammering = false


func _perform_hammer_hit():
	var tile_map = get_node("/root/World/TileMap")
	var world = get_node("/root/World")
	if not player or not tile_map or not world:
		return
	var tiles_to_remove = []
	var layer_index = 1
	var player_position : Vector2 = player.get_body_position()
	var tile_size = tile_map.tile_set.tile_size
	var radius_tiles = int(ceil(HAMMER_RADIUS / max(tile_size.x, tile_size.y)))
	var player_cell = tile_map.local_to_map(tile_map.to_local(player_position))
	var hit_land = false

	for x in range(player_cell.x - radius_tiles, player_cell.x + radius_tiles + 1):
		for y in range(player_cell.y - radius_tiles, player_cell.y + radius_tiles + 1):
			var cell = Vector2i(x, y)
			var source_id = tile_map.get_cell_source_id(layer_index, cell)
			if source_id == -1:
				continue
			var tile_position = tile_map.map_to_local(cell)
			if tile_position.distance_to(player_position) <= HAMMER_RADIUS:
				tiles_to_remove.append(cell)
				var temp_particle = particle_scene.instantiate()
				var world_space_position = tile_map.to_global(tile_position)
				temp_particle.position = world.to_local(world_space_position)
				world.add_child(temp_particle)
				hit_land = true
			
	for tile_pos in tiles_to_remove:
		tile_map.erase_cell(layer_index, tile_pos)
	
	if hit_land and player:
		player.queue_jump()
