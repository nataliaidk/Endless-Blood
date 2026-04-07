extends Node2D

@export var enemy_scene: PackedScene
@export var rat_scene: PackedScene
@export_range(0.0, 1.0, 0.01) var rat_spawn_chance := 0.55

func _on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	if not enemy_scene and not rat_scene:
		return

	var player_level := 0
	if player.has_method("get_level"):
		player_level = player.get_level()

	var spawn_scene: PackedScene = enemy_scene
	if player_level >= 2 and rat_scene != null and randf() <= rat_spawn_chance:
		spawn_scene = rat_scene

	if spawn_scene == null:
		return

	var enemy = spawn_scene.instantiate()
	enemy.add_to_group("enemies")
	
	var spawn_radius = 800.0
	var random_angle = randf() * PI * 2
	var spawn_offset = Vector2(cos(random_angle), sin(random_angle)) * spawn_radius
	
	enemy.global_position = player.global_position + spawn_offset
	add_child(enemy)
