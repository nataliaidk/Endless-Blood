extends Node2D

class SpawnEntry:
	var scene: PackedScene
	var weight: float
	var min_time: float
	var group_min: int
	var group_max: int
	func _init(s, w, mt, gmin, gmax):
		scene = s
		weight = w
		min_time = mt
		group_min = gmin
		group_max = gmax

@export var huntsman_scene: PackedScene
@export var rat_scene: PackedScene

@onready var timer: Timer = $Timer

var _table: Array[SpawnEntry] = []
var _spawn_radius := 900.0
var base_time := 5.0
var min_time := 0.3
var speed := 0.01

func _ready() -> void:
	_build_table()

func _build_table() -> void:
	_table.clear()
	if huntsman_scene:
		_table.append(SpawnEntry.new(huntsman_scene, 8.0, 0.0, 1, 1))
	if rat_scene:
		_table.append(SpawnEntry.new(rat_scene, 1.0, 15.0, 2, 5))

func _on_timer_timeout() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	var t : float = GameTimer.elapsed
	var entry := _pick_entry(t)
	if entry == null:
		return
	var count := randi_range(entry.group_min, entry.group_max)
	var base_pos := _get_spawn_position(player)
	for i in range(count):
		_spawn_one(entry.scene, base_pos, i, count)
	_update_spawn_rate(t)
		
func _pick_entry(elapsed: float) -> SpawnEntry:
	var pool := _table.filter(func(e): return e.min_time <= elapsed)
	if pool.is_empty():
		return null
	var total: float = pool.reduce(func(acc, e): return acc + e.weight, 0.0)
	var roll  := randf() * total
	for e in pool:
		roll -= e.weight
		if roll <= 0.0:
			return e
	return pool[-1]

func _get_spawn_position(player: Node2D) -> Vector2:
	var tries := 0
	while tries < 10:
		var angle  := randf() * TAU
		var offset := Vector2(cos(angle), sin(angle)) * _spawn_radius
		var pos := player.global_position + offset
		if pos.x >= -4700 and pos.x <= 4700 and pos.y >= -4700 and pos.y <= 4700:
			return pos
		tries += 1
	return Vector2.ZERO

func _spawn_one(scene: PackedScene, base_pos: Vector2, idx: int, total: int) -> void:
	var enemy := scene.instantiate()
	enemy.add_to_group("enemies")
	var offset := Vector2.ZERO
	if total == 1:
		offset = Vector2.ZERO
	else:
		var radius := 50.0
		var angle := (idx / float(total)) * TAU
		offset = Vector2(cos(angle), sin(angle)) * radius
		offset += Vector2(randf_range(-10, 10), randf_range(-10, 10))
	enemy.global_position = base_pos + offset
	add_child(enemy)
	
func _update_spawn_rate(t: float) -> void:
	timer.wait_time = max(min_time, base_time * exp(-speed * t))
	timer.start()
