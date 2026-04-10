class_name WeaponWhip
extends BaseWeapon

@export var slash_scene: PackedScene

func _do_attack() -> void:
	var dir = player.facing_direction_x
	var angle = 0
	if dir < 0:
		angle = PI
	var slash = slash_scene.instantiate()
	slash.damage = data.damage
	slash.global_position = player.global_position + Vector2(dir, 0) * 30.0
	slash.rotation = angle
	get_tree().current_scene.add_child(slash)
