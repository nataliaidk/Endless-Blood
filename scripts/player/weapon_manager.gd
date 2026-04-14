class_name WeaponManager
extends Node

const MAX_WEAPONS = 4
var active_weapons: Array[BaseWeapon] = []
var weapon_damage_bonus: int = 0
var weapon_range_bonus: float = 0.0

@onready var player: Node2D = get_parent()

func add_weapon(weapon_data: WeaponData) -> bool:
	if active_weapons.size() >= MAX_WEAPONS:
		return false

	for w in active_weapons:
		if w.data == weapon_data:
			_upgrade_weapon(w)
			return true

	var weapon_node = weapon_data.weapon_scene.instantiate() as BaseWeapon
	add_child(weapon_node)
	weapon_node.setup(weapon_data, player)
	_apply_bonuses_to_weapon(weapon_node)
	active_weapons.append(weapon_node)
	return true

func set_weapon_bonuses(damage_bonus: int, range_bonus: float) -> void:
	weapon_damage_bonus = max(0, damage_bonus)
	weapon_range_bonus = max(0.0, range_bonus)
	for w in active_weapons:
		_apply_bonuses_to_weapon(w)

func disable_all() -> void:
	for w in active_weapons:
		w.timer.stop()

func _upgrade_weapon(weapon: BaseWeapon) -> void:
	pass

func _apply_bonuses_to_weapon(weapon: BaseWeapon) -> void:
	if weapon != null and weapon.has_method("set_upgrade_bonuses"):
		weapon.set_upgrade_bonuses(weapon_damage_bonus, weapon_range_bonus)
