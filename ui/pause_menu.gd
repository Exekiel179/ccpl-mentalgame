## PauseMenu — overlay shown when ESC is pressed during gameplay.
extends CanvasLayer

var _panel: PanelContainer

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

	var bg := ColorRect.new()
	bg.color = Color(1.0, 0.98, 0.95, 0.45) # Warm semi-transparent white
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(360, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.9) # Clean Glass
	style.border_color = Color(0.9, 0.85, 0.8, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(32)
	style.shadow_color = Color(0.3, 0.2, 0.1, 0.07)
	style.shadow_size = 22
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
	title.text = "🌿  稍作休息"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15))
	vbox.add_child(title)

	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.85, 0.80, 0.70, 0.4)
	sep_style.content_margin_top = 1.0
	sep_style.content_margin_bottom = 1.0
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	var btn_resume := _make_btn("▶  继续成长", Color(0.52, 0.64, 0.54))
	btn_resume.pressed.connect(_on_resume)
	vbox.add_child(btn_resume)

	var btn_knowledge := _make_btn("📖  心灵知识", Color(0.92, 0.65, 0.50))
	btn_knowledge.pressed.connect(_on_knowledge)
	vbox.add_child(btn_knowledge)

	var btn_quit := _make_btn("🏠  返回主菜单", Color(0.85, 0.80, 0.75))
	btn_quit.pressed.connect(_on_quit)
	vbox.add_child(btn_quit)

func _make_btn(label_text: String, accent: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(240, 48)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.9)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.08) # Alpha <= 0.1
	sb.shadow_size = 4
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = sb.bg_color.lightened(0.1) # Lightened hover
	sb_h.shadow_size = 8
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color.WHITE if accent.v < 0.8 else Color(0.25, 0.2, 0.15))
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
