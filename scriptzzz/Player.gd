extends RigidBody2D
class_name Player

@export var SPEED : float = 30.0
@export var jumping_power : float = 4.0
@export var jump_gravity : float = -9.8

var jump_velocity : float = 0.0
var jump_height : float = 0.0
var pending_jump : bool = false
var is_jumping : bool = false

@onready var sprite : Sprite2D = $PlayerSprite
@onready var collision_shape : CollisionShape2D = $CollisionShape2D
@onready var crosshair : Sprite2D = $Crosshair

var sprite_base_position : Vector2 = Vector2.ZERO
var sprite_base_scale : Vector2 = Vector2.ONE
var collision_base_position : Vector2 = Vector2.ZERO
var collision_base_scale : Vector2 = Vector2.ONE

func _ready():
	sprite_base_position = sprite.position
	sprite_base_scale = sprite.scale
	collision_base_position = collision_shape.position
	collision_base_scale = collision_shape.scale
	if crosshair:
		crosshair.visible = false

func _physics_process(_delta):
	var directionx = Input.get_axis("ui_left", "ui_right")
	var directiony = Input.get_axis("ui_up", "ui_down")
	
	var xy : Vector2 = Vector2.ZERO
	
	if directionx:
		xy.x = directionx * SPEED
		
	if directiony:
		xy.y = directiony * SPEED

	apply_central_impulse(xy)


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
	collision_shape.disabled = true
	if crosshair:
		crosshair.visible = true
		crosshair.z_index = -1
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
	collision_shape.disabled = false
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
	var offset_factor = jump_height
	var offset = Vector2(-offset_factor, -offset_factor)
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
