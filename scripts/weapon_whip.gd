class_name WeaponWhip
extends BaseWeapon

@export var slash_scene: PackedScene

func _do_attack() -> void:
	#var enemies = get_enemies_sorted_by_distance()
	#if enemies.is_empty():
		#return
	#var target = enemies[0]
	#var dir = player.global_position.direction_to(target.global_position)
	#var angle = dir.angle()
	#_play_attack_animation(dir)
	#var slash = slash_scene.instantiate()
	#slash.damage = data.damage
	#slash.global_position = player.global_position + dir * 30.0
	#slash.rotation = angle
	#get_tree().current_scene.add_child(slash)
	
	var dir = player.facing_direction
	var angle = dir.angle()
	_play_attack_animation(dir)
	var slash = slash_scene.instantiate()
	slash.damage = data.damage
	slash.global_position = player.global_position + dir * 30.0
	slash.rotation = angle
	get_tree().current_scene.add_child(slash)

func _play_attack_animation(dir: Vector2) -> void:
	var sprite = player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return
	sprite.flip_h = dir.x < 0
	# sprite.play("attack_sword")
