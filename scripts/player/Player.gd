extends Node2D
class_name Player

signal landed(position : Vector2)

@export var SPEED : float = 30.0
@export var jumping_power : float = 3.0
@export var jump_gravity : float = -9.8
@export var land_collision_mask : int = 1
@export var boundary_collision_mask : int = 2
const MAX_JUMP_HEIGHT : float = 1.0
const MIN_BONUS_JUMPING_POWER : float = 0.0
const MAX_BONUS_JUMPING_POWER : float = 4.0
const BONUS_CHARGE_RATE : float = 1.0
const BONUS_DECAY_RATE : float = 1.8
const SHIP_FLICKER_FREQ : float = 8.0
const CROSSHAIR_SCALE_FREQ : float = 5.0
var jump_velocity : float = 0.0
var jump_height : float = 0.0
var pending_jump : bool = false
var is_jumping : bool = false
var jump_time : float = 0.0
var crosshair_time : float = 0.0
var crosshair_frame_counter : int = 0
var bonus_jumping_power : float = 0.0
var is_hammering : bool = false

@export_node_path("TileMap") var tile_map_path : NodePath
@export_node_path("CanvasLayer") var hud_path : NodePath = NodePath("/root/Hud")

@onready var body : RigidBody2D = $PlayerBody
@onready var sprite : Sprite2D = $PlayerBody/PlayerSprite
@onready var collision_shape : CollisionShape2D = $PlayerBody/CollisionShape2D
@onready var jump_collision_shape : CollisionShape2D = $PlayerBody/JumpCollisionShape2D
@onready var ground_shadow : Node2D = $GroundShadow
@onready var crosshair : Sprite2D = $GroundShadow/Crosshair
@onready var drop_shadow_sprite : Sprite2D = $GroundShadow/DropShadowSprite
@onready var tile_map : TileMap = _resolve_tile_map()
@onready var hud : CanvasLayer = _resolve_hud()

var sprite_base_position : Vector2 = Vector2.ZERO
var sprite_base_scale : Vector2 = Vector2.ONE
var collision_base_position : Vector2 = Vector2.ZERO
var collision_base_scale : Vector2 = Vector2.ONE
var sprite_base_modulate : Color = Color(1, 1, 1, 1)
var crosshair_base_modulate : Color = Color(1, 1, 1, 1)
var default_collision_mask : int = 0
var rng := RandomNumberGenerator.new()

func _ready():
	if body:
		body.top_level = true
		body.global_position = global_position
		var layer_bits = land_collision_mask | boundary_collision_mask
		if layer_bits != 0:
			body.collision_layer = layer_bits
		default_collision_mask = land_collision_mask
		if default_collision_mask == 0:
			default_collision_mask = body.collision_mask
		body.collision_mask = default_collision_mask
	if ground_shadow:
		ground_shadow.global_position = global_position
	if sprite:
		sprite_base_position = sprite.position
		sprite_base_scale = sprite.scale
		sprite_base_modulate = sprite.modulate
	if collision_shape:
		collision_base_position = collision_shape.position
		collision_base_scale = collision_shape.scale
	if crosshair:
		crosshair.visible = false
		crosshair_base_modulate = crosshair.modulate
	if jump_collision_shape:
		jump_collision_shape.disabled = true
	rng.randomize()
	bonus_jumping_power = MIN_BONUS_JUMPING_POWER
	_sync_root_to_body()

func _physics_process(delta):
	if not body:
		return
	var directionx = Input.get_axis("ui_left", "ui_right")
	var directiony = Input.get_axis("ui_up", "ui_down")
	
	var xy : Vector2 = Vector2.ZERO
	
	if directionx:
		xy.x = directionx * SPEED
		
	if directiony:
		xy.y = directiony * SPEED

	if xy != Vector2.ZERO:
		body.apply_central_impulse(xy)
	if is_jumping:
		jump_time += delta
		crosshair_time += delta
	_update_bonus_power(delta)
	_sync_root_to_body()


func queue_jump():
	pending_jump = true


func consume_jump_request() -> bool:
	if pending_jump:
		pending_jump = false
		return true
	return false


func start_jump():
	if is_jumping:
		return
	is_jumping = true
	jump_velocity = jumping_power + bonus_jumping_power
	jump_height = 0.0
	jump_time = 0.0
	crosshair_time = 0.0
	crosshair_frame_counter = 0
	if collision_shape:
		collision_shape.disabled = true
	if jump_collision_shape:
		jump_collision_shape.disabled = false
	if body:
		if boundary_collision_mask > 0:
			body.collision_mask = boundary_collision_mask
		else:
			body.collision_mask = default_collision_mask
	_apply_jump_visuals()


func update_jump(delta : float) -> bool:
	if not is_jumping:
		return false
	jump_velocity += jump_gravity * delta
	jump_height += jump_velocity * delta * 0.5
	jump_height = clamp(jump_height, 0.0, MAX_JUMP_HEIGHT)
	if jump_height <= 0.0:
		finish_jump()
		return false
	_apply_jump_visuals()
	return true


func finish_jump():
	var was_jumping = is_jumping
	is_jumping = false
	jump_velocity = 0.0
	jump_height = 0.0
	if collision_shape:
		collision_shape.disabled = false
	if jump_collision_shape:
		jump_collision_shape.disabled = true
	if body:
		body.collision_mask = default_collision_mask
	_reset_jump_visuals()
	if was_jumping:
		emit_signal("landed", get_body_position())


func is_jump_active() -> bool:
	return is_jumping


func _apply_jump_visuals():
	var clamped_height = clamp(jump_height, 0.0, MAX_JUMP_HEIGHT)
	var scale_factor = 1.0 + clamped_height * 1.3
	if sprite:
		sprite.scale = sprite_base_scale * scale_factor
		var base_opacity = lerp(1.0, 0.5, clamped_height / MAX_JUMP_HEIGHT)
		var flicker = 0.85 + 0.15 * sin(jump_time * SHIP_FLICKER_FREQ * TAU)
		var opacity = clamp(base_opacity * flicker, 0.3, 1.0)
		var color = sprite_base_modulate
		color.a = opacity
		sprite.modulate = color
	if collision_shape:
		collision_shape.scale = collision_base_scale * scale_factor
	var offset_factor = jump_height * 50.0
	var offset = Vector2(-offset_factor, -offset_factor)
	if body:
		offset = offset.rotated(-body.rotation)
	if sprite:
		sprite.position = sprite_base_position + offset
	if collision_shape:
		collision_shape.position = collision_base_position + offset
	_update_ground_shadow(clamped_height)


func _reset_jump_visuals():
	if sprite:
		sprite.scale = sprite_base_scale
		sprite.position = sprite_base_position
		sprite.modulate = sprite_base_modulate
	if collision_shape:
		collision_shape.scale = collision_base_scale
		collision_shape.position = collision_base_position
	_update_ground_shadow(0.0)


func _sync_root_to_body():
	if not body:
		return
	global_position = body.global_position
	global_rotation = 0.0
	if ground_shadow:
		ground_shadow.global_position = body.global_position
	_update_ground_shadow(jump_height)


func get_body_position() -> Vector2:
	if body:
		return body.global_position
	return global_position


func get_tile_map() -> TileMap:
	return tile_map


func get_hud() -> CanvasLayer:
	return hud


func set_hammering_state(active : bool):
	is_hammering = active


func _update_bonus_power(delta : float):
	if is_hammering:
		bonus_jumping_power = clamp(bonus_jumping_power + BONUS_CHARGE_RATE * delta, MIN_BONUS_JUMPING_POWER, MAX_BONUS_JUMPING_POWER)
	else:
		bonus_jumping_power = clamp(bonus_jumping_power - BONUS_DECAY_RATE * delta, MIN_BONUS_JUMPING_POWER, MAX_BONUS_JUMPING_POWER)
	if hud:
		hud.update_bonus_charge(bonus_jumping_power, MIN_BONUS_JUMPING_POWER, MAX_BONUS_JUMPING_POWER)


func _update_ground_shadow(clamped_height : float):
	if not ground_shadow:
		return
	ground_shadow.global_position = body.global_position
	if drop_shadow_sprite:
		drop_shadow_sprite.visible = is_jumping
		if is_jumping:
			drop_shadow_sprite.rotation = body.rotation
			var shadow_scale = max(0.1, 1.0 - (clamped_height * 0.8))
			drop_shadow_sprite.scale = Vector2.ONE * shadow_scale
		else:
			drop_shadow_sprite.rotation = 0.0
			drop_shadow_sprite.scale = Vector2.ONE
	if crosshair:
		var on_land = false
		if tile_map:
			var cell = tile_map.local_to_map(tile_map.to_local(body.global_position))
			on_land = tile_map.get_cell_source_id(1, cell) != -1
		crosshair.visible = is_jumping and on_land
		if crosshair.visible:
			var scale_bonus = 2.0 + 0.5 * sin(crosshair_time * CROSSHAIR_SCALE_FREQ * TAU)
			crosshair.scale = Vector2.ONE * scale_bonus
			var flicker = 0.8 + 0.4 * sin(crosshair_time * (CROSSHAIR_SCALE_FREQ * 0.7) * TAU)
			var color = crosshair_base_modulate
			color.a = clamp(flicker, 0.2, 1.0)
			crosshair.modulate = color
			crosshair_frame_counter += 1
			if crosshair_frame_counter >= 4:
				crosshair_frame_counter = 0
				rng.randomize()
				crosshair.rotation = rng.randf_range(-PI, PI)
		else:
			crosshair.scale = Vector2.ONE
			crosshair.modulate = crosshair_base_modulate
			crosshair.rotation = 0.0
			crosshair_frame_counter = 0


func _resolve_tile_map() -> TileMap:
	var node = _resolve_node(tile_map_path)
	if node and node is TileMap:
		return node
	if get_parent():
		var parent_tile_map = get_parent().get_node_or_null("TileMap")
		if parent_tile_map and parent_tile_map is TileMap:
			return parent_tile_map
	return null


func _resolve_hud() -> CanvasLayer:
	var node = _resolve_node(hud_path)
	if node and node is CanvasLayer:
		return node
	return get_tree().root.get_node_or_null("/root/Hud") as CanvasLayer


func _resolve_node(path : NodePath) -> Node:
	if path.is_empty():
		return null
	return get_node_or_null(path)
