extends Node
class_name State

# from https://www.youtube.com/watch?v=i0Y6anqiJ-g

signal state_transition

func Enter():
	pass
	
func Exit():
	pass
	
func Update(_delta:float):
	pass


func request_state_transition(new_state_name : String):
	state_transition.emit(self, new_state_name)
