extends Control

var hover_sound := preload("res://assets/sounds/button hover.mp3")

@onready var audio = $AudioStreamPlayerButton
@onready var back_button = $VBoxContainer/Back
@onready var timer_label = $TimerLabel

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	timer_label.text = "Survived for %02d' %02ds" % [int(GameTimer.seconds()) / 60, int(GameTimer.seconds()) % 60]
	back_button.mouse_entered.connect(_on_hover)
	back_button.focus_entered.connect(_on_hover)
	back_button.grab_focus()

func _on_hover():
	audio.stream = hover_sound
	audio.play()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/main_menu.tscn")
