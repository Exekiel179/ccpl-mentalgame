## KnowledgeMatchScreen — title/detail matching mini-game before entering the main play mode.
extends Control

const MATCH_COUNT := 5
const TITLE_BUTTON_MIN_SIZE := Vector2(180, 52)

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var match_prompt_label: Label = %MatchPromptLabel
@onready var match_progress_label: Label = %MatchProgressLabel
@onready var titles_flow: HFlowContainer = %TitlesFlow
@onready var current_detail_panel: PanelContainer = %CurrentDetailPanel
@onready var current_detail_title: Label = %CurrentDetailTitle
@onready var current_detail_scroll: ScrollContainer = %CurrentDetailScroll
@onready var current_detail_label: Label = %CurrentDetailLabel
@onready var match_feedback_label: Label = %MatchFeedbackLabel
@onready var btn_refresh: Button = %BtnRefresh
@onready var btn_start: Button = %BtnStart
@onready var btn_menu: Button = %BtnMenu
@onready var overlay: Control = %Overlay
@onready var detail_title_label: Label = %DetailTitleLabel
@onready var detail_meta_label: Label = %DetailMetaLabel
@onready var detail_body_label: Label = %DetailBodyLabel
@onready var detail_example_label: Label = %DetailExampleLabel
@onready var btn_close_detail: Button = %BtnCloseDetail

var _matching_cards: Array[Dictionary] = []
var _previous_matching_ids: Array[String] = []
var _remaining_cards: Array[Dictionary] = []
var _current_target: Dictionary = {}
var _title_buttons: Dictionary = {}
var _correct_count: int = 0
var _game_finished: bool = false

func _ready() -> void:
	_style_scene()
	_update_mode_copy()
	btn_refresh.pressed.connect(_refresh_cards)
	btn_start.pressed.connect(_start_selected_mode)
	btn_menu.pressed.connect(func(): GameManager.go_to_knowledge())
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

	var current_detail_sb := StyleBoxFlat.new()
	current_detail_sb.bg_color = Color(1.0, 0.985, 0.975, 0.95)
	current_detail_sb.border_width_left = 1
	current_detail_sb.border_width_top = 1
	current_detail_sb.border_width_right = 1
	current_detail_sb.border_width_bottom = 1
	current_detail_sb.border_color = Color(0.95, 0.86, 0.80, 0.75)
	current_detail_sb.set_corner_radius_all(28)
	current_detail_sb.shadow_color = Color(0.33, 0.23, 0.18, 0.06)
	current_detail_sb.shadow_size = 16
	current_detail_sb.shadow_offset = Vector2(0, 8)
	current_detail_panel.add_theme_stylebox_override("panel", current_detail_sb)

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

	title_label.add_theme_color_override("font_color", Color(0.38, 0.28, 0.24))
	title_label.add_theme_font_size_override("font_size", 34)
	subtitle_label.add_theme_color_override("font_color", Color(0.54, 0.44, 0.40))
	subtitle_label.add_theme_font_size_override("font_size", 17)
	match_prompt_label.add_theme_font_size_override("font_size", 15)
	match_prompt_label.add_theme_color_override("font_color", Color(0.71, 0.54, 0.48))
	match_progress_label.add_theme_font_size_override("font_size", 14)
	match_progress_label.add_theme_color_override("font_color", Color(0.64, 0.50, 0.44))
	current_detail_title.add_theme_font_size_override("font_size", 16)
	current_detail_title.add_theme_color_override("font_color", Color(0.79, 0.59, 0.51))
	current_detail_label.add_theme_font_size_override("font_size", 20)
	current_detail_label.add_theme_color_override("font_color", Color(0.43, 0.34, 0.30))
	current_detail_label.add_theme_constant_override("line_spacing", 8)
	current_detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	match_feedback_label.add_theme_font_size_override("font_size", 15)
	match_feedback_label.add_theme_color_override("font_color", Color(0.86, 0.62, 0.48))
	detail_title_label.add_theme_color_override("font_color", Color(0.38, 0.28, 0.24))
	detail_title_label.add_theme_font_size_override("font_size", 30)
	detail_meta_label.add_theme_color_override("font_color", Color(0.74, 0.58, 0.52))
	detail_body_label.add_theme_color_override("font_color", Color(0.44, 0.35, 0.31))
	detail_body_label.add_theme_font_size_override("font_size", 21)
	detail_body_label.add_theme_constant_override("line_spacing", 8)
	detail_example_label.add_theme_color_override("font_color", Color(0.55, 0.40, 0.34))
	detail_example_label.add_theme_font_size_override("font_size", 17)

	_style_btn(btn_refresh, Color(0.90, 0.82, 0.74), false)
	_style_btn(btn_start, Color(0.52, 0.70, 0.60), true)
	_style_btn(btn_menu, Color(0.96, 0.72, 0.58), false)
	_style_btn(btn_close_detail, Color(0.52, 0.70, 0.60), true)

func _style_btn(btn: Button, accent: Color, primary: bool) -> void:
	btn.custom_minimum_size = Vector2(164, 46)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.96)
	sb.border_width_bottom = 4
	sb.border_color = Color(accent.r * 0.78, accent.g * 0.78, accent.b * 0.78, 0.95)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 18.0
	sb.content_margin_right = 18.0
	sb.content_margin_top = 9.0
	sb.content_margin_bottom = 9.0
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

	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", Color.WHITE if primary else Color(0.34, 0.26, 0.22))

func _make_title_style(accent: Color, fill_alpha: float = 0.96) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, fill_alpha)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 4
	sb.border_color = Color(accent.r * 0.80, accent.g * 0.80, accent.b * 0.80, 0.95)
	sb.set_corner_radius_all(20)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	return sb

func _style_title_button(btn: Button, state: String = "default") -> void:
	var normal_color := Color(0.98, 0.93, 0.88)
	var hover_color := Color(1.0, 0.96, 0.92)
	var pressed_color := Color(0.96, 0.88, 0.80)
	var font_color := Color(0.34, 0.26, 0.22)
	if state == "success":
		normal_color = Color(0.72, 0.88, 0.78)
		hover_color = normal_color
		pressed_color = normal_color
		font_color = Color(1, 1, 1)
	elif state == "error":
		normal_color = Color(0.97, 0.78, 0.74)
		hover_color = normal_color
		pressed_color = normal_color
		font_color = Color(0.48, 0.22, 0.18)
	elif state == "disabled":
		normal_color = Color(0.94, 0.90, 0.86)
		hover_color = normal_color
		pressed_color = normal_color
		font_color = Color(0.58, 0.49, 0.45)

	btn.add_theme_stylebox_override("normal", _make_title_style(normal_color))
	btn.add_theme_stylebox_override("hover", _make_title_style(hover_color))
	btn.add_theme_stylebox_override("pressed", _make_title_style(pressed_color))
	btn.add_theme_stylebox_override("disabled", _make_title_style(normal_color, 0.85))
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_hover_color", font_color)
	btn.add_theme_color_override("font_pressed_color", font_color)
	btn.add_theme_color_override("font_disabled_color", font_color)

func _update_mode_copy() -> void:
	var scenario := GameManager.current_scenario
	if GameManager.knowledge_return_mode == GameManager.GameMode.CARD:
		title_label.text = "☁ CBT 知识配对"
		subtitle_label.text = "试着把 5 个标题和解释连起来，再进入【%s】主题下的 CBT 卡牌训练。" % scenario
		btn_start.text = "开始卡牌训练 ▶"
	else:
		title_label.text = "☁ 心理知识配对"
		subtitle_label.text = "试着把 5 个标题和解释连起来，再进入【%s】迷宫训练。" % scenario
		btn_start.text = "开始迷宫训练 ▶"

func _refresh_cards() -> void:
	_matching_cards = ScenarioDatabase.get_matching_flashcards(MATCH_COUNT, _previous_matching_ids)
	_previous_matching_ids = _card_ids(_matching_cards)
	_start_matching_game()

func _start_matching_game() -> void:
	_title_buttons.clear()
	_correct_count = 0
	_game_finished = _matching_cards.is_empty()
	_remaining_cards = []
	for card in _matching_cards:
		_remaining_cards.append(card.duplicate(true))
	_remaining_cards.shuffle()
	_rebuild_title_buttons()
	if _game_finished:
		current_detail_label.text = "暂时没有可用的知识卡片。"
		match_progress_label.text = ""
		match_feedback_label.text = "换一组试试看。"
		return
	_load_next_target()

func _rebuild_title_buttons() -> void:
	for child in titles_flow.get_children():
		child.queue_free()
	_title_buttons.clear()

	var shuffled_cards: Array[Dictionary] = []
	for card in _matching_cards:
		shuffled_cards.append(card)
	shuffled_cards.shuffle()

	for card_data in shuffled_cards:
		var button := Button.new()
		var card_id := str(card_data.get("id", ""))
		button.text = str(card_data.get("title", ""))
		button.custom_minimum_size = TITLE_BUTTON_MIN_SIZE
		button.focus_mode = Control.FOCUS_ALL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_style_title_button(button)
		button.pressed.connect(func(): _on_title_selected(card_data))
		button.gui_input.connect(func(event: InputEvent): _on_title_button_input(event, card_data))
		titles_flow.add_child(button)
		_title_buttons[card_id] = button

func _load_next_target() -> void:
	if _remaining_cards.is_empty():
		_finish_matching_game()
		return
	_current_target = _remaining_cards.pop_front() as Dictionary
	var current_index := _correct_count + 1
	match_progress_label.text = "第 %d / %d 题" % [current_index, _matching_cards.size()]
	current_detail_title.text = "请找出这段解释对应的标题"
	current_detail_label.text = "　　" + str(_current_target.get("detail", ""))
	current_detail_scroll.scroll_vertical = 0
	match_feedback_label.text = "选一个你觉得最对应的标题吧。"

func _on_title_selected(card_data: Dictionary) -> void:
	if _game_finished:
		return
	var selected_id := str(card_data.get("id", ""))
	var target_id := str(_current_target.get("id", ""))
	if selected_id == target_id:
		_handle_correct_match(selected_id)
	else:
		_handle_wrong_match(selected_id, card_data)

func _handle_correct_match(card_id: String) -> void:
	_correct_count += 1
	var button := _title_buttons.get(card_id) as Button
	if button:
		button.disabled = true
		_style_title_button(button, "success")
	match_feedback_label.text = "答对啦，这张知识卡已经连好了。"
	await get_tree().create_timer(0.4).timeout
	if _correct_count >= _matching_cards.size():
		_finish_matching_game()
	else:
		_load_next_target()

func _handle_wrong_match(card_id: String, card_data: Dictionary) -> void:
	var button := _title_buttons.get(card_id) as Button
	if button:
		_style_title_button(button, "error")
		var reset_timer := get_tree().create_timer(0.4)
		reset_timer.timeout.connect(func():
			if is_instance_valid(button) and not button.disabled:
				_style_title_button(button)
		)
	match_feedback_label.text = "这张还不太对，再看看下面的解释提示。"
	_open_detail(card_data)

func _finish_matching_game() -> void:
	_game_finished = true
	_current_target.clear()
	current_detail_title.text = "配对完成"
	current_detail_label.text = "　　你已经把这 5 张知识卡都连上啦。可以点“换一组”继续玩，或者直接开始游戏。"
	current_detail_scroll.scroll_vertical = 0
	match_progress_label.text = "已完成 %d / %d 题" % [_correct_count, _matching_cards.size()]
	match_feedback_label.text = "做得很好，带着这份理解去继续闯关吧。"

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

func _on_title_button_input(event: InputEvent, card_data: Dictionary) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_open_detail(card_data)
		get_viewport().set_input_as_handled()

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
