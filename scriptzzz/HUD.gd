extends CanvasLayer

@onready var pause_button = $PauseButton
@onready var resume_button = $PauseLayer/PauseMenu/ResumeButton
@onready var pause_layer = $PauseLayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pause_button.pressed.connect(self.pause)
	resume_button.pressed.connect(self.resume)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func pause():
	get_tree().paused = true
	pause_layer.show()
	
	
func resume():
	pause_layer.hide()
	get_tree().paused = false
