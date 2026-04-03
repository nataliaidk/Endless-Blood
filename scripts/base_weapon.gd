class_name BaseWeapon
extends Node2D

var data: WeaponData
var player: Node2D
var enemies_group := "enemies"

@onready var timer: Timer = $Timer

func setup(weapon_data: WeaponData, player_node: Node2D) -> void:
	data = weapon_data
	player = player_node

func _ready() -> void:
	timer.wait_time = data.cooldown
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout() -> void:
	_do_attack()

func _do_attack() -> void:
	pass

func get_enemies_sorted_by_distance() -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	for e in get_tree().get_nodes_in_group(enemies_group):
		enemies.append(e as Node2D)
	enemies.sort_custom(func(a, b):
		return a.global_position.distance_to(player.global_position) \
			 < b.global_position.distance_to(player.global_position)
	)
	return enemies
