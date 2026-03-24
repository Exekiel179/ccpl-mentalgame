## KnowledgeScreen — psychology flashcards with random draw and detail modal.
extends Control

const CARD_MIN_SIZE := Vector2(0, 340)
const CARD_COUNT := 3

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var cards_row: HBoxContainer = %CardsRow
@onready var btn_match_game: Button = %BtnMatchGame
@onready var btn_refresh: Button = %BtnRefresh
@onready var btn_start: Button = %BtnStart
@onready var btn_menu: Button = %BtnMenu
@onready var overlay: Control = %Overlay
@onready var detail_title_label: Label = %DetailTitleLabel
@onready var detail_meta_label: Label = %DetailMetaLabel
@onready var detail_body_label: Label = %DetailBodyLabel
@onready var detail_example_label: Label = %DetailExampleLabel
@onready var btn_close_detail: Button = %BtnCloseDetail

var _current_cards: Array[Dictionary] = []
var _previous_card_ids: Array[String] = []

func _ready() -> void:
	_style_scene()
	_update_mode_copy()
	btn_match_game.pressed.connect(func(): GameManager.go_to_knowledge_match())
	btn_refresh.pressed.connect(_refresh_cards)
	btn_start.pressed.connect(_start_selected_mode)
	btn_menu.pressed.connect(func(): GameManager.go_to_main_menu())
	btn_close_detail.pressed.connect(_close_detail)
	overlay.gui_input.connect(_on_overlay_input)
	_refresh_cards()

func _style_scene() -> void:
	var main_panel := get_node_or_null("CenterContainer/MainPanel") as PanelContainer
	if main_panel:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1.0, 0.995, 0.985, 0.90)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.95, 0.86, 0.80, 0.75)
		sb.set_corner_radius_all(34)
		sb.shadow_color = Color(0.35, 0.24, 0.18, 0.08)
		sb.shadow_size = 28
		sb.shadow_offset = Vector2(0, 12)
		main_panel.add_theme_stylebox_override("panel", sb)

	var detail_panel := get_node_or_null("Overlay/ModalCenter/DetailPanel") as PanelContainer
	if detail_panel:
		var detail_sb := StyleBoxFlat.new()
		detail_sb.bg_color = Color(1.0, 0.995, 0.985, 0.985)
		detail_sb.border_width_left = 1
		detail_sb.border_width_top = 1
		detail_sb.border_width_right = 1
		detail_sb.border_width_bottom = 1
		detail_sb.border_color = Color(0.94, 0.83, 0.76, 0.7)
		detail_sb.set_corner_radius_all(30)
		detail_sb.shadow_color = Color(0.22, 0.16, 0.12, 0.14)
		detail_sb.shadow_size = 30
		detail_sb.shadow_offset = Vector2(0, 12)
		detail_panel.add_theme_stylebox_override("panel", detail_sb)

	var detail_body_card := get_node_or_null("Overlay/ModalCenter/DetailPanel/DetailMargin/DetailVBox/DetailBodyCard") as PanelContainer
	if detail_body_card:
		var body_sb := StyleBoxFlat.new()
		body_sb.bg_color = Color(1.0, 0.985, 0.975, 0.94)
		body_sb.border_width_left = 1
		body_sb.border_width_top = 1
		body_sb.border_width_right = 1
		body_sb.border_width_bottom = 1
		body_sb.border_color = Color(0.95, 0.86, 0.80, 0.75)
		body_sb.set_corner_radius_all(24)
		body_sb.content_margin_left = 4.0
		body_sb.content_margin_top = 4.0
		body_sb.content_margin_right = 4.0
		body_sb.content_margin_bottom = 4.0
		detail_body_card.add_theme_stylebox_override("panel", body_sb)

	var detail_example_card := get_node_or_null("Overlay/ModalCenter/DetailPanel/DetailMargin/DetailVBox/DetailExampleCard") as PanelContainer
	if detail_example_card:
		var example_sb := StyleBoxFlat.new()
		example_sb.bg_color = Color(1.0, 0.95, 0.93, 0.88)
		example_sb.border_width_left = 1
		example_sb.border_width_top = 1
		example_sb.border_width_right = 1
		example_sb.border_width_bottom = 1
		example_sb.border_color = Color(0.92, 0.76, 0.72, 0.78)
		example_sb.set_corner_radius_all(22)
		detail_example_card.add_theme_stylebox_override("panel", example_sb)

	title_label.text = "☁ 心理知识卡片"
	subtitle_label.text = "翻开三张小卡片，温柔地认识自己的想法与情绪。"
	title_label.add_theme_color_override("font_color", Color(0.38, 0.28, 0.24))
	title_label.add_theme_font_size_override("font_size", 40)
	subtitle_label.add_theme_color_override("font_color", Color(0.54, 0.44, 0.40))
	subtitle_label.add_theme_font_size_override("font_size", 20)
	detail_title_label.add_theme_color_override("font_color", Color(0.38, 0.28, 0.24))
	detail_title_label.add_theme_font_size_override("font_size", 30)
	detail_meta_label.add_theme_color_override("font_color", Color(0.74, 0.58, 0.52))
	detail_body_label.add_theme_color_override("font_color", Color(0.44, 0.35, 0.31))
	detail_body_label.add_theme_font_size_override("font_size", 21)
	detail_body_label.add_theme_constant_override("line_spacing", 8)
	detail_example_label.add_theme_color_override("font_color", Color(0.55, 0.40, 0.34))
	detail_example_label.add_theme_font_size_override("font_size", 17)

	_style_btn(btn_match_game, Color(0.82, 0.74, 0.94), false)
	_style_btn(btn_refresh, Color(0.90, 0.82, 0.74), false)
	_style_btn(btn_start, Color(0.52, 0.70, 0.60), true)
	_style_btn(btn_menu, Color(0.96, 0.72, 0.58), false)
	_style_btn(btn_close_detail, Color(0.52, 0.70, 0.60), true)

func _style_btn(btn: Button, accent: Color, primary: bool) -> void:
	btn.custom_minimum_size = Vector2(180, 52)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.96)
	sb.border_width_bottom = 4
	sb.border_color = Color(accent.r * 0.78, accent.g * 0.78, accent.b * 0.78, 0.95)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 24.0
	sb.content_margin_right = 24.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 12.0
	btn.add_theme_stylebox_override("normal", sb)

	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = sb.bg_color.lightened(0.06)
	sb_h.shadow_color = Color(accent.r, accent.g, accent.b, 0.10)
	sb_h.shadow_size = 8
	btn.add_theme_stylebox_override("hover", sb_h)

	var sb_p := sb.duplicate() as StyleBoxFlat
	sb_p.bg_color = sb.bg_color.darkened(0.06)
	sb_p.content_margin_top = 14.0
	sb_p.content_margin_bottom = 10.0
	btn.add_theme_stylebox_override("pressed", sb_p)

	btn.add_theme_font_size_override("font_size", 19 if primary else 18)
	btn.add_theme_color_override("font_color", Color.WHITE if primary else Color(0.34, 0.26, 0.22))

func _update_mode_copy() -> void:
	var scenario := GameManager.current_scenario
	if GameManager.knowledge_return_mode == GameManager.GameMode.CARD:
		title_label.text = "☁ CBT 卡牌预备"
		subtitle_label.text = "先翻开三张心理知识卡，再进入【%s】主题下的 CBT 卡牌训练。" % scenario
		btn_start.text = "开始卡牌训练 ▶"
	else:
		title_label.text = "☁ 心理知识卡片"
		subtitle_label.text = "翻开三张小卡片，温柔地认识自己的想法与情绪，然后进入【%s】迷宫训练。" % scenario
		btn_start.text = "开始迷宫训练 ▶"

func _refresh_cards() -> void:
	_current_cards = ScenarioDatabase.get_random_flashcards(CARD_COUNT, _previous_card_ids)
	_previous_card_ids = _card_ids(_current_cards)
	for child in cards_row.get_children():
		child.queue_free()
	for card_data in _current_cards:
		cards_row.add_child(_build_card(card_data))

func _build_card(card_data: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD_MIN_SIZE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.scale = Vector2.ONE

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 0.995, 0.985, 0.96)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.93, 0.82, 0.76, 0.92)
	panel_style.set_corner_radius_all(24)
	panel_style.shadow_color = Color(0.34, 0.22, 0.18, 0.07)
	panel_style.shadow_size = 14
	panel_style.shadow_offset = Vector2(0, 8)
	panel.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var scenario_label := Label.new()
	var layer := str(card_data.get("layer", "心理知识卡片"))
	var scenario := str(card_data.get("scenario", "通用"))
	scenario_label.text = "✿ %s · %s" % [layer, scenario]
	scenario_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scenario_label.add_theme_font_size_override("font_size", 14)
	scenario_label.add_theme_color_override("font_color", Color(0.80, 0.58, 0.52))
	scenario_label.add_theme_constant_override("outline_size", 1)
	vbox.add_child(scenario_label)

	var title := Label.new()
	title.text = str(card_data.get("title", ""))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color(0.34, 0.24, 0.22))
	vbox.add_child(title)

	var summary := Label.new()
	summary.text = str(card_data.get("summary", ""))
	summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 19)
	summary.add_theme_color_override("font_color", Color(0.50, 0.40, 0.38))
	vbox.add_child(summary)

	var tags := card_data.get("tags", []) as Array
	var footer := Label.new()
	footer.text = "点一点，看看这张小卡片想轻轻告诉你什么" if tags.is_empty() else "♡ " + " · ".join(_stringify_array(tags))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color(0.86, 0.62, 0.48))
	vbox.add_child(footer)

	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.anchor_right = 1.0
	button.anchor_bottom = 1.0
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func(): _open_detail(card_data))
	button.mouse_entered.connect(func(): _animate_card_hover(panel, true))
	button.mouse_exited.connect(func(): _animate_card_hover(panel, false))
	panel.add_child(button)

	return panel

func _animate_card_hover(panel: Control, hovered: bool) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(panel, "scale", Vector2(1.02, 1.02) if hovered else Vector2.ONE, 0.14)

func _open_detail(card_data: Dictionary) -> void:
	detail_title_label.text = str(card_data.get("title", ""))
	var meta_parts: Array[String] = []
	var layer := str(card_data.get("layer", ""))
	if not layer.is_empty():
		meta_parts.append("✿ " + layer)
	var scenario := str(card_data.get("scenario", ""))
	if not scenario.is_empty():
		meta_parts.append(scenario)
	var tags := card_data.get("tags", []) as Array
	if not tags.is_empty():
		meta_parts.append(" · ".join(_stringify_array(tags)))
	var distortion := str(card_data.get("distortion", ""))
	if not distortion.is_empty():
		meta_parts.append("认知扭曲：%s" % distortion)
	detail_meta_label.text = "  |  ".join(meta_parts)
	detail_body_label.text = "　　" + str(card_data.get("detail", ""))
	var example_text := str(card_data.get("example_text", ""))
	detail_example_label.visible = not example_text.is_empty()
	detail_example_label.get_parent().get_parent().visible = detail_example_label.visible
	detail_example_label.text = "🌷 小例子：%s" % example_text
	if detail_example_label.visible:
		detail_example_label.add_theme_constant_override("line_spacing", 6)
	overlay.visible = true

func _close_detail() -> void:
	overlay.visible = false

func _stringify_array(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	return result

func _card_ids(cards: Array[Dictionary]) -> Array[String]:
	var ids: Array[String] = []
	for card in cards:
		ids.append(str(card.get("id", "")))
	ids.sort()
	return ids

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_detail()
		get_viewport().set_input_as_handled()

func _start_selected_mode() -> void:
	if GameManager.knowledge_return_mode == GameManager.GameMode.CARD:
		GameManager.start_card_game(GameManager.current_scenario)
	else:
		GameManager.start_game(GameManager.current_scenario)
