extends State
class_name PlayerIdle

@export var animator : AnimationPlayer

func Enter():
	pass
	
func Update(_delta : float):
	#if(Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown").normalized()):
		#state_transition.emit(self, "Moving")
		
	if InputService.is_jump_just_pressed():
		request_state_transition("PlayerJumping")
	elif InputService.is_hammer_pressed():
		request_state_transition("PlayerHammering")

func Exit():
	pass
