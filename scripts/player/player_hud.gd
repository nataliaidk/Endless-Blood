extends CanvasLayer

const UI_FONT := preload("res://assets/fonts/Gothikka.ttf")

var kills: int = 0

@onready var player          = get_parent()
@onready var leveling        = get_parent().get_node("PlayerLeveling")
@onready var weapon_manager  = get_parent().get_node("WeaponManager")

@onready var kills_label:      Label       = %KillsLabel
@onready var exp_progress_bar: ProgressBar = %ExpBar
@onready var time_label:       Label       = %TimeLabel
@onready var level_label: Label = %LevelLabel

@onready var weapon_slots: Array[Panel] = [
	%WeaponSlot0, %WeaponSlot1, %WeaponSlot2, %WeaponSlot3
]
@onready var item_slots: Array[Panel] = [
	%ItemSlot0, %ItemSlot1, %ItemSlot2,
	%ItemSlot3, %ItemSlot4, %ItemSlot5
]

func _ready():
	player.exp_gained.connect(_on_player_exp_gained)
	leveling.upgrade_applied.connect(_on_upgrade_applied)
	weapon_manager.weapon_added.connect(_on_weapon_added)
	_refresh_exp_bar()

func _process(_delta):
	var minutes := int(GameTimer.seconds()) / 60
	var secs    := int(GameTimer.seconds()) % 60
	time_label.text = "%d:%02d" % [minutes, secs]

func add_kill():
	kills += 1
	kills_label.text = str(kills)

func _on_weapon_added(weapon_data: WeaponData):
	var index = weapon_manager.active_weapons.size() - 1
	update_weapon_slot(index, weapon_data.icon)

func update_weapon_slot(index: int, icon: Texture2D) -> void:
	if index >= weapon_slots.size():
		return
	var tex := TextureRect.new()
	tex.texture = icon
	tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	weapon_slots[index].add_child(tex)

func _on_player_exp_gained(_amount: int):
	_refresh_exp_bar()

func _on_upgrade_applied(_upgrade: Dictionary):
	_refresh_exp_bar()

func _refresh_exp_bar():
	var needed: int = leveling._required_blood(leveling.player_level + 1)
	exp_progress_bar.max_value = needed
	exp_progress_bar.value = min(leveling.blood_exp, needed)
	level_label.text = "LVL " + str(leveling.player_level)
