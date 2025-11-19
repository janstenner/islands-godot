extends CanvasLayer

@onready var pause_button = $PauseButton
@onready var resume_button = $PauseLayer/PauseMenu/MenuContainer/ResumeButton
@onready var restart_button = $PauseLayer/PauseMenu/MenuContainer/RestartButton
@onready var main_menu_button = $PauseLayer/PauseMenu/MenuContainer/MainMenuButton
@onready var pause_layer = $PauseLayer
@onready var timer_label = $TimerLabel
@onready var game_over_label = $PauseLayer/PauseMenu/MenuContainer/GameOverLabel
@onready var hearts_container = $HeartsContainer
@onready var bonus_bar = $BonusBar
var heart_sprites : Array = []

var elapsed_time : float = 0.0
var timer_running : bool = false
var is_game_over : bool = false
var current_level_path : String = ""

const DEFAULT_LEVEL_PATH : String = "res://scenes/levels/survival/survival_world.tscn"
const MAIN_MENU_SCENE : String = "res://scenes/menus/main_menu.tscn"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_button.pressed.connect(pause)
	resume_button.pressed.connect(resume)
	restart_button.pressed.connect(restart_game)
	main_menu_button.pressed.connect(return_to_main_menu)
	_reset_overlay()
	set_process_unhandled_input(true)
	heart_sprites = hearts_container.get_children()
	reset_hearts()
	update_bonus_charge(0.0, 0.0, 1.0)
	hide_hud()


func _process(delta):
	if not visible:
		return
	if timer_running and not get_tree().paused:
		elapsed_time += delta
		_update_timer_label()
	if InputService.is_reset_just_pressed():
		restart_game()
	elif is_game_over and InputService.is_hammer_just_pressed():
		restart_game()


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
	reset_hearts()
	update_bonus_charge(0.0, 0.0, 1.0)
	_update_timer_label()


func stop_timer():
	timer_running = false


func show_game_over(time_text : String):
	is_game_over = true
	timer_running = false
	game_over_label.text = "Time survived: %s" % time_text
	game_over_label.show()
	resume_button.hide()
	restart_button.show()
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
	restart_button.hide()
	game_over_label.hide()
	get_tree().paused = false
	reset_hearts()
	update_bonus_charge(0.0, 0.0, 1.0)


func restart_game():
	get_tree().paused = false
	timer_running = false
	is_game_over = false
	var level_path = current_level_path
	if level_path.is_empty():
		level_path = DEFAULT_LEVEL_PATH
	get_tree().change_scene_to_file(level_path)


func return_to_main_menu():
	get_tree().paused = false
	timer_running = false
	is_game_over = false
	hide_hud()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _unhandled_input(_event):
	pass


func reset_hearts():
	if heart_sprites.is_empty():
		return
	set_remaining_hearts(heart_sprites.size())


func set_remaining_hearts(amount : int):
	if heart_sprites.is_empty():
		return
	for i in range(heart_sprites.size()):
		var sprite = heart_sprites[i]
		if i < amount:
			sprite.modulate = Color(1, 1, 1, 1)
		else:
			sprite.modulate = Color(0, 0, 0, 0.7)


func update_bonus_charge(current_value : float, min_value : float, max_value : float):
	if max_value <= min_value:
		bonus_bar.visible = false
		return
	var ratio = clamp((current_value - min_value) / (max_value - min_value), 0.0, 1.0)
	bonus_bar.value = ratio
	bonus_bar.visible = ratio > 0.0


func set_current_level_path(path : String):
	current_level_path = path


func show_hud():
	visible = true


func hide_hud():
	visible = false
	pause_layer.hide()
	timer_running = false
	is_game_over = false
	get_tree().paused = false
