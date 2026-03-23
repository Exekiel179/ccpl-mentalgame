## GameWin — shown when player clears all three levels.
extends Control

@onready var time_label: Label   = %TimeBonusLabel
@onready var score_label: Label  = %ScoreLabel
@onready var high_label: Label   = %HighScoreLabel
@onready var btn_retry: Button   = %BtnRetry
@onready var btn_menu: Button    = %BtnMenu

func _ready() -> void:
	_style_scene()
	score_label.text = "心灵成长印记: %d" % GameManager.last_score
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15)) # Deep Warm Brown
	high_label.text  = "最佳纪录: %d"   % GameManager.high_score
	high_label.add_theme_font_size_override("font_size", 18)
	high_label.add_theme_color_override("font_color", Color(0.45, 0.4, 0.35)) # Muted Taupe
	time_label.text  = "宁静的心境为你带来了额外成长！"
	time_label.add_theme_font_size_override("font_size", 16)
	time_label.add_theme_color_override("font_color", Color(0.45, 0.4, 0.35))
	
	var accent_retry := Color(0.52, 0.64, 0.54) # Sage Green
	var accent_menu := Color(0.85, 0.80, 0.70) # Warm Beige
	_style_btn(btn_retry, accent_retry)
	_style_btn(btn_menu,  accent_menu)
	
	btn_retry.pressed.connect(func(): GameManager.start_game(GameManager.current_scenario))
	btn_menu.pressed.connect(func():  GameManager.go_to_main_menu())
	_show_stats()
	_add_knowledge_btn()
	_entrance_anim()

func _style_scene() -> void:
	var bg := get_node_or_null("Background") as ColorRect
	if bg:
		bg.color = Color(0.92, 0.95, 0.90, 1.0) # Very soft mint/sage
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		
	var title := get_node_or_null("CenterContainer/TitleLabel") as Label
	if title:
		title.text = "🌿 心灵的蜕变"
		title.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15)) # Deep Warm Brown
		title.remove_theme_color_override("font_outline_color")
		title.remove_theme_constant_override("outline_size")
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
	var vbox := get_node_or_null("CenterContainer") as VBoxContainer
	if vbox:
		vbox.add_theme_constant_override("separation", 20)
		
		# Wrap in a soft healing panel
		var panel := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1.0, 1.0, 1.0, 0.75)
		sb.set_corner_radius_all(32)
		sb.shadow_color = Color(0.2, 0.3, 0.2, 0.08) # Alpha <= 0.1
		sb.shadow_size = 25
		panel.add_theme_stylebox_override("panel", sb)
		
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 50)
		margin.add_theme_constant_override("margin_right", 50)
		margin.add_theme_constant_override("margin_top", 40)
		margin.add_theme_constant_override("margin_bottom", 40)
		
		var parent := vbox.get_parent()
		parent.remove_child(vbox)
		margin.add_child(vbox)
		panel.add_child(margin)
		parent.add_child(panel)

func _style_btn(btn: Button, accent: Color) -> void:
	btn.custom_minimum_size = Vector2(240, 48)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.9)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 24.0
	sb.content_margin_right = 24.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.08) # Alpha <= 0.1
	sb.shadow_size = 4
	btn.add_theme_stylebox_override("normal", sb)
	
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = sb.bg_color.lightened(0.1) # Lightened hover
	sb_h.shadow_size = 10
	btn.add_theme_stylebox_override("hover", sb_h)
	
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color.WHITE if accent.v < 0.8 else Color(0.25, 0.2, 0.15))

func _add_knowledge_btn() -> void:
	var vbox := get_node_or_null("CenterContainer") as VBoxContainer
	if vbox == null:
		return
	var btn := Button.new()
	btn.text = "📖  深化认知重构"
	_style_btn(btn, Color(0.95, 0.75, 0.45)) # Warm Gold
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://ui/knowledge_screen.tscn"))
	vbox.add_child(btn)

func _show_stats() -> void:
	var stats: Dictionary = GameManager.last_stats
	if stats.is_empty():
		return
	var vbox := get_node_or_null("CenterContainer") as VBoxContainer
	if vbox == null:
		return
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	vbox.add_child(container)
	# Place after HighScoreLabel (idx 3), before BtnRetry (idx 4)
	vbox.move_child(container, 4)

	var total: int = stats.get("total", 0)
	var correct: int = stats.get("correct", 0)
	var accuracy: int = 0
	if total > 0:
		accuracy = int(float(correct) / float(total) * 100.0)

	_add_stat(container, _stars(accuracy), Color(1.0, 0.85, 0.15), 32)
	var acc_color := Color(0.35, 0.65, 0.45) if accuracy >= 70 else Color(0.8, 0.6, 0.5) # Terra Cotta
	_add_stat(container, "正确率: %d%%  (%d / %d 题)" % [accuracy, correct, total], acc_color, 16)
	_add_stat(container, "最佳连击: %d" % stats.get("best_combo", 0), Color(0.45, 0.55, 0.75), 15)
	_add_stat(container, "被碰到: %d  ·  成功躲避: %d" % [stats.get("touched", 0), stats.get("dodged", 0)],
		Color(0.45, 0.4, 0.35), 14)
	var wrong_list: Array = stats.get("wrong_sentences", [])
	if wrong_list.size() > 0:
		_add_stat(container, "答错的句子:", Color(0.75, 0.5, 0.5), 14) # Muted Rose
		for item in wrong_list:
			var d: Dictionary = item as Dictionary
			_add_stat(container, "• " + d.get("text", "") + " — " + d.get("explanation", ""),
				Color(0.45, 0.4, 0.35), 13)

func _stars(accuracy: int) -> String:
	if accuracy >= 90: return "★★★"
	if accuracy >= 70: return "★★☆"
	if accuracy >= 50: return "★☆☆"
	return "☆☆☆"

func _add_stat(container: VBoxContainer, text: String, color: Color, font_size: int) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	container.add_child(lbl)

func _entrance_anim() -> void:
	var vbox := get_node_or_null("CenterContainer") as VBoxContainer
	if vbox == null:
		return
	vbox.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(vbox, "modulate:a", 1.0, 0.45)
