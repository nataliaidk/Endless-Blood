class_name WeaponWhip
extends BaseWeapon

@export var slash_scene: PackedScene

var _damage_bonus: int = 0
var _range_bonus: float = 0.0

func set_upgrade_bonuses(damage_bonus: int, range_bonus: float) -> void:
	_damage_bonus = max(0, damage_bonus)
	_range_bonus = max(0.0, range_bonus)

func _do_attack() -> void:
	var dir = player.facing_direction_x
	var angle = 0
	if dir < 0:
		angle = PI
	var slash = slash_scene.instantiate()
	slash.damage = data.damage + _damage_bonus
	var reach := 30.0 + _range_bonus
	slash.global_position = player.global_position + Vector2(dir, 0) * reach
	slash.scale = Vector2.ONE * (1.0 + _range_bonus / 140.0)
	slash.rotation = angle
	get_tree().current_scene.add_child(slash)
