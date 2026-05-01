extends Control

var hover_sound := preload("res://assets/sounds/button hover.mp3")

@onready var audio = $AudioStreamPlayerButton
@onready var start_button = $VBoxContainer/Start
@onready var exit_button = $VBoxContainer/Exit

func _ready():
	start_button.mouse_entered.connect(_on_hover)
	exit_button.mouse_entered.connect(_on_hover)
	start_button.focus_entered.connect(_on_hover)
	exit_button.focus_entered.connect(_on_hover)
	start_button.focus_neighbor_bottom = exit_button.get_path()
	exit_button.focus_neighbor_top = start_button.get_path()
	start_button.grab_focus()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_hover():
	audio.stream = hover_sound
	audio.play()
