class_name BaseEnemy
extends CharacterBody2D

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
@export var blood_exp_reward := 1
const DAMAGE_FONT: FontFile = preload("res://assets/fonts/Gothikka.ttf")

var speed := 100.0
var max_health := 100
var health := max_health
var damage := 10
var blood_lifetime := 0.4
var is_dead := false
var _player_in_range: Node2D = null

# ── lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	health = max_health
	_setup_visuals()

func _physics_process(_delta: float) -> void:
	if is_dead or player == null:
		return
	var dir := global_position.direction_to(player.global_position)
	velocity = dir * speed
	move_and_slide()
	_update_animation(dir)

# ── wirtualne metody  ───────────────────────────────────

## Ustaw sprite/animacje specyficzne dla danego wroga.
func _setup_visuals() -> void:
	pass

## Aktualizuj animację na podstawie kierunku ruchu.
func _update_animation(_dir: Vector2) -> void:
	pass

## Dodatkowe działania przy śmierci (np. animacja die).
func _on_death_effects() -> void:
	queue_free()
	
func flash_red():
	pass
	
# ── walka ─────────────────────────────────────────────────────────────────────

func take_damage(attack: Attack) -> void:
	if is_dead:
		return
	_show_damage_number(attack.damage)
	health -= attack.damage
	_spawn_blood(blood_lifetime * 0.8, 16.0)
	flash_red()
	if health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	if is_instance_valid(player) and player.has_method("gain_blood_exp"):
		player.gain_blood_exp(blood_exp_reward)
	velocity = Vector2.ZERO
	$HurtboxArea.monitoring = false
	$Collision.set_deferred("disabled", true)
	$DamageTimer.stop()
	_spawn_blood(blood_lifetime * 1.3, 35.0)
	_on_death_effects()

func attack() -> void:
	if _player_in_range == null or not is_instance_valid(_player_in_range):
		return
	var atk := Attack.new()
	atk.damage   = damage
	atk.position = global_position
	_player_in_range.get_parent().take_damage(atk)

# ── sygnały hitboxa / timera ─────────────────────────────────────────────────

func _on_hitbox_area_entered(area: Area2D) -> void:
	if is_dead or not area.is_in_group("player"):
		return
	_player_in_range = area
	attack()
	$DamageTimer.start()

func _on_hitbox_area_exited(area: Area2D) -> void:
	if area == _player_in_range:
		_player_in_range = null
		$DamageTimer.stop()

func _on_damage_timer_timeout() -> void:
	if _player_in_range and not is_dead:
		attack()

# ── krew ─────────────────────────────────────────────────────────────────────

func _spawn_blood(lifetime: float, vel_min: float) -> void:
	var p := CPUParticles2D.new()
	p.amount               = 18
	p.one_shot             = true
	p.lifetime             = max(0.05, lifetime)
	p.spread               = 55.0
	p.initial_velocity_min = vel_min
	p.initial_velocity_max = vel_min + 36.0
	p.gravity              = Vector2(0, 75)
	p.scale_amount_min     = 0.9
	p.scale_amount_max     = 1.8
	p.color                = Color(0.73, 0.05, 0.08, 0.85)
	p.local_coords         = false
	p.z_index              = 20
	p.global_position      = global_position
	get_parent().add_child(p)
	p.emitting = true
	await get_tree().create_timer(p.lifetime + 0.3).timeout
	if is_instance_valid(p):
		p.queue_free()

func _show_damage_number(amount: int) -> void:
	if amount <= 0:
		return
	var label := Label.new()
	label.text = str(amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", DAMAGE_FONT)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.82, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.32, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 4)
	label.top_level = true
	label.z_index = 35
	label.global_position = global_position + Vector2(randf_range(-12.0, 12.0), -18.0)
	get_tree().current_scene.add_child(label)

	var tween := label.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -42), 0.55)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.55)
	await tween.finished
	if is_instance_valid(label):
		label.queue_free()
