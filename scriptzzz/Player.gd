extends Node2D
class_name Player

@export var SPEED : float = 30.0
@export var jumping_power : float = 4.0
@export var jump_gravity : float = -9.8
@export var land_collision_mask : int = 1
@export var boundary_collision_mask : int = 2
var jump_velocity : float = 0.0
var jump_height : float = 0.0
var pending_jump : bool = false
var is_jumping : bool = false

@onready var body : RigidBody2D = $PlayerBody
@onready var sprite : Sprite2D = $PlayerBody/PlayerSprite
@onready var collision_shape : CollisionShape2D = $PlayerBody/CollisionShape2D
@onready var jump_collision_shape : CollisionShape2D = $PlayerBody/JumpCollisionShape2D
@onready var ground_shadow : Node2D = $GroundShadow
@onready var crosshair : Sprite2D = $GroundShadow/Crosshair

var sprite_base_position : Vector2 = Vector2.ZERO
var sprite_base_scale : Vector2 = Vector2.ONE
var collision_base_position : Vector2 = Vector2.ZERO
var collision_base_scale : Vector2 = Vector2.ONE
var default_collision_mask : int = 0

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
	if collision_shape:
		collision_base_position = collision_shape.position
		collision_base_scale = collision_shape.scale
	if crosshair:
		crosshair.visible = false
	if jump_collision_shape:
		jump_collision_shape.disabled = true
	_sync_root_to_body()

func _physics_process(_delta):
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
	jump_velocity = jumping_power
	jump_height = 0.0
	if collision_shape:
		collision_shape.disabled = true
	if jump_collision_shape:
		jump_collision_shape.disabled = false
	if body:
		if boundary_collision_mask > 0:
			body.collision_mask = boundary_collision_mask
		else:
			body.collision_mask = default_collision_mask
	if crosshair:
		crosshair.visible = true
		crosshair.position = Vector2.ZERO
	_apply_jump_visuals()


func update_jump(delta : float) -> bool:
	if not is_jumping:
		return false
	jump_velocity += jump_gravity * delta
	jump_height += jump_velocity * delta
	if jump_height <= 0.0:
		finish_jump()
		return false
	_apply_jump_visuals()
	return true


func finish_jump():
	is_jumping = false
	jump_velocity = 0.0
	jump_height = 0.0
	if collision_shape:
		collision_shape.disabled = false
	if jump_collision_shape:
		jump_collision_shape.disabled = true
	if body:
		body.collision_mask = default_collision_mask
	if crosshair:
		crosshair.visible = false
	_reset_jump_visuals()


func is_jump_active() -> bool:
	return is_jumping


func _apply_jump_visuals():
	var scale_factor = 1.0 + jump_height
	if sprite:
		sprite.scale = sprite_base_scale * scale_factor
	if collision_shape:
		collision_shape.scale = collision_base_scale * scale_factor
	var offset_factor = jump_height * 100.0
	var offset = Vector2(-offset_factor, -offset_factor)
	if body:
		offset = offset.rotated(-body.rotation)
	if sprite:
		sprite.position = sprite_base_position + offset
	if collision_shape:
		collision_shape.position = collision_base_position + offset


func _reset_jump_visuals():
	if sprite:
		sprite.scale = sprite_base_scale
		sprite.position = sprite_base_position
	if collision_shape:
		collision_shape.scale = collision_base_scale
		collision_shape.position = collision_base_position


func _sync_root_to_body():
	if not body:
		return
	global_position = body.global_position
	global_rotation = 0.0
	if ground_shadow:
		ground_shadow.global_position = body.global_position
		ground_shadow.global_rotation = 0.0


func get_body_position() -> Vector2:
	if body:
		return body.global_position
	return global_position
