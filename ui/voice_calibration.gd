## VoiceCalibration — pre-game voice model training screen.
## If a model already exists the player can skip directly to game.
## Flow: COLLECTING (4 samples each word) → VERIFYING (3 correct each) → done.
extends Control

const VoiceServiceScript := preload("res://services/voice_service.gd")

var _voice_service: Node

# Layout nodes (built in _ready)
var _bg: ColorRect
var _panel: PanelContainer
var _title_label: Label
var _instruction_label: Label
var _word_label: Label
var _progress_label: Label
var _dots_container: HBoxContainer
var _status_label: Label
var _record_btn: Button
var _skip_btn: Button
var _action_btn: Button   # "重新校准" or "开始游戏" on has-model screen

var _timer_bar: ProgressBar
var _recording: bool = false
var _record_elapsed: float = 0.0
var _ui_verify_pass: int = 0
var _ui_verify_word: String = ""

func _ready() -> void:
	_build_ui()
	_voice_service = VoiceServiceScript.new()
	add_child(_voice_service)
	_voice_service.calibration_progress.connect(_on_calib_progress)
	_voice_service.calibration_verify.connect(_on_calib_verify)
	_voice_service.calibration_verify_result.connect(_on_calib_verify_result)
	_voice_service.calibration_done.connect(_on_calib_done)
	_voice_service.voice_failed.connect(_on_voice_failed)
	_voice_service.recording_started.connect(_on_recording_started)
	_voice_service.recording_stopped.connect(_on_recording_stopped)

	_start_incremental_calibration()

# ─────────────────────────────────────────────────────────────────────────────
#  UI Builder
# ─────────────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_bg = ColorRect.new()
	_bg.color = Color(0.98, 0.96, 0.92, 1.0)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(560, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 1.0, 0.8)
	sb.border_color = Color(0.9, 0.85, 0.8, 0.5)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(32)
	sb.shadow_color = Color(0.3, 0.2, 0.1, 0.06)
	sb.shadow_size = 25
	_panel.add_theme_stylebox_override("panel", sb)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	# Title
	_title_label = Label.new()
	_title_label.text = "🎤  语音校准"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(0.35, 0.3, 0.25))
	vbox.add_child(_title_label)

	# Instruction
	_instruction_label = Label.new()
	_instruction_label.text = ""
	_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_instruction_label.add_theme_font_size_override("font_size", 16)
	_instruction_label.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45))
	vbox.add_child(_instruction_label)

	# Big word display
	_word_label = Label.new()
	_word_label.text = ""
	_word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_word_label.add_theme_font_size_override("font_size", 64)
	_word_label.add_theme_color_override("font_color", Color(0.52, 0.64, 0.54)) # Sage Green
	vbox.add_child(_word_label)

	# Progress dots
	_dots_container = HBoxContainer.new()
	_dots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots_container.add_theme_constant_override("separation", 10)
	vbox.add_child(_dots_container)

	# Progress text
	_progress_label = Label.new()
	_progress_label.text = ""
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 16)
	_progress_label.add_theme_color_override("font_color", Color(0.65, 0.6, 0.55))
	vbox.add_child(_progress_label)

	# Status / feedback
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_status_label)

	# Record button
	_record_btn = _make_btn("🎤  点击录音 / 按空格", Color(0.92, 0.6, 0.45), 380, 52, 18)
	_record_btn.visible = false
	vbox.add_child(_record_btn)

	# Timer bar
	_timer_bar = ProgressBar.new()
	_timer_bar.custom_minimum_size = Vector2(380, 12)
	_timer_bar.max_value = 1.0
	_timer_bar.value = 0.0
	_timer_bar.show_percentage = false
	_timer_bar.visible = false
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.9, 0.85, 0.8)
	bar_bg.set_corner_radius_all(6)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.92, 0.6, 0.45) # Coral
	bar_fill.set_corner_radius_all(6)
	_timer_bar.add_theme_stylebox_override("background", bar_bg)
	_timer_bar.add_theme_stylebox_override("fill", bar_fill)
	vbox.add_child(_timer_bar)

	# action_btn
	_action_btn = _make_btn("", Color(0.52, 0.64, 0.54), 280, 46, 17)
	_action_btn.visible = false
	vbox.add_child(_action_btn)

	# Separator
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.85, 0.8, 0.75, 0.3)
	sep_style.content_margin_top = 1.0
	sep_style.content_margin_bottom = 1.0
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# Skip button
	_skip_btn = _make_btn("⏭  跳过，直接开始游戏", Color(0.85, 0.82, 0.78), 280, 40, 15)
	_skip_btn.pressed.connect(_on_skip)
	vbox.add_child(_skip_btn)

func _make_btn(label_text: String, accent: Color,
		min_w: int = 240, min_h: int = 44, font_sz: int = 17) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(min_w, min_h)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.9)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 18.0
	sb.content_margin_right = 18.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(accent.r * 1.05, accent.g * 1.05, accent.b * 1.05, 1.0)
	sb_h.shadow_size = 8
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_color_override("font_color", Color.WHITE if accent.v < 0.8 else Color(0.3, 0.25, 0.2))
	return btn

# ─────────────────────────────────────────────────────────────────────────────
#  Screens
# ─────────────────────────────────────────────────────────────────────────────

func _start_incremental_calibration() -> void:
	_action_btn.visible = true
	_action_btn.text = "🗑  重置模型重新录制"
	if not _action_btn.pressed.is_connected(_reset_and_recalibrate):
		_action_btn.pressed.connect(_reset_and_recalibrate)
	_dots_container.visible = true

	var hint: String = "（将在原有基础上继续训练）" if GameManager.has_voice_calibration() else ""
	_instruction_label.text = "点击按钮（或空格）开始录音，约 1.8 秒后自动完成" + hint
	_skip_btn.text = "Q / 跳过 — 直接进入游戏"
	_record_btn.visible = true
	if not _record_btn.pressed.is_connected(_on_record_pressed):
		_record_btn.pressed.connect(_on_record_pressed)
	_voice_service.start_calibration(false)  # incremental — keep existing templates

func _reset_and_recalibrate() -> void:
	_voice_service.reset_calibration()
	_instruction_label.text = "模型已清除，重新录制"
	_voice_service.start_calibration(true)  # full reset

# ─────────────────────────────────────────────────────────────────────────────
#  Calibration signal handlers
# ─────────────────────────────────────────────────────────────────────────────

func _on_calib_progress(word_cn: String, count: int, needed: int) -> void:
	_title_label.text = "🎤  收集样本"
	_word_label.text = word_cn
	_word_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
	_progress_label.text = "第 %d / %d 次" % [count, needed]
	_update_dots(count, needed, false)
	_status_label.text = ""
	_status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))

func _on_calib_verify(word_cn: String) -> void:
	# Reset counter when switching to a different word
	if word_cn != _ui_verify_word:
		_ui_verify_word = word_cn
		_ui_verify_pass = 0
	_title_label.text = "🔍  验证"
	_word_label.text = word_cn
	_word_label.add_theme_color_override("font_color", Color(0.3, 0.88, 1.0))
	var needed: int = _voice_service.VERIFY_PASSES
	_progress_label.text = "说出「%s」来验证 (需 %d 次通过)" % [word_cn, needed]
	_update_dots(_ui_verify_pass, needed, true)
	_status_label.text = ""

func _on_calib_verify_result(word_cn: String, passed: bool) -> void:
	if passed:
		_ui_verify_pass += 1
		var needed: int = _voice_service.VERIFY_PASSES
		_update_dots(_ui_verify_pass, needed, true)
		_status_label.text = "✅  正确！(%d / %d)" % [_ui_verify_pass, needed]
		_status_label.add_theme_color_override("font_color", Color(0.3, 0.95, 0.5))
	else:
		_ui_verify_pass = 0
		_status_label.text = "❌  再试一次"
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.42))
	_pop_status()

func _on_calib_done() -> void:
	_title_label.text = "✅  校准完成！"
	_instruction_label.text = "语音模型已保存，即将进入游戏…"
	_word_label.text = "🎉"
	_word_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_progress_label.text = ""
	_status_label.text = ""
	_record_btn.visible = false
	_skip_btn.visible = false
	_dots_container.visible = false
	await get_tree().create_timer(1.5).timeout
	_go_to_game()

func _on_voice_failed(reason: String) -> void:
	_status_label.text = "⚠  " + reason
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.25))
	_pop_status()

func _on_recording_started() -> void:
	_recording = true
	_record_elapsed = 0.0
	_record_btn.text = "🔴  录音中…"
	_record_btn.disabled = true
	_record_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_timer_bar.value = 0.0
	_timer_bar.visible = true

func _on_recording_stopped() -> void:
	_recording = false
	_record_btn.text = "🎤  点击录音 / 按空格"
	_record_btn.disabled = false
	_record_btn.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0))
	_timer_bar.value = 0.0
	_timer_bar.visible = false

# ─────────────────────────────────────────────────────────────────────────────
#  Input
# ─────────────────────────────────────────────────────────────────────────────

func _on_record_pressed() -> void:
	if _recording:
		return
	_voice_service.start_recording()

func _process(delta: float) -> void:
	if _recording:
		_record_elapsed += delta
		_timer_bar.value = _record_elapsed / _voice_service.RECORD_MAX

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_Q and event.pressed and not event.is_echo():
		_go_to_game()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.is_echo():
		_on_record_pressed()
		get_viewport().set_input_as_handled()

# ─────────────────────────────────────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────────────────────────────────────

func _update_dots(filled: int, total: int, verify_mode: bool) -> void:
	for child in _dots_container.get_children():
		child.queue_free()
	for i in total:
		var dot := Label.new()
		dot.add_theme_font_size_override("font_size", 28)
		if i < filled:
			dot.text = "●"
			dot.add_theme_color_override("font_color",
				Color(0.3, 0.92, 0.5) if verify_mode else Color(1.0, 0.82, 0.2))
		else:
			dot.text = "○"
			dot.add_theme_color_override("font_color", Color(0.45, 0.50, 0.62))
		_dots_container.add_child(dot)

func _pop_status() -> void:
	_status_label.scale = Vector2(0.8, 0.8)
	var tw := create_tween()
	tw.tween_property(_status_label, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_skip() -> void:
	_go_to_game()

func _go_to_game() -> void:
	get_tree().change_scene_to_file(GameManager.GAME_SCENE)
