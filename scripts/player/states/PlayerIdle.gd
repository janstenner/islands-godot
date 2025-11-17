extends State
class_name PlayerIdle

@export var animator : AnimationPlayer

func Enter():
	pass
	
func Update(_delta : float):
	#if(Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown").normalized()):
		#state_transition.emit(self, "Moving")
		
	if Input.is_action_just_pressed("Jump"):
		request_state_transition("PlayerJumping")
	elif Input.is_action_pressed("Hammer"):
		request_state_transition("PlayerHammering")

func Exit():
	pass
