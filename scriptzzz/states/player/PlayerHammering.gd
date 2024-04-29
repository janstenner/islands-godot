extends State
class_name PlayerHammering

@onready var animation_player = $"../../AnimationPlayer"


func Enter():
	# TODO add AudioManager to Player
	# AudioManager.play_sound(AudioManager.PLAYER_ATTACK_SWING, 0.3, 1)
	
	animation_player.play("hammer_animation")
	await animation_player.animation_finished
	state_transition.emit(self, "PlayerIdle")
