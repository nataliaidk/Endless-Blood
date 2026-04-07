extends CharacterBody2D

const RAT_TEXTURES := [
	preload("res://assets/sprites/Rat-Blonde-Walk.png"),
	preload("res://assets/sprites/Rat-Cinnamon-Walk.png"),
	preload("res://assets/sprites/Rat-Chocolate-Walk.png"),
	preload("res://assets/sprites/Rat-DarkGrey-Walk.png"),
	preload("res://assets/sprites/Rat-LightGrey-Walk.png"),
	preload("res://assets/sprites/Rat-White-Walk.png")
]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")
@onready var health_bar: TextureProgressBar = $TextureProgressBar

var player_in_range: Node2D = null
var speed := 145.0
var max_health := 60
var health := max_health
var damage := 8
var knockback := 2
var is_dead := false
@export var blood_exp_reward := 1

@export var blood_color := Color(0.73, 0.05, 0.08, 0.85)
@export var blood_lifetime := 0.35

func _ready() -> void:
	_randomize_visual()
	health_bar.value = health
	health_bar.max_value = max_health

func _physics_process(_delta: float) -> void:
	if is_dead or player == null:
		return

	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()
	_update_animation(direction)

func _update_animation(direction: Vector2) -> void:
	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false

	if sprite.animation != &"walk":
		sprite.play("walk")

func take_damage(attack: Attack):
	if is_dead:
		return
	health -= attack.damage
	health_bar.value = health
	_spawn_blood_splash(blood_lifetime * 0.8, 16.0)
	if health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	if player != null and is_instance_valid(player) and player.has_method("gain_blood_exp"):
		player.gain_blood_exp(blood_exp_reward)
	velocity = Vector2.ZERO
	health_bar.hide()
	$Hitbox.monitoring = false
	$CollisionShape2D.set_deferred("disabled", true)
	$DamageTimer.stop()
	_spawn_blood_splash(blood_lifetime * 1.2, 30.0)
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.is_in_group("player"):
		player_in_range = body
		attack()
		$DamageTimer.start()

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		$DamageTimer.stop()

func _on_damage_timer_timeout() -> void:
	if player_in_range and not is_dead:
		attack()

func attack() -> void:
	if player_in_range == null or not is_instance_valid(player_in_range):
		return
	var attack_data := Attack.new()
	attack_data.damage = damage
	attack_data.knockback = knockback
	attack_data.position = global_position
	player_in_range.take_damage(attack_data)

func _spawn_blood_splash(lifetime: float, velocity_min: float) -> void:
	var blood := CPUParticles2D.new()
	blood.amount = 12
	blood.one_shot = true
	blood.emitting = false
	blood.lifetime = max(0.05, lifetime)
	blood.spread = 60.0
	blood.initial_velocity_min = velocity_min
	blood.initial_velocity_max = velocity_min + 28.0
	blood.gravity = Vector2(0, 70)
	blood.scale_amount_min = 0.8
	blood.scale_amount_max = 1.5
	blood.color = blood_color
	blood.local_coords = false
	blood.z_index = 20
	blood.global_position = global_position
	get_parent().add_child(blood)
	blood.emitting = true

	var cleanup_timer := get_tree().create_timer(blood.lifetime + 0.3)
	await cleanup_timer.timeout
	if is_instance_valid(blood):
		blood.queue_free()

func _randomize_visual() -> void:
	if RAT_TEXTURES.is_empty():
		return
	var chosen_texture: Texture2D = RAT_TEXTURES[randi() % RAT_TEXTURES.size()]
	var frames := SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 10.0)

	var frame_width := int(chosen_texture.get_width() / 4)
	var frame_height := chosen_texture.get_height()
	for i in range(4):
		var atlas := AtlasTexture.new()
		atlas.atlas = chosen_texture
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame("walk", atlas)

	sprite.sprite_frames = frames
	sprite.play("walk")
