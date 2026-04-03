extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")
@onready var health_bar: TextureProgressBar = $TextureProgressBar

var player_in_range: Node2D = null
var speed := 75
var max_health := 100
var health := max_health
var damage := 25
var knockback := 5
var is_dead := false

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
	if health <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	sprite.play("die")
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
	var attack = Attack.new()
	attack.damage = damage
	attack.knockback = knockback
	attack.position = global_position
	player_in_range.take_damage(attack)
