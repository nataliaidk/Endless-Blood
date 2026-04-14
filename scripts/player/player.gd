extends CharacterBody2D

signal exp_gained(amount: int)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera := $Camera2D
@onready var health_bar: TextureProgressBar = $TextureProgressBar
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var leveling: Node = $PlayerLeveling
@onready var ui: Node = $PlayerUI
@onready var audio = $AudioStreamPlayer

@export var die_sound: AudioStream
@export var hurt_sounds: Array[AudioStream]

var speed := 200.0
var max_health := 100
var health := max_health
var is_dead := false
var facing_direction := Vector2.DOWN
var facing_direction_x := 1
var is_attacking := false

func _ready():
	camera.make_current()
	health_bar.value = health
	health_bar.max_value = max_health
	var whip_data = load("res://data/whip_data.tres")
	weapon_manager.add_weapon(whip_data)
	GameTimer.start()

func _physics_process(_delta):
	if is_dead:
		return
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		facing_direction = direction.normalized()
		calculate_facing_direction_x()
	velocity = Vector2.ZERO if is_attacking else direction * speed
	move_and_slide()
	update_animation(direction if not is_attacking else Vector2.ZERO)

func calculate_facing_direction_x():
	if facing_direction.x != 0:
		if facing_direction.x < 0:
			facing_direction_x = -1
		if facing_direction.x > 0:
			facing_direction_x = 1

func update_animation(direction: Vector2):
	if is_attacking or direction == Vector2.ZERO:
		sprite.play("idle")
		return
	if abs(direction.x) > abs(direction.y):
		sprite.play("walk_right" if direction.x > 0 else "walk_left")
	else:
		sprite.play("walk_down" if direction.y > 0 else "walk_up")

func take_damage(attack: Attack):
	if is_dead:
		return
	health -= attack.damage
	health_bar.value = health
	flash_red()
	if health <= 0:
		die()
	else:
		audio.stream = hurt_sounds.pick_random()
		audio.play()

func flash_red():
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1, 1, 1) 

func heal(amount: int):
	health = min(max_health, health + amount)
	health_bar.value = health

func die():
	GameTimer.stop()
	audio.stream = die_sound
	audio.play()
	is_dead = true
	is_attacking = false
	velocity = Vector2.ZERO
	weapon_manager.disable_all()
	sprite.play("die")
	await sprite.animation_finished
	get_tree().change_scene_to_file("res://scenes/game/death_screen.tscn")

func gain_blood_exp(amount: int):
	if is_dead or amount <= 0:
		return
	exp_gained.emit(amount)

func get_level() -> int:
	return leveling.player_level
	
