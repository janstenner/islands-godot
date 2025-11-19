extends Control

const LEVELS = [
	{
		"name": "Endless Survival",
		"path": "res://scenes/levels/survival/survival_world.tscn"
	}
]

@onready var level_selector : OptionButton = $MarginContainer/MenuContainer/LevelSelector
@onready var start_button : Button = $MarginContainer/MenuContainer/StartButton
@onready var options_button : Button = $MarginContainer/MenuContainer/OptionsButton

func _ready():
	_hide_hud_layer()
	_populate_levels()
	level_selector.item_selected.connect(_on_level_selected)
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	_update_start_state()


func _populate_levels():
	level_selector.clear()
	for i in LEVELS.size():
		var entry = LEVELS[i]
		level_selector.add_item(entry["name"], i)
	if LEVELS.is_empty():
		level_selector.selected = -1
	else:
		level_selector.select(0)


func _on_level_selected(_index : int):
	_update_start_state()


func _on_start_pressed():
	var level_index = level_selector.get_selected_id()
	if level_index < 0 or level_index >= LEVELS.size():
		return
	var scene_path = LEVELS[level_index]["path"]
	if scene_path.is_empty():
		return
	get_tree().change_scene_to_file(scene_path)


func _on_options_pressed():
	# Placeholder for future submenu integration.
	print("Options menu not implemented yet.")


func _update_start_state():
	start_button.disabled = LEVELS.is_empty()


func _hide_hud_layer():
	var hud = get_tree().root.get_node_or_null("Hud")
	if hud and hud.has_method("hide_hud"):
		hud.hide_hud()
