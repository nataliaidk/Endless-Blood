extends Node

signal level_up_ready(choices: Array[Dictionary])
signal upgrade_applied(upgrade: Dictionary)

const WEAPON_UPGRADE_POOL := [
	{"id": "hunter_axe",    "name": "Hunter Axe",     "damage_bonus": 30, "range_bonus": 10.0, "icon_cell": Vector2i(0, 0)},
	{"id": "saw_cleaver",   "name": "Saw Cleaver",     "damage_bonus": 28, "range_bonus": 16.0, "icon_cell": Vector2i(1, 0)},
	{"id": "kirkhammer",    "name": "Kirkhammer",      "damage_bonus": 40, "range_bonus":  6.0, "icon_cell": Vector2i(2, 0)},
	{"id": "threaded_cane", "name": "Threaded Cane",   "damage_bonus": 20, "range_bonus": 26.0, "icon_cell": Vector2i(3, 0)},
	{"id": "ludwig_blade",  "name": "Ludwig's Blade",  "damage_bonus": 35, "range_bonus": 14.0, "icon_cell": Vector2i(0, 1)},
	{"id": "beast_claw",    "name": "Beast Claw",      "damage_bonus": 27, "range_bonus": 20.0, "icon_cell": Vector2i(1, 1)},
]

@export var heal_percent_on_kill := 0.07
@export var axe_damage := 55
@export var axe_range := 200.0
@export var axe_arc_degrees := 100.0
@export var axe_cooldown := 0.55
@export var axe_attack_lock_time := 0.12

var blood_exp := 0
var player_level := 0
var unlocked_upgrade_ids: Array[String] = []

var _pending_requirement := 0
var _in_progress := false

@onready var player = get_parent()

func _ready():
	player.exp_gained.connect(_on_exp_gained)

func _on_exp_gained(amount: int):
	blood_exp += amount
	_heal_on_kill()
	_try_trigger_level_up()

func _try_trigger_level_up():
	if _in_progress or player.is_dead:
		return
	var requirement := _required_blood(player_level + 1)
	if blood_exp >= requirement:
		_pending_requirement = requirement
		_in_progress = true
		level_up_ready.emit(_roll_choices())

func on_upgrade_chosen(choice_index: int, choices: Array[Dictionary]):
	if choice_index < 0 or choice_index >= choices.size():
		return
	var chosen := choices[choice_index]
	_apply_upgrade(chosen)
	blood_exp = max(0, blood_exp - _pending_requirement)
	player_level += 1
	_pending_requirement = 0
	_in_progress = false
	_try_trigger_level_up()

func _apply_upgrade(upgrade: Dictionary):
	axe_damage += int(upgrade.get("damage_bonus", 0))
	axe_range  += float(upgrade.get("range_bonus", 0.0))
	var id := str(upgrade.get("id", ""))
	if not unlocked_upgrade_ids.has(id):
		unlocked_upgrade_ids.append(id)
	upgrade_applied.emit(upgrade)

func _roll_choices() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for u in WEAPON_UPGRADE_POOL:
		if not unlocked_upgrade_ids.has(str(u["id"])):
			available.append(u)
	var source := available if available.size() >= 3 else WEAPON_UPGRADE_POOL.duplicate(true)
	source.shuffle()
	var result: Array[Dictionary] = []
	result.assign(source.slice(0, 3))
	return result

func _required_blood(target_level: int) -> int:
	return max(1, target_level * 2 - 1)

func _heal_on_kill():
	if player.health <= 0:
		return
	var amount := int(max(1.0, round(player.max_health * heal_percent_on_kill)))
	player.heal(amount)
	
