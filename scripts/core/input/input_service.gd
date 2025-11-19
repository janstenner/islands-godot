extends Node

func get_movement_input() -> Vector2:
	var horizontal = Input.get_axis("ui_left", "ui_right")
	var vertical = Input.get_axis("ui_up", "ui_down")
	return Vector2(horizontal, vertical)


func is_jump_pressed() -> bool:
	return Input.is_action_pressed("Jump")


func is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("Jump")


func is_hammer_pressed() -> bool:
	return Input.is_action_pressed("Hammer")


func is_hammer_just_pressed() -> bool:
	return Input.is_action_just_pressed("Hammer")


func is_reset_just_pressed() -> bool:
	return Input.is_action_just_pressed("Reset")
