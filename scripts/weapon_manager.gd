class_name WeaponManager
extends Node

const MAX_WEAPONS = 4
var active_weapons: Array[BaseWeapon] = []

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
	active_weapons.append(weapon_node)
	return true

func _upgrade_weapon(weapon: BaseWeapon) -> void:
	pass
