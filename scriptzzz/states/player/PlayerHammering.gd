extends State
class_name PlayerHammering

@onready var animation_player = $"../../AnimationPlayer"
@onready var player : Player = $"../.."


func Enter():
	# TODO add AudioManager to Player
	# AudioManager.play_sound(AudioManager.PLAYER_ATTACK_SWING, 0.3, 1)
	
	animation_player.play("hammer_animation")
	await animation_player.animation_finished
	if player and player.consume_jump_request():
		state_transition.emit(self, "PlayerJumping")
	else:
		state_transition.emit(self, "PlayerIdle")
