## CardGameController — guided CBT seven-step card battle.
extends Node2D

const CogData = preload("res://data/cog_card_data.gd")

const MAX_HEALTH: int = 100
const MAX_STRESS: int = 100
const START_INSIGHT: int = 3

# --- Healing Aesthetic Palette ---
const COLOR_WARM_BG := Color(0.988, 0.961, 0.922)
const COLOR_MORANDI_GREEN := Color(0.4, 0.6, 0.58)
const COLOR_CLAY_ORANGE := Color(0.85, 0.55, 0.4)
const COLOR_TEXT_PRIMARY := Color(0.25, 0.22, 0.2)
const COLOR_TEXT_SECONDARY := Color(0.45, 0.4, 0.35)
const COLOR_PANEL_BG := Color(1.0, 1.0, 1.0, 0.92)
const COLOR_PANEL_BORDER := Color(0.9, 0.88, 0.85, 0.4)
const FILL_HEALTH := Color(0.4, 0.6, 0.58)
const FILL_STRESS := Color(0.85, 0.55, 0.4)
const CORNER_RADIUS := 24

var _scenario: String = "学业压力"
var _encounters: Array[Dictionary] = []
var _encounter_index: int = 0
var _current_encounter: Dictionary = {}
var _current_step: int = CogData.Step.SITUATION
var _game_active: bool = false

var _health: int = MAX_HEALTH
var _stress: int = 32
var _insight: int = START_INSIGHT
var _progress_score: int = 0
var _current_emotion_label: String = ""
var _current_emotion_intensity: int = 0
var _rerated_emotion_intensity: int = 0

var _selected_thought: Dictionary = {}
var _selected_emotion: Dictionary = {}
var _selected_distortion: Dictionary = {}
var _selected_evidence: Array[Dictionary] = []
var _selected_skill: Dictionary = {}
var _selected_balanced_thought: Dictionary = {}

var _bg_sprite: Sprite2D
var _hud_layer: CanvasLayer
var _background_layer: CanvasLayer
var _health_bar: ProgressBar
var _stress_bar: ProgressBar
var _insight_label: Label
var _scenario_label: Label
var _encounter_label: Label
var _step_label: Label
var _feedback_label: Label
var _main_layout: HBoxContainer
var _left_column: VBoxContainer
var _center_column: VBoxContainer
var _right_column: VBoxContainer
var _situation_panel: PanelContainer
var _guidance_panel: PanelContainer
var _options_panel: PanelContainer
var _summary_panel: PanelContainer
var _summary_label: RichTextLabel
var _situation_title: Label
var _situation_body: RichTextLabel
var _guidance_title: Label
var _guidance_body: RichTextLabel
var _options_title: Label
var _options_scroll: ScrollContainer
var _options_list: VBoxContainer
var _continue_button: Button
var _menu_button: Button
var _gemini_service: Node
var _hd_font: Font
var _hd_font_bold: Font

func _ready() -> void:
	_scenario = GameManager.current_scenario
	_encounters = CogData.get_encounters_for_scenario(_scenario)
	_setup_fonts()
	_build_scene()
	_connect_gemini()
	_start_game()

func _setup_fonts() -> void:
	var font_names = PackedStringArray([
		"Source Han Sans SC", "Noto Sans CJK SC", "Microsoft YaHei", "Yu Gothic", "Segoe UI", "Sans-Serif"
	])
	_hd_font = SystemFont.new()
	_hd_font.font_names = font_names
	_hd_font_bold = SystemFont.new()
	_hd_font_bold.font_names = font_names
	_hd_font_bold.font_weight = 700

func _build_scene() -> void:
	_background_layer = CanvasLayer.new()
	_background_layer.layer = -2
	add_child(_background_layer)

	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = COLOR_WARM_BG
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background_layer.add_child(backdrop)

	_bg_sprite = Sprite2D.new()
	_bg_sprite.name = "BackgroundSprite"
	_bg_sprite.modulate = Color(1.0, 1.0, 1.0, 0.08)
	add_child(_bg_sprite)

	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 3
	add_child(_hud_layer)

	var root_margin: MarginContainer = MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 48)
	root_margin.add_theme_constant_override("margin_right", 48)
	root_margin.add_theme_constant_override("margin_top", 32)
	root_margin.add_theme_constant_override("margin_bottom", 32)
	_hud_layer.add_child(root_margin)

	_main_layout = HBoxContainer.new()
	_main_layout.add_theme_constant_override("separation", 32)
	root_margin.add_child(_main_layout)

	_left_column = VBoxContainer.new()
	_left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_column.size_flags_stretch_ratio = 3.0
	_left_column.add_theme_constant_override("separation", 24)
	_main_layout.add_child(_left_column)

	_center_column = VBoxContainer.new()
	_center_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_center_column.size_flags_stretch_ratio = 4.0
	_center_column.add_theme_constant_override("separation", 20)
	_main_layout.add_child(_center_column)

	_right_column = VBoxContainer.new()
	_right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_column.size_flags_stretch_ratio = 3.0
	_right_column.add_theme_constant_override("separation", 24)
	_main_layout.add_child(_right_column)

	_build_left_column()
	_build_center_column()
	_build_right_column()

	var gemini_script: Script = load("res://services/gemini_service.gd") as Script
	if gemini_script:
		_gemini_service = gemini_script.new()
		_gemini_service.name = "GeminiService"
		add_child(_gemini_service)

func _build_left_column() -> void:
	var stats_card: PanelContainer = _make_panel(COLOR_PANEL_BG)
	_left_column.add_child(stats_card)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	stats_card.get_child(0).add_child(vbox)
	
	vbox.add_child(_make_label("身心状态", 22, COLOR_TEXT_PRIMARY, true))
	
	var h_box: VBoxContainer = VBoxContainer.new()
	vbox.add_child(h_box)
	h_box.add_child(_make_label("心理稳定度", 16, COLOR_TEXT_SECONDARY))
	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(0, 12)
	_health_bar.show_percentage = false
	_health_bar.max_value = MAX_HEALTH
	_apply_progress_theme(_health_bar, FILL_HEALTH)
	h_box.add_child(_health_bar)
	
	var s_box: VBoxContainer = VBoxContainer.new()
	vbox.add_child(s_box)
	s_box.add_child(_make_label("情绪温度", 16, COLOR_TEXT_SECONDARY))
	_stress_bar = ProgressBar.new()
	_stress_bar.custom_minimum_size = Vector2(0, 12)
	_stress_bar.show_percentage = false
	_stress_bar.max_value = MAX_STRESS
	_apply_progress_theme(_stress_bar, FILL_STRESS)
	s_box.add_child(_stress_bar)

	var info_card: PanelContainer = _make_panel(COLOR_PANEL_BG)
	_left_column.add_child(info_card)
	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_card.get_child(0).add_child(info_vbox)
	_scenario_label = _make_label("", 18, COLOR_MORANDI_GREEN, true)
	_scenario_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(_scenario_label)
	_encounter_label = _make_label("", 14, COLOR_TEXT_SECONDARY)
	_encounter_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(_encounter_label)

func _build_center_column() -> void:
	_situation_panel = _make_panel(COLOR_PANEL_BG)
	_center_column.add_child(_situation_panel)
	var sit_vbox: VBoxContainer = VBoxContainer.new()
	_situation_panel.get_child(0).add_child(sit_vbox)
	_situation_title = _make_label("当前情境", 20, COLOR_TEXT_PRIMARY, true)
	sit_vbox.add_child(_situation_title)
	_situation_body = RichTextLabel.new()
	_situation_body.bbcode_enabled = true
	_situation_body.fit_content = true
	_situation_body.add_theme_font_override("normal_font", _hd_font)
	_situation_body.add_theme_font_size_override("normal_font_size", 17)
	_situation_body.add_theme_color_override("default_color", COLOR_TEXT_SECONDARY)
	sit_vbox.add_child(_situation_body)

	_options_panel = _make_panel(COLOR_PANEL_BG)
	_options_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_center_column.add_child(_options_panel)
	var opt_vbox: VBoxContainer = VBoxContainer.new()
	opt_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_options_panel.get_child(0).add_child(opt_vbox)
	_options_title = _make_label("选择你的反应", 20, COLOR_TEXT_PRIMARY, true)
	opt_vbox.add_child(_options_title)
	
	_options_scroll = ScrollContainer.new()
	_options_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_options_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	opt_vbox.add_child(_options_scroll)
	_options_list = VBoxContainer.new()
	_options_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_options_list.add_theme_constant_override("separation", 12)
	_options_scroll.add_child(_options_list)

func _make_label(text: String, size: int, color: Color, bold: bool = false) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", _hd_font_bold if bold else _hd_font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _make_panel(bg: Color) -> PanelContainer:
	var pc: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(CORNER_RADIUS)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = COLOR_PANEL_BORDER
	pc.add_theme_stylebox_override("panel", sb)
	var mc: MarginContainer = MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 20)
	mc.add_theme_constant_override("margin_right", 20)
	mc.add_theme_constant_override("margin_top", 16)
	mc.add_theme_constant_override("margin_bottom", 16)
	pc.add_child(mc)
	return pc

func _make_btn(text: String, color: Color, filled: bool = true) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	b.add_theme_font_override("font", _hd_font_bold)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.set_corner_radius_all(CORNER_RADIUS)
	if filled:
		sb.bg_color = color
		b.add_theme_color_override("font_color", Color.WHITE)
	else:
		sb.bg_color = Color.TRANSPARENT
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = color
		b.add_theme_color_override("font_color", color)
	b.add_theme_stylebox_override("normal", sb)
	return b

func _apply_progress_theme(bar: ProgressBar, fill_color: Color) -> void:
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color(0.92, 0.89, 0.83, 0.96)
	bg.set_corner_radius_all(12)
	bar.add_theme_stylebox_override("background", bg)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(12)
	bar.add_theme_stylebox_override("fill", fill)

func _build_right_column() -> void:
	var step_card: PanelContainer = _make_panel(COLOR_MORANDI_GREEN)
	_right_column.add_child(step_card)
	var step_vbox: VBoxContainer = VBoxContainer.new()
	step_card.get_child(0).add_child(step_vbox)
	_step_label = _make_label("探索步骤", 22, Color.WHITE, true)
	step_vbox.add_child(_step_label)
	_insight_label = _make_label("顿悟点: 3", 16, Color(1, 1, 1, 0.8))
	step_vbox.add_child(_insight_label)

	_guidance_panel = _make_panel(COLOR_PANEL_BG)
	_right_column.add_child(_guidance_panel)
	var gui_vbox: VBoxContainer = VBoxContainer.new()
	_guidance_panel.get_child(0).add_child(gui_vbox)
	_guidance_title = _make_label("心智指引", 18, COLOR_CLAY_ORANGE, true)
	gui_vbox.add_child(_guidance_title)
	_guidance_body = RichTextLabel.new()
	_guidance_body.bbcode_enabled = true
	_guidance_body.fit_content = true
	_guidance_body.add_theme_font_override("normal_font", _hd_font)
	_guidance_body.add_theme_font_size_override("normal_font_size", 15)
	_guidance_body.add_theme_color_override("default_color", COLOR_TEXT_SECONDARY)
	gui_vbox.add_child(_guidance_body)

	_summary_panel = _make_panel(COLOR_PANEL_BG)
	_summary_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_column.add_child(_summary_panel)
	var sum_vbox: VBoxContainer = VBoxContainer.new()
	sum_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_summary_panel.get_child(0).add_child(sum_vbox)
	sum_vbox.add_child(_make_label("本轮记录", 18, COLOR_TEXT_PRIMARY, true))
	var sum_scroll: ScrollContainer = ScrollContainer.new()
	sum_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sum_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sum_vbox.add_child(sum_scroll)
	_summary_label = RichTextLabel.new()
	_summary_label.bbcode_enabled = true
	_summary_label.fit_content = true
	_summary_label.add_theme_font_override("normal_font", _hd_font)
	_summary_label.add_theme_font_size_override("normal_font_size", 14)
	_summary_label.add_theme_color_override("default_color", COLOR_TEXT_SECONDARY)
	sum_scroll.add_child(_summary_label)

	_feedback_label = _make_label("", 14, COLOR_MORANDI_GREEN)
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right_column.add_child(_feedback_label)

	var btn_vbox: VBoxContainer = VBoxContainer.new()
	btn_vbox.alignment = BoxContainer.ALIGNMENT_END
	_right_column.add_child(btn_vbox)

	_continue_button = _make_btn("下一步", COLOR_MORANDI_GREEN)
	if _continue_button:
		_continue_button.visible = false
		_continue_button.pressed.connect(_on_continue_pressed)
		btn_vbox.add_child(_continue_button)

	_menu_button = _make_btn("退出训练", COLOR_TEXT_SECONDARY, false)
	if _menu_button:
		_menu_button.pressed.connect(func(): GameManager.go_to_main_menu())
		btn_vbox.add_child(_menu_button)

func _connect_gemini() -> void:
	if _gemini_service == null:
		return
	if _gemini_service.has_signal("image_ready"):
		_gemini_service.image_ready.connect(_on_bg_ready)
	if _gemini_service.has_method("generate_background"):
		_gemini_service.generate_background(_scenario + " CBT 训练场景")

func _on_bg_ready(texture: Texture2D) -> void:
	_bg_sprite.texture = texture
	var vp: Vector2 = get_viewport_rect().size
	_bg_sprite.position = vp * 0.5
	var ts: Vector2 = texture.get_size()
	if ts.x > 0 and ts.y > 0:
		_bg_sprite.scale = Vector2(vp.x / ts.x, vp.y / ts.y)
	_bg_sprite.modulate = Color(1.0, 1.0, 1.0, 0.08)

func _start_game() -> void:
	_encounter_index = 0
	_game_active = true
	AmbientMusic.start(AmbientMusic.Track.CARD_GAME)
	_load_encounter(_encounter_index)

func _load_encounter(index: int) -> void:
	if index >= _encounters.size():
		_on_session_complete()
		return
	_current_encounter = _encounters[index]
	_reset_step_state()
	_current_step = CogData.Step.SITUATION
	_current_emotion_intensity = 0
	_rerated_emotion_intensity = 0
	_render_current_step()
	_update_hud()

func _reset_step_state() -> void:
	_selected_thought = {}
	_selected_emotion = {}
	_selected_distortion = {}
	_selected_evidence.clear()
	_selected_skill = {}
	_selected_balanced_thought = {}
	_current_emotion_label = ""

func _render_current_step() -> void:
	_situation_title.text = "%s｜%s" % [_scenario, _current_encounter.get("title", "")]
	_situation_body.text = "[center]%s[/center]" % _current_encounter.get("situation_text", "")
	_guidance_title.text = "当前步骤：%s" % CogData.step_name(_current_step)
	_guidance_body.text = "[center]%s[/center]" % _instruction_for_step(_current_step)
	_options_title.text = _options_title_for_step(_current_step)
	_feedback_label.text = _current_feedback_for_step()
	_continue_button.visible = _current_step == CogData.Step.SITUATION or _current_step == CogData.Step.RERATE
	_rebuild_options_for_step()
	_update_summary()
	_update_hud()

func _instruction_for_step(step: int) -> String:
	match step:
		CogData.Step.SITUATION:
			return "先读一读情境，看看这一轮发生了什么。"
		CogData.Step.AUTOMATIC_THOUGHT:
			return "从脑中最先冒出来的想法里，选一个最贴近当下的。"
		CogData.Step.EMOTION:
			return "给此刻的情绪命名，并看见它的强度。"
		CogData.Step.DISTORTION:
			return "观察这个想法里可能包含哪种认知偏差。"
		CogData.Step.EVIDENCE:
			return "同时看看支持证据和反证，让视角更完整。"
		CogData.Step.REFRAME:
			return "选一种技能，再找一个更平衡的替代想法。"
		CogData.Step.RERATE:
			return "回看情绪强度有没有变化，不需要一下子降到很低。"
	return ""

func _options_title_for_step(step: int) -> String:
	match step:
		CogData.Step.SITUATION:
			return "准备开始"
		CogData.Step.AUTOMATIC_THOUGHT:
			return "选择一个自动化想法"
		CogData.Step.EMOTION:
			return "选择当前情绪"
		CogData.Step.DISTORTION:
			return "选择最贴近的偏差卡"
		CogData.Step.EVIDENCE:
			return "选择两张最有帮助的证据卡"
		CogData.Step.REFRAME:
			return "先选技能，再选替代想法"
		CogData.Step.RERATE:
			return "选择新的情绪强度"
	return ""

func _current_feedback_for_step() -> String:
	var feedback: Dictionary = _current_encounter.get("feedback", {})
	match _current_step:
		CogData.Step.SITUATION:
			return feedback.get("situation", "")
		CogData.Step.AUTOMATIC_THOUGHT:
			return feedback.get("automatic_thought", "")
		CogData.Step.EMOTION:
			return feedback.get("emotion", "")
		CogData.Step.DISTORTION:
			return feedback.get("distortion", "")
		CogData.Step.EVIDENCE:
			return feedback.get("evidence", "")
		CogData.Step.REFRAME:
			return feedback.get("reframe", "")
		CogData.Step.RERATE:
			return feedback.get("rerate", "")
	return ""


func _rebuild_options_for_step() -> void:
	for child in _options_list.get_children():
		child.queue_free()

	match _current_step:
		CogData.Step.SITUATION:
			_add_info_card("这一轮会从情境开始，一步一步完成完整 CBT 流程。")
		CogData.Step.AUTOMATIC_THOUGHT:
			for item in _current_encounter.get("automatic_thoughts", []):
				_add_choice_button(item.get("text", ""), func(): _choose_thought(item), _selected_thought == item)
		CogData.Step.EMOTION:
			for item in _current_encounter.get("emotion_options", []):
				var label := "%s（%d）" % [item.get("label", ""), int(item.get("intensity", 0))]
				_add_choice_button(label, func(): _choose_emotion(item), _selected_emotion == item)
		CogData.Step.DISTORTION:
			for item in _current_encounter.get("distortion_options", []):
				var text := "%s｜%s" % [CogData.distortion_name(int(item.get("id", 0))), _distortion_desc(int(item.get("id", 0)))]
				_add_choice_button(text, func(): _choose_distortion(item), _selected_distortion == item)
		CogData.Step.EVIDENCE:
			for item in _current_encounter.get("evidence_cards", []):
				var badge := "支持证据"
				if item.get("kind", "") == "counter":
					badge = "反证"
				var selected: bool = _contains_dict(_selected_evidence, item)
				_add_choice_button("[%s] %s" % [badge, item.get("text", "")], func(): _toggle_evidence(item), selected)
		CogData.Step.REFRAME:
			_add_subtitle("先选择一个技能")
			for key in _current_encounter.get("skill_options", []):
				var skill: Dictionary = CogData.get_skill_cards().get(key, {})
				var skill_selected: bool = String(_selected_skill.get("key", "")) == String(key)
				_add_choice_button("%s｜%s" % [skill.get("display_name", ""), skill.get("description", "")], func(): _choose_skill(key), skill_selected)
			_add_subtitle("再选择一个替代想法")
			for item in _current_encounter.get("balanced_thought_options", []):
				_add_choice_button(item.get("text", ""), func(): _choose_balanced_thought(item), _selected_balanced_thought == item)
		CogData.Step.RERATE:
			for intensity in [max(_current_emotion_intensity - 40, 15), max(_current_emotion_intensity - 25, 20), max(_current_emotion_intensity - 10, 25), _current_emotion_intensity]:
				_add_choice_button("%s（%d）" % [_current_emotion_label, intensity], func(): _choose_rerate(intensity), _rerated_emotion_intensity == intensity)

func _add_info_card(text: String) -> void:
	var panel: PanelContainer = _make_panel(COLOR_PANEL_BG)
	_options_list.add_child(panel)
	var label: Label = _make_label(text, 16, COLOR_TEXT_SECONDARY)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.get_child(0).add_child(label)

func _add_subtitle(text: String) -> void:
	var label: Label = _make_label(text, 18, COLOR_TEXT_PRIMARY, true)
	_options_list.add_child(label)

func _add_choice_button(text: String, callback: Callable, selected: bool) -> void:
	var btn: Button = Button.new()
	btn.text = text
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.custom_minimum_size = Vector2(0, 86)
	btn.pressed.connect(callback)
	btn.add_theme_font_override("font", _hd_font)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.set_corner_radius_all(CORNER_RADIUS)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	if selected:
		sb.bg_color = Color(0.89, 0.95, 0.92, 0.98)
		sb.border_color = COLOR_MORANDI_GREEN
	else:
		sb.bg_color = Color(0.97, 0.95, 0.91, 0.98)
		sb.border_color = COLOR_PANEL_BORDER
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("focus", sb)
	_options_list.add_child(btn)

func _choose_thought(item: Dictionary) -> void:
	_selected_thought = item
	_feedback_label.text = "你识别到了一种可能的自动化想法。"
	_refresh_step_options()
	_advance_step()

func _choose_emotion(item: Dictionary) -> void:
	_selected_emotion = item
	_current_emotion_label = item.get("label", "")
	_current_emotion_intensity = int(item.get("intensity", 0))
	_stress = clampi(_stress + int(round(float(_current_emotion_intensity) * 0.20)), 0, MAX_STRESS)
	_feedback_label.text = "你已经为情绪找到了名称。"
	_refresh_step_options()
	_advance_step()

func _choose_distortion(item: Dictionary) -> void:
	_selected_distortion = item
	var fit: int = int(item.get("weight", 1))
	if fit >= 3:
		_feedback_label.text = "这个偏差角度和当前想法很贴近。"
	elif fit == 2:
		_feedback_label.text = "这个偏差角度也能帮助你继续观察。"
	else:
		_feedback_label.text = "这也是一个可以继续考虑的角度。"
	_refresh_step_options()
	_advance_step()

func _toggle_evidence(item: Dictionary) -> void:
	if _contains_dict(_selected_evidence, item):
		_remove_dict(_selected_evidence, item)
	else:
		if _selected_evidence.size() >= 2:
			_selected_evidence.pop_front()
		_selected_evidence.append(item)
	_feedback_label.text = "把支持证据和反证都摆出来，会更容易看到全貌。"
	_refresh_step_options()
	if _selected_evidence.size() >= 2:
		_advance_step()

func _choose_skill(key: String) -> void:
	var data: Dictionary = CogData.get_skill_cards().get(key, {}).duplicate(true)
	data["key"] = key
	_selected_skill = data
	_feedback_label.text = "你选择了一种应对方式。"
	_refresh_step_options()

func _choose_balanced_thought(item: Dictionary) -> void:
	_selected_balanced_thought = item
	if _selected_skill.is_empty():
		_feedback_label.text = "先选一个技能，会更容易形成替代想法。"
		_refresh_step_options()
		return
	_feedback_label.text = "这个替代想法让视角更平衡了一些。"
	_apply_reframe_effects()
	_refresh_step_options()
	_advance_step()

func _choose_rerate(intensity: int) -> void:
	_rerated_emotion_intensity = intensity
	_feedback_label.text = "你已经完成了这一轮情绪重评。"
	_refresh_step_options()

func _on_continue_pressed() -> void:
	if not _game_active:
		return
	if _current_step == CogData.Step.SITUATION:
		_advance_step()
		return
	if _current_step == CogData.Step.RERATE:
		_complete_encounter()

func _advance_step() -> void:
	_current_step += 1
	if _current_step > CogData.Step.RERATE:
		_current_step = CogData.Step.RERATE
	_render_current_step()

func _apply_reframe_effects() -> void:
	var skill_match: int = 1
	var targets: Array = _selected_skill.get("targets", [])
	if _selected_distortion.get("id", -1) in targets:
		skill_match = 3
	elif not targets.is_empty():
		skill_match = 2
	var evidence_weight: int = 0
	for item in _selected_evidence:
		var delta: int = int(item.get("weight", 1))
		if item.get("kind", "") == "counter":
			evidence_weight += delta + 1
		else:
			evidence_weight += delta
	var reduction: int = 8 + evidence_weight + skill_match * 4 - int(round(float(_stress) * 0.05))
	reduction = maxi(reduction, 8)
	var heal: int = 4 + int(_selected_balanced_thought.get("weight", 1)) * 2 + skill_match
	_health = clampi(_health + heal, 0, MAX_HEALTH)
	_stress = clampi(_stress - reduction, 0, MAX_STRESS)
	_insight = clampi(_insight + 1 - int(_selected_skill.get("insight_cost", 0)), 0, 9)
	_progress_score += 10 + evidence_weight + skill_match * 2

func _build_card_stats(completed: bool) -> Dictionary:
	return {
		"mode": GameManager.GameMode.CARD,
		"scenario": _scenario,
		"completed_encounters": _encounter_index,
		"total_encounters": _encounters.size(),
		"health": _health,
		"stress": _stress,
		"insight": _insight,
		"progress_score": _progress_score,
		"emotion_label": _current_emotion_label,
		"emotion_before": _current_emotion_intensity,
		"emotion_after": _rerated_emotion_intensity,
		"finished": completed,
	}

func _complete_encounter() -> void:
	var delta: int = _current_emotion_intensity - _rerated_emotion_intensity
	if delta >= 20:
		_feedback_label.text = "情绪已经出现明显松动了。"
		_health = clampi(_health + 6, 0, MAX_HEALTH)
		_progress_score += 12
	elif delta > 0:
		_feedback_label.text = "情绪有一点下降，这也是有价值的变化。"
		_health = clampi(_health + 3, 0, MAX_HEALTH)
		_progress_score += 8
	else:
		_feedback_label.text = "即使强度暂时没明显下降，你也已经完成了一轮练习。"
		_progress_score += 5
	_update_summary()
	_update_hud()
	await get_tree().create_timer(1.1).timeout
	_encounter_index += 1
	if _health <= 0:
		_on_soft_stop()
		return
	_load_encounter(_encounter_index)

func _on_soft_stop() -> void:
	_game_active = false
	AmbientMusic.stop()
	GameManager.update_high_score(_progress_score)
	GameManager.save_mode_stats(_build_card_stats(false))
	GameManager.go_to_game_over()

func _on_session_complete() -> void:
	_game_active = false
	AmbientMusic.stop()
	GameManager.update_high_score(_progress_score + _health)
	GameManager.save_mode_stats(_build_card_stats(true))
	_guidance_title.text = "本轮完成"
	_guidance_body.text = "[center]你已经完成了这个场景下的练习流程。[/center]"
	_feedback_label.text = "你已经走完这一组危机卡，并练习了完整的 CBT 七步流程。"
	for child in _options_list.get_children():
		child.queue_free()
	_add_info_card("你可以回顾自己的记录，也可以回到主菜单选择其他场景。")
	_continue_button.visible = false
	_update_summary()
	_update_hud()
	GameManager.go_to_win()

func _update_summary() -> void:
	var lines: PackedStringArray = []
	lines.append("[b]情境[/b]：%s" % _current_encounter.get("title", ""))
	if not _selected_thought.is_empty():
		lines.append("[b]想法[/b]：%s" % _selected_thought.get("text", ""))
	if not _selected_emotion.is_empty():
		lines.append("[b]情绪[/b]：%s（%d）" % [_selected_emotion.get("label", ""), int(_selected_emotion.get("intensity", 0))])
	if not _selected_distortion.is_empty():
		lines.append("[b]偏差[/b]：%s" % CogData.distortion_name(int(_selected_distortion.get("id", 0))))
	if not _selected_evidence.is_empty():
		var evidence_texts: PackedStringArray = []
		for item in _selected_evidence:
			evidence_texts.append(item.get("text", ""))
		lines.append("[b]证据[/b]：%s" % "；".join(evidence_texts))
	if not _selected_skill.is_empty():
		lines.append("[b]技能[/b]：%s" % _selected_skill.get("display_name", ""))
	if not _selected_balanced_thought.is_empty():
		lines.append("[b]替代想法[/b]：%s" % _selected_balanced_thought.get("text", ""))
	if _rerated_emotion_intensity > 0:
		lines.append("[b]重评[/b]：%s（%d → %d）" % [_current_emotion_label, _current_emotion_intensity, _rerated_emotion_intensity])
	_summary_label.text = "\n".join(lines)

func _update_hud() -> void:
	_health_bar.value = _health
	_stress_bar.value = _stress
	_scenario_label.text = "【%s】CBT 卡牌训练" % _scenario
	_encounter_label.text = "第 %d / %d 张危机卡" % [mini(_encounter_index + 1, _encounters.size()), _encounters.size()]
	_step_label.text = "步骤 %d / 7\n%s" % [_current_step + 1, CogData.step_name(_current_step)]
	_insight_label.text = "洞察值：%d\n练习进度：%d" % [_insight, _progress_score]

func _distortion_desc(id: int) -> String:
	for card in CogData.get_distortion_cards().values():
		if int(card.get("id", -1)) == id:
			return card.get("description", "")
	return ""

func _contains_dict(items: Array[Dictionary], target: Dictionary) -> bool:
	for item in items:
		if item == target:
			return true
	return false

func _remove_dict(items: Array[Dictionary], target: Dictionary) -> void:
	for i in items.size():
		if items[i] == target:
			items.remove_at(i)
			return

func _refresh_step_options() -> void:
	_rebuild_options_for_step()
	_update_summary()
	_update_hud()
