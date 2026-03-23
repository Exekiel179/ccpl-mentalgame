## MainMenu — entry screen; lets player pick scenario or access training.
extends Control

const VoiceServiceScript := preload("res://services/voice_service.gd")

@onready var btn_academic: Button       = %BtnAcademic
@onready var btn_family: Button         = %BtnFamily
@onready var btn_social: Button         = %BtnSocial
@onready var btn_knowledge: Button      = %BtnKnowledge
@onready var bg_sprite: Sprite2D        = %BGSprite
@onready var char_sprite: Sprite2D      = %CharSprite
@onready var gemini_service: Node       = $GeminiService
@onready var gemini_service_char: Node  = $GeminiServiceChar
var _status_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	btn_academic.pressed.connect(func(): GameManager.start_game("学业压力"))
	btn_family.pressed.connect(func():   GameManager.start_game("家庭矛盾"))
	btn_social.pressed.connect(func():   GameManager.start_game("社交压力"))
	btn_knowledge.pressed.connect(func(): GameManager.go_to_knowledge())

	_rebuild_menu()
	_setup_difficulty_buttons()
	_setup_reset_button()
	_update_model_status()

	AmbientMusic.start()
	gemini_service.image_ready.connect(_on_bg_ready)
	gemini_service.generate_background("主菜单")
	gemini_service_char.image_ready.connect(_on_char_ready)
	gemini_service_char.generate_background("立绘")

## Reconstructs the menu layout with proper styling and section headers.
func _rebuild_menu() -> void:
	var vbox := btn_academic.get_parent() as VBoxContainer
	if vbox == null:
		return

	# ── Fix title / subtitle (scene hardcodes black) ──────────────────────
	var title_lbl := vbox.get_node_or_null("TitleLabel") as Label
	if title_lbl:
		title_lbl.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
		title_lbl.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.24))
		title_lbl.add_theme_constant_override("outline_size", 8)
		title_lbl.add_theme_font_size_override("font_size", 48)

	var sub_lbl := vbox.get_node_or_null("SubtitleLabel") as Label
	if sub_lbl:
		sub_lbl.add_theme_color_override("font_color", Color(0.60, 0.78, 1.0))
		sub_lbl.add_theme_font_size_override("font_size", 17)

	# ── Section header: 选择场景 ────────────────────────────────────────────
	var scenario_lbl := vbox.get_node_or_null("ScenarioLabel") as Label
	if scenario_lbl:
		scenario_lbl.text = "🎮  选择场景"
		scenario_lbl.add_theme_font_size_override("font_size", 15)
		scenario_lbl.add_theme_color_override("font_color", Color(0.50, 0.70, 1.0))
		scenario_lbl.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.24))
		scenario_lbl.add_theme_constant_override("outline_size", 3)

	# ── Replace plain Divider with a section header row ────────────────────
	var divider := vbox.get_node_or_null("Divider")
	var insert_idx: int = btn_knowledge.get_index()
	if divider:
		insert_idx = divider.get_index()
		vbox.remove_child(divider)
		divider.queue_free()

	var sep := _make_sep(Color(0.40, 0.58, 1.0, 0.28))
	vbox.add_child(sep)
	vbox.move_child(sep, insert_idx)

	var training_hdr := Label.new()
	training_hdr.text = "🧠  训练入口"
	training_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	training_hdr.add_theme_font_size_override("font_size", 15)
	training_hdr.add_theme_color_override("font_color", Color(0.78, 0.55, 1.0))
	training_hdr.add_theme_color_override("font_outline_color", Color(0.10, 0.04, 0.22))
	training_hdr.add_theme_constant_override("outline_size", 3)
	vbox.add_child(training_hdr)
	vbox.move_child(training_hdr, insert_idx + 1)

	# BtnKnowledge is now at insert_idx + 2
	btn_knowledge.text = "📖  认知重构训练"

	# ── Style all buttons ──────────────────────────────────────────────────
	_style_btn(btn_academic, Color(0.30, 0.58, 1.0))
	_style_btn(btn_family,   Color(0.30, 0.58, 1.0))
	_style_btn(btn_social,   Color(0.30, 0.58, 1.0))
	_style_btn(btn_knowledge, Color(0.70, 0.45, 1.0), 200, 46, 17)

	# ── Wrap VBoxContainer in a glass card ─────────────────────────────────
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.09, 0.22, 0.90)
	sb.border_color = Color(0.35, 0.58, 1.0, 0.55)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(22)
	sb.shadow_color = Color(0.10, 0.26, 0.72, 0.34)
	sb.shadow_size = 22
	panel.add_theme_stylebox_override("panel", sb)

	var center := vbox.get_parent()
	center.remove_child(vbox)
	margin.add_child(vbox)
	panel.add_child(margin)
	center.add_child(panel)

	# ── Entrance animation ─────────────────────────────────────────────────
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.94, 0.94)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.40)
	tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.30).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _make_sep(color: Color) -> HSeparator:
	var sep := HSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	sep.add_theme_stylebox_override("separator", style)
	return sep

func _style_btn(btn: Button, accent: Color,
		min_w: int = 240, min_h: int = 44, font_sz: int = 18) -> void:
	btn.custom_minimum_size = Vector2(min_w, min_h)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r * 0.16, accent.g * 0.16, accent.b * 0.16, 0.88)
	sb.border_color = Color(accent.r * 0.82, accent.g * 0.82, accent.b * 0.82, 0.55)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 9.0
	sb.content_margin_bottom = 9.0
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(accent.r * 0.28, accent.g * 0.28, accent.b * 0.28, 0.96)
	sb_h.border_color = Color(accent.r, accent.g, accent.b, 0.88)
	btn.add_theme_stylebox_override("hover", sb_h)
	var sb_p := sb.duplicate() as StyleBoxFlat
	sb_p.bg_color = Color(accent.r * 0.38, accent.g * 0.38, accent.b * 0.38, 1.0)
	btn.add_theme_stylebox_override("pressed", sb_p)
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))

func _setup_difficulty_buttons() -> void:
	var parent := btn_academic.get_parent()
	if parent == null:
		return
	var sep := _make_sep(Color(0.35, 0.55, 0.95, 0.22))
	parent.add_child(sep)

	var diff_label := Label.new()
	diff_label.text = "⚙  难度"
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_label.add_theme_font_size_override("font_size", 14)
	diff_label.add_theme_color_override("font_color", Color(0.62, 0.75, 0.95))
	parent.add_child(diff_label)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	parent.add_child(hbox)

	var names: Array = ["简单", "普通", "困难"]
	var accents: Array = [Color(0.30, 0.80, 0.50), Color(0.30, 0.58, 1.0), Color(0.95, 0.38, 0.38)]
	for i in 3:
		var btn := Button.new()
		btn.text = names[i] as String
		var idx: int = i
		btn.pressed.connect(func(): _set_difficulty(idx))
		hbox.add_child(btn)
		_style_btn(btn, accents[i] as Color, 88, 36, 14)
		if i == GameManager.difficulty:
			btn.disabled = true

func _setup_reset_button() -> void:
	var parent := btn_academic.get_parent()
	if parent == null:
		return
	var sep := _make_sep(Color(0.35, 0.55, 0.95, 0.18))
	parent.add_child(sep)

	var btn := Button.new()
	btn.text = "🎤  重置语音模型"
	btn.pressed.connect(_reset_voice_model)
	parent.add_child(btn)
	_style_btn(btn, Color(0.55, 0.40, 0.80), 240, 38, 15)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 13)
	parent.add_child(_status_label)

func _update_model_status() -> void:
	if _status_label == null:
		return
	if GameManager.has_voice_calibration():
		_status_label.text = "✅ 已有语音模型，可直接游戏"
		_status_label.add_theme_color_override("font_color", Color(0.45, 0.90, 0.60))
	else:
		_status_label.text = "⚠ 未检测到语音模型，建议先训练"
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.38))

func _reset_voice_model() -> void:
	var voice_service := VoiceServiceScript.new()
	add_child(voice_service)
	voice_service.reset_calibration()
	voice_service.queue_free()
	GameManager.current_level = 1
	_update_model_status()

func _set_difficulty(idx: int) -> void:
	GameManager.difficulty = idx
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _on_bg_ready(texture: Texture2D) -> void:
	bg_sprite.texture = texture
	var vp := get_viewport_rect().size
	bg_sprite.position = vp * 0.5
	var tex_size := texture.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		bg_sprite.scale = Vector2(vp.x / tex_size.x, vp.y / tex_size.y)

func _on_char_ready(texture: Texture2D) -> void:
	char_sprite.texture = texture
	var tween := create_tween()
	tween.tween_property(char_sprite, "modulate:a", 1.0, 0.8)
