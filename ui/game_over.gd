## GameOver — shown when health reaches zero.
extends Control

@onready var score_label: Label   = %FinalScoreLabel
@onready var high_label: Label    = %HighScoreLabel
@onready var btn_retry: Button    = %BtnRetry
@onready var btn_menu: Button     = %BtnMenu

func _ready() -> void:
	_style_scene()
	score_label.text = "最终分数: %d" % GameManager.last_score
	score_label.add_theme_font_size_override("font_size", 26)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	high_label.text  = "最高分: %d"   % GameManager.high_score
	high_label.add_theme_font_size_override("font_size", 17)
	high_label.add_theme_color_override("font_color", Color(0.65, 0.75, 0.90))
	_style_btn(btn_retry, Color(0.28, 0.80, 0.48))
	_style_btn(btn_menu,  Color(0.42, 0.58, 0.95))
	btn_retry.pressed.connect(func(): GameManager.start_game(GameManager.current_scenario))
	btn_menu.pressed.connect(func():  GameManager.go_to_main_menu())
	_show_stats()
	_add_knowledge_btn()
	_entrance_anim()

func _style_scene() -> void:
	var bg := get_node_or_null("ColorRect") as ColorRect
	if bg:
		bg.color = Color(0.03, 0.05, 0.13, 1.0)
	var title := get_node_or_null("CenterContainer/VBoxContainer/TitleLabel") as Label
	if title:
		title.add_theme_color_override("font_color", Color(0.95, 0.32, 0.32))
		title.add_theme_color_override("font_outline_color", Color(0.40, 0.04, 0.04))
		title.add_theme_constant_override("outline_size", 7)
	var vbox := get_node_or_null("CenterContainer/VBoxContainer") as VBoxContainer
	if vbox:
		vbox.add_theme_constant_override("separation", 14)

func _style_btn(btn: Button, accent: Color) -> void:
	btn.custom_minimum_size = Vector2(220, 46)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r * 0.18, accent.g * 0.18, accent.b * 0.18, 0.88)
	sb.border_color = Color(accent.r * 0.85, accent.g * 0.85, accent.b * 0.85, 0.60)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(accent.r * 0.32, accent.g * 0.32, accent.b * 0.32, 0.96)
	sb_h.border_color = Color(accent.r, accent.g, accent.b, 0.90)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0))

func _add_knowledge_btn() -> void:
	var vbox := get_node_or_null("CenterContainer/VBoxContainer") as VBoxContainer
	if vbox == null:
		return
	var btn := Button.new()
	btn.text = "📖  查看知识库"
	_style_btn(btn, Color(0.58, 0.42, 0.95))
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://ui/knowledge_screen.tscn"))
	vbox.add_child(btn)

func _show_stats() -> void:
	var stats: Dictionary = GameManager.last_stats
	if stats.is_empty():
		return
	var vbox := get_node_or_null("CenterContainer/VBoxContainer") as VBoxContainer
	if vbox == null:
		return
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	vbox.add_child(container)
	# Place after HighScoreLabel (idx 2), before BtnRetry (idx 3)
	vbox.move_child(container, 3)

	var total: int = stats.get("total", 0)
	var correct: int = stats.get("correct", 0)
	var accuracy: int = 0
	if total > 0:
		accuracy = int(float(correct) / float(total) * 100.0)

	_add_stat(container, _stars(accuracy), Color(1.0, 0.82, 0.15), 32)
	var acc_color := Color(0.35, 0.92, 0.55) if accuracy >= 70 else Color(1.0, 0.62, 0.28)
	_add_stat(container, "正确率: %d%%  (%d / %d 题)" % [accuracy, correct, total], acc_color, 16)
	_add_stat(container, "最佳连击: %d" % stats.get("best_combo", 0), Color(0.65, 0.82, 1.0), 15)
	_add_stat(container, "被碰到: %d  ·  成功躲避: %d" % [stats.get("touched", 0), stats.get("dodged", 0)],
		Color(0.72, 0.72, 0.82), 14)
	var wrong_list: Array = stats.get("wrong_sentences", [])
	if wrong_list.size() > 0:
		_add_stat(container, "答错的句子:", Color(1.0, 0.52, 0.52), 14)
		for item in wrong_list:
			var d: Dictionary = item as Dictionary
			_add_stat(container, "• " + d.get("text", "") + " — " + d.get("explanation", ""),
				Color(0.78, 0.78, 0.86), 13)

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
	var center := get_node_or_null("CenterContainer") as CenterContainer
	if center == null:
		return
	center.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(center, "modulate:a", 1.0, 0.40)
