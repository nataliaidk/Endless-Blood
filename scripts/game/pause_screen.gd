extends CanvasLayer

var hover_sound := preload("res://assets/sounds/button hover.mp3")

@onready var audio = $AudioStreamPlayerButton
@onready var resume_button = $VBoxContainer/ResumeButton
@onready var quit_button = $VBoxContainer/QuitButton

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	resume_button.mouse_entered.connect(_on_hover)
	quit_button.mouse_entered.connect(_on_hover)
	resume_button.focus_entered.connect(_on_hover)
	quit_button.focus_entered.connect(_on_hover)
	resume_button.focus_neighbor_bottom = quit_button.get_path()
	quit_button.focus_neighbor_top = resume_button.get_path()
	resume_button.grab_focus()

func _on_hover():
	audio.stream = hover_sound
	audio.play()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	queue_free()
	get_tree().change_scene_to_file("res://scenes/game/main_menu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_resume_pressed()

func _on_resume_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().paused = false
	queue_free()
