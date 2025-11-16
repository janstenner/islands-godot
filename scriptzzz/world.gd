extends Node2D

@export var noise_height_texture : NoiseTexture2D
@export var grassThreshold : float = 0.3
@export var visible_tiles : Vector2i = Vector2i(32, 18)
@export var border_thickness : int = 1

var noise : Noise

@onready var tile_map = $TileMap
@onready var player = $Player
@onready var camera = $GameCamera


var source_id = 2
var outer_atlas = Vector2i(0,2)
var water_atlas = Vector2i(0,1)
var sand_atlas = Vector2i(0,0)
var grass_atlas = Vector2i(1,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	noise_height_texture.noise.set_seed(randi_range(0, 100000))
	noise = noise_height_texture.noise
	_configure_camera()
	generateWorld(0,0)
	pass 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	
	pass
	
	
func generateWorld(origin_x, origin_y):
	var border = max(border_thickness, 1)
	var half_width = int(visible_tiles.x / 2)
	var half_height = int(visible_tiles.y / 2)
	var play_min_x = origin_x - half_width
	var play_max_x = origin_x + half_width
	var play_min_y = origin_y - half_height
	var play_max_y = origin_y + half_height
	var boundary_min_x = play_min_x - border
	var boundary_max_x = play_max_x + border
	var boundary_min_y = play_min_y - border
	var boundary_max_y = play_max_y + border
	
	# clear existing cells before rebuilding the visible section
	tile_map.clear()
	
	# surround the playable area with blocking tiles on layer 2
	for x in range(boundary_min_x, boundary_max_x):
		for y in range(boundary_min_y, boundary_max_y):
			if x < play_min_x or x >= play_max_x or y < play_min_y or y >= play_max_y:
				tile_map.set_cell(2, Vector2i(x,y), source_id, outer_atlas)
	
	# build the playable section
	for x in range(play_min_x, play_max_x):
		for y in range(play_min_y, play_max_y):
			tile_map.set_cell(0, Vector2i(x,y), source_id, water_atlas)
			
			var noise_val : float = noise.get_noise_2d(x,y)
			
			if noise_val >= 0.0 and noise_val <= grassThreshold:
				tile_map.set_cell(1, Vector2i(x,y), source_id, sand_atlas)
			elif noise_val > grassThreshold:
				tile_map.set_cell(1, Vector2i(x,y), source_id, grass_atlas)
			else:
				tile_map.erase_cell(1, Vector2i(x,y))
	pass


func _configure_camera():
	if not camera:
		return
	var tile_size = tile_map.tile_set.tile_size
	var view_size = Vector2(visible_tiles.x * tile_size.x, visible_tiles.y * tile_size.y)
	var half_view = view_size / 2.0
	camera.position = Vector2.ZERO
	camera.limit_left = -half_view.x
	camera.limit_right = half_view.x
	camera.limit_top = -half_view.y
	camera.limit_bottom = half_view.y
	camera.zoom = Vector2.ONE
	camera.make_current()
