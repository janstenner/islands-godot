extends RigidBody2D


var SPEED = 40

#test
func _physics_process(delta):

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var directionx = Input.get_axis("ui_left", "ui_right")
	var directiony = Input.get_axis("ui_up", "ui_down")
	
	var xy : Vector2 = Vector2(0, 0)
	
	#print(position.x, position.y)
	
	if directionx:
		xy.x = directionx * SPEED
		
	if directiony:
		xy.y = directiony * SPEED

	apply_central_impulse(xy)
