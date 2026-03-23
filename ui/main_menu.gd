## MainMenu — entry screen; lets player pick scenario or access training.
extends Control

const VoiceServiceScript := preload("res://services/voice_service.gd")

@onready var btn_academic: Button       = %BtnAcademic
@onready var btn_family: Button         = %BtnFamily
@onready var btn_social: Button         = %BtnSocial
@onready var btn_knowledge: Button      = %BtnKnowledge
var _card_mode_btns: Array[Button] = []
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
	_setup_card_mode_section()
	_setup_difficulty_buttons()
	_setup_reset_button()
	_update_model_status()

	AmbientMusic.start(AmbientMusic.Track.MENU)
	gemini_service.image_ready.connect(_on_bg_ready)
	gemini_service.generate_background("温暖治愈的心理咨询室，有阳光洒进窗户，极简风格，温馨的木质家具，绿植，电影感光效")
	gemini_service_char.image_ready.connect(_on_char_ready)
	gemini_service_char.generate_background("温柔亲切的心理咨询师立绘，穿着柔软的针织衫，温和的微笑，高画质，二次元风格")

## Reconstructs the menu layout with proper styling and section headers.
func _rebuild_menu() -> void:
	var vbox := btn_academic.get_parent() as VBoxContainer
	if vbox == null:
		return

	# ── Fix title / subtitle (scene hardcodes black) ──────────────────────
	var title_lbl := vbox.get_node_or_null("TitleLabel") as Label
	if title_lbl:
		title_lbl.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15)) # Deep Warm Brown
		title_lbl.remove_theme_color_override("font_outline_color")
		title_lbl.add_theme_font_size_override("font_size", 52)
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var sub_lbl := vbox.get_node_or_null("SubtitleLabel") as Label
	if sub_lbl:
		sub_lbl.add_theme_color_override("font_color", Color(0.45, 0.4, 0.35)) # Muted Taupe
		sub_lbl.add_theme_font_size_override("font_size", 18)
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# ── Section header: 选择场景 ────────────────────────────────────────────
	var scenario_lbl := vbox.get_node_or_null("ScenarioLabel") as Label
	if scenario_lbl:
		scenario_lbl.text = "🌿  选择治愈场景"
		scenario_lbl.add_theme_font_size_override("font_size", 16)
		scenario_lbl.add_theme_color_override("font_color", Color(0.40, 0.45, 0.35)) # Sage Green
		scenario_lbl.remove_theme_color_override("font_outline_color")
		scenario_lbl.remove_theme_constant_override("outline_size")
		scenario_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		scenario_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# ── Replace plain Divider with a section header row ────────────────────
	var divider := vbox.get_node_or_null("Divider")
	var insert_idx: int = btn_knowledge.get_index()
	if divider:
		insert_idx = divider.get_index()
		vbox.remove_child(divider)
		divider.queue_free()

	var sep := _make_sep(Color(0.85, 0.80, 0.70, 0.40)) # Warm separator
	vbox.add_child(sep)
	vbox.move_child(sep, insert_idx)

	var training_hdr := Label.new()
	training_hdr.text = "🌱  自我成长训练"
	training_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	training_hdr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	training_hdr.add_theme_font_size_override("font_size", 16)
	training_hdr.add_theme_color_override("font_color", Color(0.45, 0.4, 0.35)) # Muted Taupe
	vbox.add_child(training_hdr)
	vbox.move_child(training_hdr, insert_idx + 1)

	# BtnKnowledge is now at insert_idx + 2
	btn_knowledge.text = "📖  探索认知重构"

	# ── Style all buttons ──────────────────────────────────────────────────
	var primary_color := Color(0.52, 0.64, 0.54) # Sage Green
	var secondary_color := Color(0.92, 0.60, 0.45) # Warm Coral/Orange
	
	_style_btn(btn_academic, primary_color)
	_style_btn(btn_family,   primary_color)
	_style_btn(btn_social,   primary_color)
	_style_btn(btn_knowledge, secondary_color, 240, 48, 18)

	# ── Wrap VBoxContainer in a glass card ─────────────────────────────────
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.98, 0.95, 0.85) # Semi-transparent Warm White
	sb.border_color = Color(0.90, 0.85, 0.80, 0.50)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(32)
	sb.shadow_color = Color(0.3, 0.2, 0.1, 0.08) # Soft warm shadow transparency <= 0.1
	sb.shadow_size = 30
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
	# Soft, slightly desaturated background
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.9)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 24.0
	sb.content_margin_right = 24.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	# Remove harsh borders, use subtle shadow instead
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.08) # Transparency <= 0.1
	sb.shadow_size = 4
	btn.add_theme_stylebox_override("normal", sb)
	
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = sb.bg_color.lightened(0.1) # Uniform lightened hover
	sb_h.shadow_size = 8
	btn.add_theme_stylebox_override("hover", sb_h)
	
	var sb_p := sb.duplicate() as StyleBoxFlat
	sb_p.bg_color = Color(accent.r * 0.9, accent.g * 0.9, accent.b * 0.9, 1.0)
	sb_p.shadow_size = 2
	btn.add_theme_stylebox_override("pressed", sb_p)
	
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))

func _setup_card_mode_section() -> void:
	var parent := btn_academic.get_parent()
	if parent == null:
		return
	var sep := _make_sep(Color(0.85, 0.75, 0.65, 0.35))
	parent.add_child(sep)

	var card_hdr := Label.new()
	card_hdr.text = "🧡  卡牌心灵对战"
	card_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_hdr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_hdr.add_theme_font_size_override("font_size", 16)
	card_hdr.add_theme_color_override("font_color", Color(0.45, 0.4, 0.35)) # Muted Taupe
	parent.add_child(card_hdr)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	parent.add_child(hbox)

	var scenarios: Array = ["学业压力", "家庭矛盾", "社交压力"]
	var emojis: Array    = ["📚", "🏠", "👥"]
	var card_accent := Color(0.65, 0.55, 0.75) # Muted Lavender for card mode
	for i in 3:
		var btn := Button.new()
		btn.text = "%s %s" % [emojis[i], scenarios[i]]
		var sc: String = scenarios[i]
		btn.pressed.connect(func(): GameManager.start_card_game(sc))
		hbox.add_child(btn)
		_style_btn(btn, card_accent, 124, 40, 15)
		_card_mode_btns.append(btn)

func _setup_difficulty_buttons() -> void:
	var parent := btn_academic.get_parent()
	if parent == null:
		return
	var sep := _make_sep(Color(0.85, 0.75, 0.65, 0.30))
	parent.add_child(sep)

	var diff_label := Label.new()
	diff_label.text = "调节挑战节奏"
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diff_label.add_theme_font_size_override("font_size", 14)
	diff_label.add_theme_color_override("font_color", Color(0.45, 0.4, 0.35)) # Muted Taupe
	parent.add_child(diff_label)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	parent.add_child(hbox)

	var names: Array = ["轻柔", "适中", "深刻"]
	var accents: Array = [Color(0.65, 0.75, 0.60), Color(0.65, 0.70, 0.80), Color(0.75, 0.5, 0.5)] # Muted Rose for 'Hard'
	for i in 3:
		var btn := Button.new()
		btn.text = names[i] as String
		var idx: int = i
		btn.pressed.connect(func(): _set_difficulty(idx))
		hbox.add_child(btn)
		_style_btn(btn, accents[i] as Color, 96, 38, 15)
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
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 13)
	parent.add_child(_status_label)

func _update_model_status() -> void:
	if _status_label == null:
		return
	if GameManager.has_voice_calibration():
		_status_label.text = "✅ 已有语音模型，可直接游戏"
		_status_label.add_theme_color_override("font_color", Color(0.35, 0.65, 0.45)) # Soft Green
	else:
		_status_label.text = "⚠ 未检测到语音模型，建议先训练"
		_status_label.add_theme_color_override("font_color", Color(0.75, 0.5, 0.5)) # Muted Rose

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
	char_sprite.modulate = Color(1, 1, 1, 0)
	
	# Position at bottom right
	var vp := get_viewport_rect().size
	var tex_size := texture.get_size()
	
	# Scale to fit height (about 85% of screen)
	var scale_factor := (vp.y * 0.85) / tex_size.y
	char_sprite.scale = Vector2(scale_factor, scale_factor)
	char_sprite.position = Vector2(vp.x * 0.75, vp.y - (tex_size.y * scale_factor * 0.5))
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(char_sprite, "modulate:a", 1.0, 1.0)
	# Slight slide-in from right
	var target_pos := char_sprite.position
	char_sprite.position.x += 30
	tween.tween_property(char_sprite, "position:x", target_pos.x, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
