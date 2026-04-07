extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera := $Camera2D
@onready var health_bar: TextureProgressBar = $TextureProgressBar
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const WEAPONS_TEXTURE := preload("res://assets/sprites/Weapons.png")
const WEAPONS_GRID_COLUMNS := 4
const WEAPONS_GRID_ROWS := 5
const WEAPON_UPGRADE_POOL := [
	{"id": "hunter_axe", "name": "Hunter Axe", "damage_bonus": 30, "range_bonus": 10.0, "icon_cell": Vector2i(0, 0)},
	{"id": "saw_cleaver", "name": "Saw Cleaver", "damage_bonus": 28, "range_bonus": 16.0, "icon_cell": Vector2i(1, 0)},
	{"id": "kirkhammer", "name": "Kirkhammer", "damage_bonus": 40, "range_bonus": 6.0, "icon_cell": Vector2i(2, 0)},
	{"id": "threaded_cane", "name": "Threaded Cane", "damage_bonus": 20, "range_bonus": 26.0, "icon_cell": Vector2i(3, 0)},
	{"id": "ludwig_blade", "name": "Ludwig Blade", "damage_bonus": 35, "range_bonus": 14.0, "icon_cell": Vector2i(0, 1)},
	{"id": "beast_claw", "name": "Beast Claw", "damage_bonus": 27, "range_bonus": 20.0, "icon_cell": Vector2i(1, 1)}
]

var speed := 200.0
var max_health := 300
var health := max_health
var is_dead := false
var facing_direction := Vector2.DOWN

@export var axe_damage := 55
@export var axe_range := 200.0
@export var axe_arc_degrees := 100.0
@export var axe_cooldown := 0.55
@export var heal_percent_on_kill := 0.07
@export var axe_attack_lock_time := 0.12

var can_attack := true
var is_attacking := false

var blood_exp := 0
var player_level := 0
var pending_level_requirement := 0
var level_up_in_progress := false
var unlocked_upgrade_ids: Array[String] = []
var pending_upgrade_choices: Array[Dictionary] = []

var level_up_canvas: CanvasLayer
var level_up_panel: PanelContainer
var level_up_title: Label
var level_up_buttons: Array[Button] = []
var level_label: Label
var exp_progress_bar: ProgressBar
var exp_label: Label

func _ready():
	camera.make_current()
	health_bar.value = health
	health_bar.max_value = max_health
	var whip_data = load("res://data/whip_data.tres")
	$WeaponManager.add_weapon(whip_data)
	_setup_level_up_ui()
	_update_exp_ui()

func _physics_process(_delta):
	if is_dead:
		return
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		facing_direction = direction.normalized()

	if Input.is_action_just_pressed("attack") and can_attack:
		_start_axe_attack()

	if is_attacking:
		velocity = Vector2.ZERO
	else:
		velocity = direction * speed
	move_and_slide()
	update_animation(direction if not is_attacking else Vector2.ZERO)

func _start_axe_attack():
	can_attack = false
	is_attacking = true
	_perform_axe_hit()

	var lock_timer := get_tree().create_timer(axe_attack_lock_time)
	await lock_timer.timeout
	is_attacking = false

	var cooldown_timer := get_tree().create_timer(max(0.0, axe_cooldown - axe_attack_lock_time))
	await cooldown_timer.timeout
	can_attack = true

func _perform_axe_hit() -> void:
	# The axe is short range but high damage; we hit only enemies in front of the player.
	var half_arc_cos := cos(deg_to_rad(axe_arc_degrees * 0.5))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D:
			continue
		if not enemy.has_method("take_damage"):
			continue

		var to_enemy := global_position.direction_to(enemy.global_position)
		var distance := global_position.distance_to(enemy.global_position)
		if distance > axe_range:
			continue

		if facing_direction.dot(to_enemy) < half_arc_cos:
			continue

		var attack := Attack.new()
		attack.damage = axe_damage
		attack.knockback = 0.0
		attack.position = global_position
		enemy.take_damage(attack)

func update_animation(direction: Vector2):
	if is_attacking:
		sprite.play("idle")
		return
	if direction == Vector2.ZERO:
		sprite.play("idle")
	else:
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
	can_attack = false
	is_attacking = false
	velocity = Vector2.ZERO
	sprite.play("die")

func gain_blood_exp(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	blood_exp += amount
	_heal_after_enemy_kill()
	_update_exp_ui()
	_try_trigger_level_up()

func _try_trigger_level_up() -> void:
	if level_up_in_progress or is_dead:
		return

	var requirement := _required_blood_for_level(player_level + 1)
	if blood_exp >= requirement:
		pending_level_requirement = requirement
		_show_level_up_choices()

func _required_blood_for_level(target_level: int) -> int:
	# Level requirements: 1, 3, 5, ... (odd numbers).
	return max(1, target_level * 2 - 1)

func _setup_level_up_ui() -> void:
	level_up_canvas = CanvasLayer.new()
	level_up_canvas.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	level_up_canvas.layer = 20
	add_child(level_up_canvas)

	var hud_margin := MarginContainer.new()
	hud_margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud_margin.offset_left = 16
	hud_margin.offset_top = 16
	hud_margin.offset_right = 340
	hud_margin.offset_bottom = 140
	level_up_canvas.add_child(hud_margin)

	var hud_box := VBoxContainer.new()
	hud_box.add_theme_constant_override("separation", 6)
	hud_margin.add_child(hud_box)

	level_label = Label.new()
	level_label.text = "LVL 0"
	hud_box.add_child(level_label)

	exp_progress_bar = ProgressBar.new()
	exp_progress_bar.min_value = 0
	exp_progress_bar.max_value = 1
	exp_progress_bar.value = 0
	exp_progress_bar.custom_minimum_size = Vector2(260, 20)
	hud_box.add_child(exp_progress_bar)

	exp_label = Label.new()
	exp_label.text = "EXP 0 / 1"
	hud_box.add_child(exp_label)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_up_canvas.add_child(center)

	level_up_panel = PanelContainer.new()
	level_up_panel.custom_minimum_size = Vector2(780, 320)
	center.add_child(level_up_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	level_up_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	level_up_title = Label.new()
	level_up_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_up_title.text = "LEVEL UP"
	vbox.add_child(level_up_title)

	var subtitle := Label.new()
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.text = "Pick one item"
	vbox.add_child(subtitle)

	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation", 12)
	vbox.add_child(choices)

	for i in range(3):
		var button := Button.new()
		button.custom_minimum_size = Vector2(230, 190)
		button.expand_icon = true
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_level_up_choice_pressed.bind(i))
		choices.add_child(button)
		level_up_buttons.append(button)

	level_up_panel.visible = false

func _show_level_up_choices() -> void:
	if level_up_in_progress:
		return

	level_up_in_progress = true
	pending_upgrade_choices = _roll_upgrade_choices()

	for i in range(level_up_buttons.size()):
		var upgrade := pending_upgrade_choices[i]
		var damage_bonus := int(upgrade.get("damage_bonus", 0))
		var range_bonus := int(upgrade.get("range_bonus", 0.0))
		var weapon_name := str(upgrade.get("name", "Unknown"))
		var icon_cell_variant: Variant = upgrade.get("icon_cell", Vector2i.ZERO)
		var icon_cell: Vector2i = icon_cell_variant if icon_cell_variant is Vector2i else Vector2i.ZERO

		level_up_buttons[i].text = "%s\n+%d DMG | +%d RANGE" % [weapon_name, damage_bonus, range_bonus]
		level_up_buttons[i].icon = _make_weapon_icon(icon_cell)

	level_up_title.text = "LEVEL %d -> %d" % [player_level, player_level + 1]
	level_up_panel.visible = true
	get_tree().paused = true

func _roll_upgrade_choices() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for upgrade in WEAPON_UPGRADE_POOL:
		if not unlocked_upgrade_ids.has(str(upgrade["id"])):
			available.append(upgrade)

	var source: Array[Dictionary] = available
	if source.size() < 3:
		source = WEAPON_UPGRADE_POOL.duplicate(true)

	source.shuffle()

	var picked: Array[Dictionary] = []
	for upgrade in source:
		if picked.size() >= 3:
			break
		picked.append(upgrade)

	return picked

func _make_weapon_icon(icon_cell: Vector2i) -> Texture2D:
	var texture_size := WEAPONS_TEXTURE.get_size()
	var cell_size := Vector2(
		texture_size.x / float(WEAPONS_GRID_COLUMNS),
		texture_size.y / float(WEAPONS_GRID_ROWS)
	)
	var clamped_cell := Vector2i(
		clampi(icon_cell.x, 0, WEAPONS_GRID_COLUMNS - 1),
		clampi(icon_cell.y, 0, WEAPONS_GRID_ROWS - 1)
	)
	var region := Rect2(
		Vector2(clamped_cell.x * cell_size.x, clamped_cell.y * cell_size.y),
		cell_size
	)

	var icon := AtlasTexture.new()
	icon.atlas = WEAPONS_TEXTURE
	icon.region = region
	return icon

func _heal_after_enemy_kill() -> void:
	if health <= 0:
		return
	var heal_amount := int(max(1.0, round(max_health * heal_percent_on_kill)))
	health = min(max_health, health + heal_amount)
	health_bar.value = health

func _update_exp_ui() -> void:
	if level_label == null or exp_progress_bar == null or exp_label == null:
		return
	var needed := _required_blood_for_level(player_level + 1)
	level_label.text = "LVL %d" % player_level
	exp_progress_bar.max_value = needed
	exp_progress_bar.value = min(blood_exp, needed)
	exp_label.text = "EXP %d / %d" % [blood_exp, needed]

func _on_level_up_choice_pressed(choice_index: int) -> void:
	if choice_index < 0 or choice_index >= pending_upgrade_choices.size():
		return

	var chosen := pending_upgrade_choices[choice_index]
	_apply_upgrade(chosen)

	blood_exp = max(0, blood_exp - pending_level_requirement)
	player_level += 1
	pending_level_requirement = 0
	level_up_in_progress = false
	pending_upgrade_choices.clear()

	level_up_panel.visible = false
	get_tree().paused = false
	_update_exp_ui()

	_try_trigger_level_up()

func _apply_upgrade(upgrade: Dictionary) -> void:
	var damage_bonus := int(upgrade.get("damage_bonus", 0))
	var range_bonus := float(upgrade.get("range_bonus", 0.0))
	var upgrade_id := str(upgrade.get("id", ""))

	axe_damage += damage_bonus
	axe_range += range_bonus

	if not unlocked_upgrade_ids.has(upgrade_id):
		unlocked_upgrade_ids.append(upgrade_id)

func get_level() -> int:
	return player_level
