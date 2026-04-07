extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")
@onready var health_bar: TextureProgressBar = $TextureProgressBar

var player_in_range: Node2D = null
var speed := 75
var max_health := 100
var health := max_health
var knockback := 1
var damage := 25
var is_dead := false
@export var blood_exp_reward := 1

@export var blood_color := Color(0.73, 0.05, 0.08, 0.9)
@export var blood_lifetime := 0.5

func _ready():
	health_bar.value = health
	health_bar.max_value = max_health

func _physics_process(_delta):
	if is_dead or player == null:
		return
		
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()
	update_animation(direction)

func update_animation(direction: Vector2):
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			sprite.play("walk_right")
		else:
			sprite.play("walk_left")
	else:
		if direction.y > 0:
			sprite.play("walk_down")
		else:
			sprite.play("walk_up")

func take_damage(attack: Attack):
	if is_dead:
		return
	health -= attack.damage
	health_bar.value = health
	_spawn_blood_splash(blood_lifetime * 0.7, 18.0)
	if health <= 0:
		die()

func die():
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
	_spawn_blood_splash(blood_lifetime * 1.3, 42.0)
	sprite.play("die")
	await sprite.animation_finished
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.is_in_group("player"):
		player_in_range = body
		attack()
		$DamageTimer.start()

func _on_hitbox_body_exited(body: Node2D):
	if body == player_in_range:
		player_in_range = null
		$DamageTimer.stop()

func _on_damage_timer_timeout():
	if player_in_range and not is_dead:
		attack()

func attack():
	if player_in_range == null or not is_instance_valid(player_in_range):
		return
	var attack = Attack.new()
	attack.damage = damage
	attack.knockback = knockback
	attack.position = global_position
	player_in_range.take_damage(attack)

func _spawn_blood_splash(lifetime: float, velocity_min: float) -> void:
	var blood := CPUParticles2D.new()
	blood.amount = 26
	blood.one_shot = true
	blood.emitting = false
	blood.lifetime = max(0.05, lifetime)
	blood.spread = 50.0
	blood.initial_velocity_min = velocity_min
	blood.initial_velocity_max = velocity_min + 45.0
	blood.gravity = Vector2(0, 80)
	blood.angular_velocity_min = -220.0
	blood.angular_velocity_max = 220.0
	blood.scale_amount_min = 1.0
	blood.scale_amount_max = 2.2
	blood.color = blood_color
	blood.local_coords = false
	blood.z_index = 20
	blood.global_position = global_position
	get_parent().add_child(blood)
	blood.emitting = true

	var cleanup_timer := get_tree().create_timer(blood.lifetime + 0.4)
	await cleanup_timer.timeout
	if is_instance_valid(blood):
		blood.queue_free()
