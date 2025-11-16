extends Node2D

@export var noise_height_texture : NoiseTexture2D
@export var grassThreshold : float = 0.3
@export var visible_tiles : Vector2i = Vector2i(32, 18)
@export var border_thickness : int = 2
@export var future_column_buffer : int = 5
@export var base_scroll_speed : float = 40.0
@export var scroll_acceleration : float = 2.0
@export var boundary_wall_thickness : float = 256.0

var noise : Noise
var tile_size_px : int = 32
var scroll_offset_px : float = 0.0
var play_min_x : int
var play_max_x : int
var play_min_y : int
var play_max_y : int
var play_width : int
var play_height : int
var world_left_column : int
var world_right_column : int
var generated_width : int
var camera_half_view : Vector2 = Vector2.ZERO
var game_over : bool = false

@onready var tile_map = $TileMap
@onready var boundary_map = $BoundaryTileMap
@onready var player = $Player
@onready var camera = $GameCamera
@onready var water_layer = $WaterShaderLayer
@onready var screen_bounds = $ScreenBounds
@onready var left_bound = $ScreenBounds/LeftBound
@onready var right_bound = $ScreenBounds/RightBound
@onready var top_bound = $ScreenBounds/TopBound
@onready var bottom_bound = $ScreenBounds/BottomBound

var current_scroll_speed : float = 0.0


var source_id = 2
var outer_atlas = Vector2i(0,2)
var water_atlas = Vector2i(0,1)
var sand_atlas = Vector2i(0,0)
var grass_atlas = Vector2i(1,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	noise_height_texture.noise.set_seed(randi_range(0, 100000))
	noise = noise_height_texture.noise
	tile_size_px = tile_map.tile_set.tile_size.x
	current_scroll_speed = base_scroll_speed
	if player:
		player.landed.connect(_on_player_landed)
	_configure_camera()
	generateWorld(0,0)
	if Hud:
		Hud.start_timer()
	pass 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_over:
		return
	current_scroll_speed += scroll_acceleration * delta
	_scroll_world(delta)
	_check_player_bounds()
	
	
func generateWorld(origin_x, origin_y):
	var border = max(border_thickness, 1)
	var future_columns = max(future_column_buffer, 0)
	var half_width = int(visible_tiles.x / 2)
	var half_height = int(visible_tiles.y / 2)
	play_min_x = origin_x - half_width
	play_max_x = origin_x + half_width
	play_min_y = origin_y - half_height
	play_max_y = origin_y + half_height
	play_width = play_max_x - play_min_x
	play_height = play_max_y - play_min_y
	generated_width = play_width + future_columns
	var generated_max_x = play_min_x + generated_width
	world_left_column = play_min_x
	world_right_column = generated_max_x - 1
	scroll_offset_px = 0.0
	tile_map.position = Vector2.ZERO
	water_layer.position = Vector2.ZERO
	tile_map.clear()
	boundary_map.clear()
	
	# build the playable section
	for x in range(play_min_x, generated_max_x):
		for y in range(play_min_y, play_max_y):
			tile_map.set_cell(0, Vector2i(x,y), source_id, water_atlas)
			
			var noise_val : float = noise.get_noise_2d(x,y)
			
			if noise_val >= 0.0 and noise_val <= grassThreshold:
				tile_map.set_cell(1, Vector2i(x,y), source_id, sand_atlas)
			elif noise_val > grassThreshold:
				tile_map.set_cell(1, Vector2i(x,y), source_id, grass_atlas)
			else:
				tile_map.erase_cell(1, Vector2i(x,y))
	
	_build_boundaries(border)
	pass


func _configure_camera():
	if not camera:
		return
	var tile_size = tile_map.tile_set.tile_size
	var view_size = Vector2(visible_tiles.x * tile_size.x, visible_tiles.y * tile_size.y)
	var half_view = view_size / 2.0
	camera_half_view = half_view
	camera.position = Vector2.ZERO
	camera.limit_left = -half_view.x
	camera.limit_right = half_view.x
	camera.limit_top = -half_view.y
	camera.limit_bottom = half_view.y
	camera.zoom = Vector2.ONE
	camera.make_current()
	_configure_screen_bounds(half_view)


func _scroll_world(delta):
	if current_scroll_speed <= 0:
		return
	scroll_offset_px += current_scroll_speed * delta
	while scroll_offset_px >= tile_size_px:
		scroll_offset_px -= tile_size_px
		_shift_world_columns()
	var offset = -scroll_offset_px
	tile_map.position.x = offset


func _shift_world_columns():
	if generated_width <= 0:
		return
	for layer in [0, 1]:
		_copy_layer_left(layer)
	world_left_column += 1
	world_right_column += 1
	var new_world_x = world_right_column
	_populate_column(new_world_x)


func _copy_layer_left(layer_index : int):
	for y in range(play_min_y, play_max_y):
		for x in range(play_min_x, play_min_x + generated_width - 1):
			var from = Vector2i(x + 1, y)
			var to = Vector2i(x, y)
			var source = tile_map.get_cell_source_id(layer_index, from)
			if source == -1:
				tile_map.erase_cell(layer_index, to)
			else:
				var atlas = tile_map.get_cell_atlas_coords(layer_index, from)
				var alternative = tile_map.get_cell_alternative_tile(layer_index, from)
				tile_map.set_cell(layer_index, to, source, atlas, alternative)
		tile_map.erase_cell(layer_index, Vector2i(play_min_x + generated_width - 1, y))


func _populate_column(world_x : int):
	var local_x = play_min_x + generated_width - 1
	for y in range(play_min_y, play_max_y):
		var coords = Vector2i(local_x, y)
		tile_map.set_cell(0, coords, source_id, water_atlas)
		var noise_val : float = noise.get_noise_2d(world_x, y)
		if noise_val >= 0.0 and noise_val <= grassThreshold:
			tile_map.set_cell(1, coords, source_id, sand_atlas)
		elif noise_val > grassThreshold:
			tile_map.set_cell(1, coords, source_id, grass_atlas)
		else:
			tile_map.erase_cell(1, coords)


func _build_boundaries(border : int):
	var boundary_min_x = play_min_x - border
	var boundary_max_x = play_max_x + border
	var boundary_min_y = play_min_y - border
	var boundary_max_y = play_max_y + border
	for x in range(boundary_min_x, boundary_max_x):
		for y in range(boundary_min_y, boundary_max_y):
			if x < play_min_x or x >= play_max_x or y < play_min_y or y >= play_max_y:
				boundary_map.set_cell(0, Vector2i(x,y), source_id, outer_atlas)


func _configure_screen_bounds(half_view : Vector2):
	if not screen_bounds:
		return
	var thickness = boundary_wall_thickness
	var vertical_height = half_view.y * 2.0 + thickness * 2.0
	var horizontal_width = half_view.x * 2.0 + thickness * 2.0
	if left_bound and left_bound.shape:
		left_bound.position = Vector2(-half_view.x - thickness * 0.5, 0)
		left_bound.shape.size = Vector2(thickness, vertical_height)
	if right_bound and right_bound.shape:
		right_bound.position = Vector2(half_view.x + thickness * 0.5, 0)
		right_bound.shape.size = Vector2(thickness, vertical_height)
	if top_bound and top_bound.shape:
		top_bound.position = Vector2(0, -half_view.y - thickness * 0.5)
		top_bound.shape.size = Vector2(horizontal_width, thickness)
	if bottom_bound and bottom_bound.shape:
		bottom_bound.position = Vector2(0, half_view.y + thickness * 0.5)
		bottom_bound.shape.size = Vector2(horizontal_width, thickness)


func _check_player_bounds():
	if not player or game_over:
		return
	var player_pos = player.get_body_position()
	if player_pos.x <= -camera_half_view.x:
		trigger_game_over("Left boundary")


func _on_player_landed(position : Vector2):
	if game_over:
		return
	var cell = tile_map.local_to_map(tile_map.to_local(position))
	if tile_map.get_cell_source_id(1, cell) != -1:
		trigger_game_over("Landed on land")


func trigger_game_over(_reason : String = ""):
	if game_over:
		return
	game_over = true
	current_scroll_speed = 0.0
	var time_text = ""
	if Hud:
		time_text = Hud.get_formatted_time()
		Hud.show_game_over(time_text)
	else:
		get_tree().paused = true
