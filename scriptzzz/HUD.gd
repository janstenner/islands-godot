extends CanvasLayer

@onready var pause_button = $PauseButton
@onready var resume_button = $PauseLayer/PauseMenu/MenuContainer/ResumeButton
@onready var pause_layer = $PauseLayer
@onready var timer_label = $TimerLabel
@onready var game_over_label = $PauseLayer/PauseMenu/MenuContainer/GameOverLabel

var elapsed_time : float = 0.0
var timer_running : bool = false
var is_game_over : bool = false

func _ready():
	pause_button.pressed.connect(pause)
	resume_button.pressed.connect(resume)
	_reset_overlay()


func _process(delta):
	if timer_running and not get_tree().paused:
		elapsed_time += delta
		_update_timer_label()


func pause():
	if is_game_over:
		return
	get_tree().paused = true
	pause_layer.show()
	game_over_label.hide()
	resume_button.show()
	
func resume():
	if is_game_over:
		return
	pause_layer.hide()
	get_tree().paused = false


func start_timer():
	elapsed_time = 0.0
	timer_running = true
	is_game_over = false
	_reset_overlay()
	_update_timer_label()


func stop_timer():
	timer_running = false


func show_game_over(time_text : String):
	is_game_over = true
	timer_running = false
	game_over_label.text = "Time survived: %s" % time_text
	game_over_label.show()
	resume_button.hide()
	pause_layer.show()
	pause_button.disabled = true
	get_tree().paused = true


func get_formatted_time() -> String:
	return _format_time(elapsed_time)


func _update_timer_label():
	timer_label.text = _format_time(elapsed_time)


func _format_time(total_seconds : float) -> String:
	var minutes = int(total_seconds) / 60
	var seconds = int(total_seconds) % 60
	var milliseconds = int(fmod(total_seconds, 1.0) * 1000.0)
	return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]


func _reset_overlay():
	pause_button.disabled = false
	pause_layer.hide()
	resume_button.show()
	game_over_label.hide()
	get_tree().paused = false
