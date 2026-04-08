extends Node2D

var tracks = [
	preload("res://assets/music/Before Concession.mp3"),
	preload("res://assets/music/Unholy Invocation.mp3")
]

func _ready():
	$AudioStreamPlayer.stream = tracks.pick_random()
	$AudioStreamPlayer.play()
