extends Node2D

@export var noise_height_texture : NoiseTexture2D
var noise : Noise

var width : int = 32
var height : int = 32

@onready var tile_map = $TileMap
@onready var player = $Player

var source_id = 2
var water_atlas = Vector2i(0,1)
var land_atlas = Vector2i(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	noise = noise_height_texture.noise
	generateWorld(0,0)
	pass 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	pass
	
	
func generateWorld(origin_x, origin_y):
	for x in range(origin_x - width/2, origin_x + width/2):
		for y in range(origin_y - height/2, origin_y + height/2):
			var noise_val : float = noise.get_noise_2d(x,y)
			if noise_val >= 0.3:
				tile_map.set_cell(0, Vector2i(x,y), source_id, land_atlas)
			else:
				tile_map.set_cell(0, Vector2i(x,y), source_id, water_atlas)

