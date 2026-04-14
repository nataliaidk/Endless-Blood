extends CanvasLayer

const WEAPONS_TEXTURE    := preload("res://assets/sprites/Weapons.png")
const WEAPONS_GRID_COLUMNS := 4
const WEAPONS_GRID_ROWS    := 5
const UI_FONT := preload("res://assets/fonts/Gothikka.ttf")

var level_up_panel: PanelContainer
var level_up_title: Label
var level_up_buttons: Array[Button] = []
var level_label: Label
var exp_progress_bar: ProgressBar
var exp_label: Label

var _current_choices: Array[Dictionary] = []

@onready var player   = get_parent()
@onready var leveling = get_parent().get_node("PlayerLeveling")

func _ready():
	layer = 20
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_build_ui()
	player.exp_gained.connect(_on_player_exp_gained)
	leveling.level_up_ready.connect(_on_level_up_ready)
	leveling.upgrade_applied.connect(_on_upgrade_applied)
	_refresh_exp_bar()

func _build_ui():
	# --- HUD (lewy górny róg) ---
	var hud := MarginContainer.new()
	hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud.offset_left = 16; hud.offset_top = 16
	hud.offset_right = 340; hud.offset_bottom = 140
	add_child(hud)

	var hud_box := VBoxContainer.new()
	hud_box.add_theme_constant_override("separation", 6)
	hud.add_child(hud_box)

	level_label = Label.new()
	level_label.add_theme_font_override("font", UI_FONT)
	level_label.add_theme_font_size_override("font_size", 26)
	level_label.add_theme_color_override("font_color", Color(0.98, 0.93, 0.88, 1.0))
	level_label.add_theme_color_override("font_outline_color", Color(0.07, 0.02, 0.02, 1.0))
	level_label.add_theme_constant_override("outline_size", 2)
	hud_box.add_child(level_label)

	exp_progress_bar = ProgressBar.new()
	exp_progress_bar.min_value = 0
	exp_progress_bar.max_value = 1
	exp_progress_bar.custom_minimum_size = Vector2(260, 20)
	exp_progress_bar.add_theme_stylebox_override("background", _make_progress_background_style())
	exp_progress_bar.add_theme_stylebox_override("fill", _make_progress_fill_style())
	hud_box.add_child(exp_progress_bar)

	exp_label = Label.new()
	exp_label.add_theme_font_override("font", UI_FONT)
	exp_label.add_theme_font_size_override("font_size", 18)
	exp_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.8, 1.0))
	exp_label.add_theme_color_override("font_outline_color", Color(0.07, 0.02, 0.02, 1.0))
	exp_label.add_theme_constant_override("outline_size", 1)
	hud_box.add_child(exp_label)

	# --- Panel level-up (wyśrodkowany) ---
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	level_up_panel = PanelContainer.new()
	level_up_panel.custom_minimum_size = Vector2(780, 320)
	level_up_panel.add_theme_stylebox_override("panel", _make_levelup_panel_style())
	center.add_child(level_up_panel)

	var margin := MarginContainer.new()
	for side in ["top","bottom","left","right"]:
		margin.add_theme_constant_override("margin_" + side, 20 if side in ["top","bottom"] else 24)
	level_up_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	level_up_title = Label.new()
	level_up_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_up_title.add_theme_font_override("font", UI_FONT)
	level_up_title.add_theme_font_size_override("font_size", 44)
	level_up_title.add_theme_color_override("font_color", Color(0.99, 0.95, 0.9, 1.0))
	level_up_title.add_theme_color_override("font_outline_color", Color(0.12, 0.03, 0.03, 1.0))
	level_up_title.add_theme_constant_override("outline_size", 3)
	level_up_title.text = "LEVEL UP"
	vbox.add_child(level_up_title)

	var subtitle := Label.new()
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", UI_FONT)
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.92, 0.82, 0.74, 1.0))
	subtitle.text = "Pick one item"
	vbox.add_child(subtitle)

	var choices_row := HBoxContainer.new()
	choices_row.add_theme_constant_override("separation", 12)
	vbox.add_child(choices_row)

	for i in range(3):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(240, 220)
		btn.expand_icon = false
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_override("font", UI_FONT)
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_constant_override("h_separation", 12)
		btn.add_theme_constant_override("icon_max_width", 96)
		btn.add_theme_color_override("font_color", Color(0.98, 0.94, 0.88, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.97, 0.93, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.91, 0.78, 1.0))
		btn.add_theme_color_override("font_focus_color", Color(1.0, 0.97, 0.93, 1.0))
		btn.add_theme_color_override("icon_normal_color", Color(1, 1, 1, 1))
		btn.add_theme_color_override("icon_hover_color", Color(1, 1, 1, 1))
		btn.add_theme_color_override("icon_pressed_color", Color(1, 1, 1, 1))
		btn.add_theme_color_override("icon_focus_color", Color(1, 1, 1, 1))
		btn.add_theme_stylebox_override("normal", _make_choice_button_style(Color(0.13, 0.06, 0.06, 0.95), Color(0.52, 0.16, 0.16, 1.0)))
		btn.add_theme_stylebox_override("hover", _make_choice_button_style(Color(0.19, 0.08, 0.08, 0.98), Color(0.83, 0.28, 0.28, 1.0)))
		btn.add_theme_stylebox_override("pressed", _make_choice_button_style(Color(0.31, 0.12, 0.1, 1.0), Color(0.95, 0.48, 0.32, 1.0)))
		btn.add_theme_stylebox_override("focus", _make_choice_button_style(Color(0.19, 0.08, 0.08, 0.98), Color(0.83, 0.28, 0.28, 1.0)))
		btn.pressed.connect(_on_choice_pressed.bind(i))
		choices_row.add_child(btn)
		level_up_buttons.append(btn)

	level_up_panel.visible = false

func _on_level_up_ready(choices: Array[Dictionary]):
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_current_choices = choices
	level_up_title.text = "LEVEL %d → %d" % [leveling.player_level, leveling.player_level + 1]
	if choices.is_empty():
		level_up_panel.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		get_tree().paused = false
		return
	for i in range(level_up_buttons.size()):
		if i >= choices.size():
			level_up_buttons[i].visible = false
			continue
		level_up_buttons[i].visible = true
		var u := choices[i]
		level_up_buttons[i].text = "%s\nDMG +%d   RNG +%d" % [
			u.get("name", "?"),
			int(u.get("damage_bonus", 0)),
			int(u.get("range_bonus", 0.0))
		]
		level_up_buttons[i].icon = _make_icon(u.get("icon_cell", Vector2i.ZERO))
	level_up_panel.visible = true
	get_tree().paused = true

func _on_choice_pressed(index: int):
	level_up_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().paused = false
	leveling.on_upgrade_chosen(index, _current_choices)
	_refresh_exp_bar()

func _on_upgrade_applied(_upgrade: Dictionary):
	_refresh_exp_bar()

func _on_player_exp_gained(_amount: int):
	_refresh_exp_bar()

func _refresh_exp_bar():
	var needed :int = leveling._required_blood(leveling.player_level + 1)
	exp_progress_bar.max_value = needed
	exp_progress_bar.value = min(leveling.blood_exp, needed)
	level_label.text = "LEVEL %d" % leveling.player_level
	exp_label.text = "BLOOD %d / %d" % [int(exp_progress_bar.value), needed]

func _make_icon(icon_cell: Vector2i) -> Texture2D:
	var tex_size := WEAPONS_TEXTURE.get_size()
	var cell := Vector2(tex_size.x / float(WEAPONS_GRID_COLUMNS), tex_size.y / float(WEAPONS_GRID_ROWS))
	var clamped := Vector2i(
		clampi(icon_cell.x, 0, WEAPONS_GRID_COLUMNS - 1),
		clampi(icon_cell.y, 0, WEAPONS_GRID_ROWS - 1)
	)
	var icon := AtlasTexture.new()
	icon.atlas = WEAPONS_TEXTURE
	icon.region = Rect2(Vector2(clamped.x * cell.x, clamped.y * cell.y), cell)
	return icon

func _make_levelup_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.02, 0.02, 0.94)
	sb.border_color = Color(0.76, 0.27, 0.2, 0.95)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 14
	sb.corner_radius_bottom_left = 14
	sb.shadow_size = 10
	sb.shadow_color = Color(0, 0, 0, 0.4)
	return sb

func _make_choice_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb

func _make_progress_background_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.03, 0.03, 0.88)
	sb.border_color = Color(0.44, 0.16, 0.16, 1.0)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	return sb

func _make_progress_fill_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.84, 0.16, 0.12, 1.0)
	sb.corner_radius_top_left = 7
	sb.corner_radius_top_right = 7
	sb.corner_radius_bottom_right = 7
	sb.corner_radius_bottom_left = 7
	return sb
