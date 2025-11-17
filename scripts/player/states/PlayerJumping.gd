extends State
class_name PlayerJumping

@onready var player : Player = $"../.."


func Enter():
	if player:
		player.start_jump()


func Update(delta : float):
	if not player:
		return
	if not player.update_jump(delta):
		state_transition.emit(self, "PlayerIdle")


func Exit():
	if player:
		player.finish_jump()
