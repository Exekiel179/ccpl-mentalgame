## PauseMenu — overlay shown when ESC is pressed during gameplay.
extends CanvasLayer

var _panel: PanelContainer

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.03, 0.08, 0.72)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(340, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.11, 0.24, 0.94)
	style.border_color = Color(0.38, 0.60, 1.0, 0.65)
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0.10, 0.28, 0.70, 0.38)
	style.shadow_size = 18
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "⏸  已暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.20))
	title.add_theme_constant_override("outline_size", 4)
	vbox.add_child(title)

	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.35, 0.58, 1.0, 0.28)
	sep_style.content_margin_top = 1.0
	sep_style.content_margin_bottom = 1.0
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	var btn_resume := _make_btn("▶  继续游戏", Color(0.28, 0.80, 0.48))
	btn_resume.pressed.connect(_on_resume)
	vbox.add_child(btn_resume)

	var btn_knowledge := _make_btn("📖  知识库", Color(0.48, 0.65, 1.0))
	btn_knowledge.pressed.connect(_on_knowledge)
	vbox.add_child(btn_knowledge)

	var btn_quit := _make_btn("🏠  返回主菜单", Color(0.90, 0.40, 0.40))
	btn_quit.pressed.connect(_on_quit)
	vbox.add_child(btn_quit)

func _make_btn(label_text: String, accent: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(240, 44)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r * 0.16, accent.g * 0.16, accent.b * 0.16, 0.88)
	sb.border_color = Color(accent.r * 0.8, accent.g * 0.8, accent.b * 0.8, 0.55)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(accent.r * 0.28, accent.g * 0.28, accent.b * 0.28, 0.96)
	sb_h.border_color = Color(accent.r, accent.g, accent.b, 0.85)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0))
	return btn

func toggle() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	visible = paused
	if paused and _panel:
		_panel.scale = Vector2(0.88, 0.88)
		_panel.modulate.a = 0.0
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(_panel, "modulate:a", 1.0, 0.14)

func _on_resume() -> void:
	get_tree().paused = false
	visible = false

func _on_knowledge() -> void:
	get_tree().paused = false
	visible = false
	AmbientMusic.stop()
	get_tree().change_scene_to_file("res://ui/knowledge_screen.tscn")

func _on_quit() -> void:
	get_tree().paused = false
	visible = false
	AmbientMusic.stop()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
