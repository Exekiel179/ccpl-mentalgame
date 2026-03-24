## VoiceCalibration — Optimized professional psychological training space.
## Healing aesthetic: Warm Cream, Morandi Green, Clay Orange.
## Responsive layout, high-definition fonts (Semi-Bold), and 24px rounded corners.
extends Control

# --- Constants & Colors (Synced with Main Theme) ---
const COLOR_WARM_BG := Color(0.988, 0.961, 0.922)
const COLOR_MORANDI_GREEN := Color(0.4, 0.6, 0.58)
const COLOR_CLAY_ORANGE := Color(0.85, 0.55, 0.4)
const COLOR_TEXT_PRIMARY := Color(0.25, 0.22, 0.2)
const COLOR_TEXT_SECONDARY := Color(0.45, 0.4, 0.35)
const COLOR_PANEL_BG := Color(1.0, 1.0, 1.0, 0.92)
const COLOR_PANEL_BORDER := Color(0.9, 0.88, 0.85, 0.4)
const CORNER_RADIUS := 24

# --- Classes for Custom UI ---

class SampleWaveform:
	extends Control

	var _values: PackedFloat32Array = PackedFloat32Array()
	var _line_color: Color = Color(0.4, 0.6, 0.58)

	func _ready() -> void:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		custom_minimum_size = Vector2(0, 36)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_placeholder(1)

	func set_from_frames(frames: PackedVector2Array) -> void:
		var bars: PackedFloat32Array = PackedFloat32Array()
		var bucket_count: int = 24
		if frames.is_empty():
			_values = bars
			queue_redraw()
			return
		var step: int = max(1, int(ceil(float(frames.size()) / float(bucket_count))))
		var max_amp: float = 0.001
		for i in bucket_count:
			var start: int = i * step
			var finish: int = mini(frames.size(), start + step)
			var peak: float = 0.0
			for j in range(start, finish):
				var frame: Vector2 = frames[j]
				var amp: float = abs((frame.x + frame.y) * 0.5)
				if amp > peak:
					peak = amp
			max_amp = max(max_amp, peak)
			bars.append(peak)
		for i in bars.size():
			bars[i] = clamp(bars[i] / max_amp, 0.15, 1.0)
		_values = bars
		queue_redraw()

	func set_placeholder(seed: int) -> void:
		_set_placeholder(seed)
		queue_redraw()

	func set_line_color(color: Color) -> void:
		_line_color = color
		queue_redraw()

	func _set_placeholder(seed: int) -> void:
		var bars: PackedFloat32Array = PackedFloat32Array()
		for i in 24:
			var wave: float = 0.3 + 0.2 * sin(float(i + seed) * 0.5) + 0.1 * cos(float(i * 2 + seed) * 0.3)
			bars.append(clamp(wave, 0.15, 0.8))
		_values = bars

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var baseline := rect.size.y * 0.5
		var spacing := rect.size.x / float(max(1, _values.size()))
		for i in _values.size():
			var x := spacing * (i + 0.5)
			var amp := _values[i] * rect.size.y * 0.4
			draw_line(
				Vector2(x, baseline - amp),
				Vector2(x, baseline + amp),
				_line_color,
				3.0,
				true
			)

class DopamineIllustration:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(200, 160) # Reduced from 240
		size_flags_vertical = Control.SIZE_EXPAND_FILL

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var center := rect.size * 0.5
		
		var atom_color := Color(0.4, 0.6, 0.58, 0.3)
		var bond_color := Color(0.45, 0.4, 0.35, 0.2)

		draw_circle(center, min(rect.size.x, rect.size.y) * 0.3, Color(1, 1, 1, 0.4))

		var atoms = [
			center + Vector2(-40, -30), center + Vector2(0, -45),
			center + Vector2(40, -30), center + Vector2(40, 30),
			center + Vector2(0, 45), center + Vector2(-40, 30)
		]

		for i in range(atoms.size()):
			var a = atoms[i]
			var b = atoms[(i + 1) % atoms.size()]
			draw_line(a, b, bond_color, 2.0, true)
			draw_circle(a, 10.0, atom_color)
			draw_circle(a, 5.0, Color.WHITE)

		var accent := Color(0.85, 0.55, 0.4, 0.4)
		draw_circle(center + Vector2(60, -70), 6.0, accent)
		draw_circle(center + Vector2(-70, 60), 5.0, accent)

class VectorIcon:
	extends Control
	enum Type { MIC, PLAY, CHECK, WAVE }
	var type: Type = Type.MIC
	var color: Color = Color.WHITE

	func _ready() -> void:
		custom_minimum_size = Vector2(24, 24)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var center := rect.size * 0.5
		var s: float = min(rect.size.x, rect.size.y) * 0.8
		
		match type:
			Type.MIC:
				draw_rect(Rect2(center.x - s*0.2, center.y - s*0.4, s*0.4, s*0.6), color, true)
				draw_arc(center + Vector2(0, s*0.1), s*0.35, 0, PI, 16, color, 2.0, true)
				draw_line(center + Vector2(0, s*0.45), center + Vector2(0, s*0.55), color, 2.0, true)
			Type.PLAY:
				var pts = PackedVector2Array([
					center + Vector2(-s*0.25, -s*0.35),
					center + Vector2(s*0.35, 0),
					center + Vector2(-s*0.25, s*0.35)
				])
				draw_colored_polygon(pts, color)
			Type.CHECK:
				draw_line(center + Vector2(-s*0.3, 0), center + Vector2(-s*0.1, s*0.25), color, 3.0, true)
				draw_line(center + Vector2(-s*0.1, s*0.25), center + Vector2(s*0.4, -s*0.3), color, 3.0, true)
			Type.WAVE:
				for i in range(3):
					var x = -s*0.3 + i * s*0.3
					draw_line(center + Vector2(x, -s*0.2), center + Vector2(x, s*0.2), color, 2.0, true)

# --- Main Logic ---

const VoiceServiceScript := preload("res://services/voice_service.gd")

var _voice_service: Node
var _preview_player: AudioStreamPlayer
var _hd_font: Font
var _hd_font_bold: Font

# UI References
var _bg: ColorRect
var _bg_sprite: Sprite2D
var _title_label: Label
var _instruction_label: Label
var _word_label: Label
var _progress_label: Label
var _phase_badge: Label
var _status_label: Label
var _dots_container: HBoxContainer
var _timer_bar: ProgressBar
var _record_btn: Button
var _skip_btn: Button
var _action_btn: Button
var _orb_icon: VectorIcon
var _record_orb: PanelContainer
var _cards_container: VBoxContainer

var _sample_cards: Array[PanelContainer] = []
var _sample_word_labels: Array[Label] = []
var _sample_meta_labels: Array[Label] = []
var _sample_waveforms: Array[SampleWaveform] = []
var _sample_play_buttons: Array[Button] = []
var _sample_audio: Array = []

var _recording: bool = false
var _record_elapsed: float = 0.0
var _record_tween: Tween
var _ui_verify_pass: int = 0
var _ui_verify_word: String = ""
var _sample_entries: Array[Dictionary] = []

func _ready() -> void:
	_setup_fonts()
	_build_ui()
	_setup_background()
	
	_preview_player = AudioStreamPlayer.new()
	add_child(_preview_player)

	_voice_service = VoiceServiceScript.new()
	add_child(_voice_service)
	_voice_service.calibration_progress.connect(_on_calib_progress)
	_voice_service.calibration_verify.connect(_on_calib_verify)
	_voice_service.calibration_verify_result.connect(_on_calib_verify_result)
	_voice_service.calibration_done.connect(_on_calib_done)
	_voice_service.calibration_sample_collected.connect(_on_sample_collected)
	_voice_service.voice_failed.connect(_on_voice_failed)
	_voice_service.recording_started.connect(_on_recording_started)
	_voice_service.recording_stopped.connect(_on_recording_stopped)

	_reset_sample_library()
	_start_incremental_calibration()

func _setup_fonts() -> void:
	var font_names = PackedStringArray([
		"Source Han Sans SC", "Noto Sans CJK SC", "Microsoft YaHei", "Yu Gothic", "Segoe UI", "Sans-Serif"
	])
	
	# Regular Font
	_hd_font = SystemFont.new()
	_hd_font.font_names = font_names
	_hd_font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	_hd_font.hinting = TextServer.HINTING_LIGHT
	_hd_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_ONE_HALF
	_hd_font.generate_mipmaps = true
	
	# Bold Font (High Weight)
	_hd_font_bold = SystemFont.new()
	_hd_font_bold.font_names = font_names
	_hd_font_bold.font_weight = 700 # Bold
	_hd_font_bold.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	_hd_font_bold.hinting = TextServer.HINTING_LIGHT
	_hd_font_bold.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_ONE_HALF
	_hd_font_bold.generate_mipmaps = true

func _setup_background() -> void:
	var static_bg: Texture2D = preload("res://assets/ui/background_main.png")
	if static_bg:
		_bg_sprite.texture = static_bg
		_bg_sprite.position = get_viewport_rect().size / 2
		var s: Vector2 = get_viewport_rect().size / static_bg.get_size()
		_bg_sprite.scale = Vector2(max(s.x, s.y), max(s.x, s.y))
		_bg_sprite.modulate.a = 0.6 # Softer background for calibration

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Force size to viewport for initial setup
	size = get_viewport_rect().size
	
	_bg = ColorRect.new()
	_bg.color = COLOR_WARM_BG
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	_bg_sprite = Sprite2D.new()
	add_child(_bg_sprite)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 48)
	root_margin.add_theme_constant_override("margin_right", 48)
	root_margin.add_theme_constant_override("margin_top", 24) # Reduced from 40
	root_margin.add_theme_constant_override("margin_bottom", 24) # Reduced from 40
	add_child(root_margin)

	var layout := HBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 48)
	root_margin.add_child(layout)

	# 1. Left Decorative Panel (30% width)
	var left_outer := PanelContainer.new()
	left_outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_outer.size_flags_stretch_ratio = 3.0
	left_outer.add_theme_stylebox_override("panel", _make_panel_style(Color(1, 1, 1, 0.4)))
	layout.add_child(left_outer)
	
	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 24)
	left_margin.add_theme_constant_override("margin_right", 24)
	left_margin.add_theme_constant_override("margin_top", 24)
	left_margin.add_theme_constant_override("margin_bottom", 24)
	left_outer.add_child(left_margin)
	
	var left_panel := _build_left_panel()
	left_margin.add_child(left_panel)

	# 2. Center Task Panel (40% width)
	var center_panel := _build_center_panel()
	center_panel.size_flags_stretch_ratio = 4.0
	layout.add_child(center_panel)

	# 3. Right Library Panel (30% width)
	var right_outer := PanelContainer.new()
	right_outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_outer.size_flags_stretch_ratio = 3.0
	right_outer.add_theme_stylebox_override("panel", _make_panel_style(Color(1, 1, 1, 0.4)))
	layout.add_child(right_outer)

	var right_margin := MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 24)
	right_margin.add_theme_constant_override("margin_right", 24)
	right_margin.add_theme_constant_override("margin_top", 24)
	right_margin.add_theme_constant_override("margin_bottom", 24)
	right_outer.add_child(right_margin)

	var right_panel := _build_right_panel()
	right_margin.add_child(right_panel)

	# Overlay for particle effects
	var overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.name = "OverlayLayer"
	add_child(overlay)

func _build_left_panel() -> Control:
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 16)

	var header_vbox := VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 4)
	container.add_child(header_vbox)

	var eyebrow := _make_label("专业心理训练空间", 14, COLOR_MORANDI_GREEN, true)
	header_vbox.add_child(eyebrow)

	var title := _make_label("语音矫正与声线校准", 28, COLOR_TEXT_PRIMARY, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_vbox.add_child(title)

	var desc := _make_label("通过建立稳定的声线模板，帮助你在高压社交场景下保持自然的呼吸与语速。", 16, COLOR_TEXT_SECONDARY)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(desc)

	var illustration := DopamineIllustration.new()
	container.add_child(illustration)
	
	# Tip relocated here to save space in center
	var tip_card := PanelContainer.new()
	tip_card.add_theme_stylebox_override("panel", _make_panel_style(COLOR_PANEL_BG, 16))
	container.add_child(tip_card)
	
	var tip_margin := MarginContainer.new()
	tip_margin.add_theme_constant_override("margin_left", 16)
	tip_margin.add_theme_constant_override("margin_right", 16)
	tip_margin.add_theme_constant_override("margin_top", 12)
	tip_margin.add_theme_constant_override("margin_bottom", 12)
	tip_card.add_child(tip_margin)
	
	var tip_text := _make_label("💡 建议在安静环境下，用最放松的自然音量读出文字。", 14, COLOR_TEXT_SECONDARY)
	tip_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_margin.add_child(tip_text)

	return container

func _build_center_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(COLOR_PANEL_BG))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12) # Compact vertical flow
	margin.add_child(vbox)

	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 2)
	vbox.add_child(header_box)

	_phase_badge = _make_label("准备中", 14, COLOR_MORANDI_GREEN, true)
	_phase_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_box.add_child(_phase_badge)

	_title_label = _make_label("语音矫正舱", 32, COLOR_TEXT_PRIMARY, true) # Reduced
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_box.add_child(_title_label)

	_instruction_label = _make_label("初始化录制环境...", 16, COLOR_TEXT_SECONDARY)
	_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_instruction_label)

	# Responsive Recording Orb
	var orb_aspect := AspectRatioContainer.new()
	orb_aspect.ratio = 1.0
	orb_aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	orb_aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	orb_aspect.custom_minimum_size = Vector2(0, 120) # Reduced from 180
	vbox.add_child(orb_aspect)

	_record_orb = PanelContainer.new()
	_record_orb.add_theme_stylebox_override("panel", _make_orb_style())
	orb_aspect.add_child(_record_orb)

	var orb_center := CenterContainer.new()
	_record_orb.add_child(orb_center)
	_orb_icon = VectorIcon.new()
	_orb_icon.type = VectorIcon.Type.MIC
	_orb_icon.color = COLOR_TEXT_PRIMARY
	_orb_icon.custom_minimum_size = Vector2(48, 48)
	orb_center.add_child(_orb_icon)

	_word_label = _make_label("", 52, COLOR_CLAY_ORANGE, true) # Reduced from 64
	_word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_word_label)

	_dots_container = HBoxContainer.new()
	_dots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots_container.add_theme_constant_override("separation", 12)
	vbox.add_child(_dots_container)

	_progress_label = _make_label("", 16, COLOR_TEXT_SECONDARY, true)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_progress_label)

	_timer_bar = ProgressBar.new()
	_timer_bar.custom_minimum_size = Vector2(0, 8)
	_timer_bar.show_percentage = false
	_timer_bar.value = 0
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = COLOR_WARM_BG
	bar_bg.set_corner_radius_all(4)
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = COLOR_CLAY_ORANGE
	bar_fill.set_corner_radius_all(4)
	_timer_bar.add_theme_stylebox_override("background", bar_bg)
	_timer_bar.add_theme_stylebox_override("fill", bar_fill)
	vbox.add_child(_timer_bar)

	_status_label = _make_label("", 17, COLOR_MORANDI_GREEN, true)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status_label)
	
	# Compact inline status strip
	var status_bg := PanelContainer.new()
	var sb_style := _make_panel_style(Color(0.4, 0.6, 0.58, 0.05), 8)
	sb_style.set_border_width_all(0)
	status_bg.add_theme_stylebox_override("panel", sb_style)
	vbox.add_child(status_bg)
	
	var btn_box := HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 32)
	vbox.add_child(btn_box)

	_record_btn = _make_btn("开始录音", COLOR_MORANDI_GREEN)
	_record_btn.pressed.connect(_on_record_pressed)
	btn_box.add_child(_record_btn)

	_action_btn = _make_btn("重新校准", COLOR_TEXT_SECONDARY)
	_action_btn.pressed.connect(_reset_and_recalibrate)
	_action_btn.visible = false
	btn_box.add_child(_action_btn)

	_skip_btn = _make_btn("跳过 (Q)", COLOR_TEXT_SECONDARY, false) # Ghost style
	_skip_btn.pressed.connect(_on_skip)
	btn_box.add_child(_skip_btn)

	return panel

func _build_right_panel() -> Control:
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 16)

	var header := _make_label("声线采集库", 22, COLOR_TEXT_PRIMARY, true)
	container.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Custom scrollbar styling
	var v_scroll = scroll.get_v_scroll_bar()
	v_scroll.custom_minimum_size = Vector2(6, 0)
	var scroll_style = StyleBoxFlat.new()
	scroll_style.bg_color = COLOR_MORANDI_GREEN
	scroll_style.bg_color.a = 0.4
	scroll_style.set_corner_radius_all(3)
	v_scroll.add_theme_stylebox_override("grabber", scroll_style)
	v_scroll.add_theme_stylebox_override("grabber_highlight", scroll_style)
	v_scroll.add_theme_stylebox_override("grabber_pressed", scroll_style)
	container.add_child(scroll)

	_cards_container = VBoxContainer.new()
	_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_container.add_theme_constant_override("separation", 10)
	scroll.add_child(_cards_container)

	for i in 8:
		var card = _build_sample_card(i)
		_cards_container.add_child(card)
	
	# Safety bottom spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	_cards_container.add_child(spacer)

	return container

func _build_sample_card(index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_panel_style(Color(1, 1, 1, 0.45), 16))
	_sample_cards.append(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)

	var v_info := VBoxContainer.new()
	v_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(v_info)

	var word_label := _make_label("等待采集...", 16, COLOR_TEXT_PRIMARY, true)
	v_info.add_child(word_label)
	_sample_word_labels.append(word_label)

	var waveform := SampleWaveform.new()
	waveform.set_line_color(Color(0.8, 0.8, 0.8))
	v_info.add_child(waveform)
	_sample_waveforms.append(waveform)

	var meta_label := _make_label("Sample #%d" % (index + 1), 12, COLOR_TEXT_SECONDARY)
	v_info.add_child(meta_label)
	_sample_meta_labels.append(meta_label)

	var play_btn = _make_btn("试听", COLOR_MORANDI_GREEN, true, 12)
	play_btn.custom_minimum_size = Vector2(56, 28)
	play_btn.disabled = true
	play_btn.pressed.connect(_on_sample_play_pressed.bind(index))
	hbox.add_child(play_btn)
	_sample_play_buttons.append(play_btn)
	_sample_audio.append(null)

	return card

# --- UI Helpers ---

func _make_label(text: String, size: int, color: Color, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _hd_font_bold if bold else _hd_font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _make_btn(text: String, color: Color, filled: bool = true, font_size: int = 16) -> Button: # Reduced default from 18
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", _hd_font_bold)
	b.add_theme_font_size_override("font_size", font_size)
	b.custom_minimum_size = Vector2(140, 44) # Reduced from 160x48
	
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(CORNER_RADIUS)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	
	if filled:
		sb.bg_color = color
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
	else:
		sb.bg_color = Color.TRANSPARENT
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = color
		b.add_theme_color_override("font_color", color)
		b.add_theme_color_override("font_hover_color", color.lightened(0.2))

	b.add_theme_stylebox_override("normal", sb)
	var sb_h = sb.duplicate()
	sb_h.bg_color = color.lightened(0.1) if filled else Color(1, 1, 1, 0.1)
	b.add_theme_stylebox_override("hover", sb_h)
	var sb_p = sb.duplicate()
	sb_p.bg_color = color.darkened(0.1) if filled else Color(0, 0, 0, 0.1)
	b.add_theme_stylebox_override("pressed", sb_p)
	
	_register_interactive_feedback(b)
	return b

func _make_panel_style(bg: Color, radius: int = CORNER_RADIUS) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = COLOR_PANEL_BORDER
	sb.shadow_color = Color(0, 0, 0, 0.05)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 4)
	return sb

func _make_orb_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_PANEL_BG
	sb.border_width_left = 4
	sb.border_width_top = 4
	sb.border_width_right = 4
	sb.border_width_bottom = 4
	sb.border_color = Color.WHITE
	sb.corner_radius_top_left = 1000 # Circular
	sb.corner_radius_top_right = 1000
	sb.corner_radius_bottom_left = 1000
	sb.corner_radius_bottom_right = 1000
	sb.shadow_color = COLOR_MORANDI_GREEN
	sb.shadow_color.a = 0.2
	sb.shadow_size = 40
	return sb

func _register_interactive_feedback(control: Control) -> void:
	control.pivot_offset = control.size * 0.5
	control.mouse_entered.connect(func():
		create_tween().tween_property(control, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_SINE)
	)
	control.mouse_exited.connect(func():
		create_tween().tween_property(control, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_SINE)
	)
	control.resized.connect(func():
		control.pivot_offset = control.size * 0.5
	)

# --- Calibration Logic ---

func _start_incremental_calibration() -> void:
	_action_btn.visible = true
	var has_ready_model: bool = GameManager.has_voice_calibration()
	var hint := " (继续训练)" if has_ready_model else " (首次建模)"
	_phase_badge.text = "录制阶段"
	_instruction_label.text = "按下「开始录音」并读出下方文字。" + hint
	_status_label.text = "将先在本次训练会话中暂存样本，全部验证通过后再写入本地模型。"
	_record_btn.visible = true
	_voice_service.start_calibration(not has_ready_model)

func _reset_and_recalibrate() -> void:
	_voice_service.reset_calibration()
	_reset_sample_library()
	_instruction_label.text = "已清空本地模型。请按提示重新开始采集样本。"
	_status_label.text = "新的语音模型会在全部验证通过后一次性保存。"
	_voice_service.start_calibration(true)

func _on_calib_progress(word_cn: String, count: int, needed: int) -> void:
	_phase_badge.text = "样本采集中"
	_word_label.text = word_cn
	_progress_label.text = "进度: %d / %d" % [count, needed]
	_update_dots(count, needed, false)
	_status_label.text = "准备好后请读出「%s」" % word_cn

func _on_calib_verify(word_cn: String) -> void:
	if word_cn != _ui_verify_word:
		_ui_verify_word = word_cn
		_ui_verify_pass = 0
	_phase_badge.text = "稳定性验证"
	_word_label.text = word_cn
	_word_label.add_theme_color_override("font_color", COLOR_MORANDI_GREEN)
	_status_label.add_theme_color_override("font_color", COLOR_MORANDI_GREEN)
	var needed: int = _voice_service.VERIFY_PASSES
	_progress_label.text = "验证进度: %d / %d" % [_ui_verify_pass, needed]
	_update_dots(_ui_verify_pass, needed, true)
	_status_label.text = "请自然地说出「%s」" % word_cn

func _on_calib_verify_result(word_cn: String, passed: bool) -> void:
	var needed: int = _voice_service.VERIFY_PASSES
	if passed:
		_ui_verify_pass += 1
		_status_label.text = "验证通过！声线匹配度高。"
		_status_label.add_theme_color_override("font_color", COLOR_MORANDI_GREEN)
	else:
		_ui_verify_pass = 0
		_status_label.text = "识别有误，已将该录音加入训练集重新训练，请再说一次「%s」。" % word_cn
		_status_label.add_theme_color_override("font_color", COLOR_CLAY_ORANGE)
	_update_dots(_ui_verify_pass, needed, true)
	_progress_label.text = "验证进度: %d / %d" % [_ui_verify_pass, needed]

func _on_calib_done() -> void:
	_phase_badge.text = "校准完成"
	_word_label.text = "DONE"
	_status_label.text = "训练成功！正在为您开启游戏..."
	_record_btn.disabled = true
	await get_tree().create_timer(2.0).timeout
	_go_to_game()

func _on_sample_collected(word_cn: String, count: int, frames: PackedVector2Array) -> void:
	var slot := _sample_entries.size()
	if slot >= 8: return
	var stream := _build_wav_stream(frames)
	_sample_entries.append({"word": word_cn, "stream": stream})
	
	_sample_word_labels[slot].text = word_cn
	_sample_waveforms[slot].set_from_frames(frames)
	_sample_waveforms[slot].set_line_color(COLOR_MORANDI_GREEN)
	_sample_meta_labels[slot].text = "采集成功 · 样本 #%d" % (slot + 1)
	_sample_audio[slot] = stream
	_sample_play_buttons[slot].disabled = false
	
	_animate_sample_to_slot(slot)

func _on_recording_started() -> void:
	_recording = true
	_record_elapsed = 0.0
	_record_btn.text = "正在收音..."
	_record_btn.disabled = true
	_timer_bar.value = 0
	_orb_icon.color = COLOR_CLAY_ORANGE
	if _record_tween:
		_record_tween.kill()
	_record_tween = create_tween().set_loops()
	_record_tween.tween_property(_record_orb, "scale", Vector2(1.1, 1.1), 0.4).set_trans(Tween.TRANS_SINE)
	_record_tween.tween_property(_record_orb, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_SINE)

func _on_recording_stopped() -> void:
	_recording = false
	_record_btn.text = "开始录音"
	_record_btn.disabled = false
	_orb_icon.color = COLOR_TEXT_PRIMARY
	if _record_tween:
		_record_tween.kill()
		_record_tween = null
	_record_orb.scale = Vector2.ONE

func _on_record_pressed() -> void:
	if not _recording:
		_voice_service.start_recording()

func _process(delta: float) -> void:
	if _recording:
		_record_elapsed += delta
		_timer_bar.value = (_record_elapsed / _voice_service.RECORD_MAX) * 100.0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Space
		_on_record_pressed()
	elif event is InputEventKey and event.keycode == KEY_Q and event.pressed:
		_on_skip()

func _update_dots(filled: int, total: int, verify_mode: bool) -> void:
	for child in _dots_container.get_children():
		child.queue_free()
	for i in total:
		var dot := VectorIcon.new()
		dot.type = VectorIcon.Type.CHECK if (i < filled and verify_mode) else VectorIcon.Type.WAVE
		dot.color = (COLOR_MORANDI_GREEN if i < filled else COLOR_TEXT_SECONDARY)
		dot.custom_minimum_size = Vector2(20, 20)
		_dots_container.add_child(dot)

func _reset_sample_library() -> void:
	_sample_entries.clear()
	for i in 8:
		_sample_word_labels[i].text = "等待采集..."
		_sample_waveforms[i].set_placeholder(i)
		_sample_waveforms[i].set_line_color(Color(0.8, 0.8, 0.8))
		_sample_play_buttons[i].disabled = true

func _on_sample_play_pressed(slot: int) -> void:
	var stream = _sample_audio[slot]
	if stream:
		_preview_player.stream = stream
		_preview_player.play()

func _on_voice_failed(reason: String) -> void:
	_status_label.text = "录制失败: " + reason
	_status_label.add_theme_color_override("font_color", COLOR_CLAY_ORANGE)

func _on_skip() -> void:
	_go_to_game()

func _go_to_game() -> void:
	get_tree().change_scene_to_file(GameManager.GAME_SCENE)

func _build_wav_stream(frames: PackedVector2Array) -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	data.resize(frames.size() * 2)
	for i in frames.size():
		var mono: float = clamp((frames[i].x + frames[i].y) * 0.5, -1.0, 1.0)
		var pcm := int(round(mono * 32767.0))
		if pcm < 0: pcm += 65536
		data[i * 2] = pcm & 0xFF
		data[i * 2 + 1] = (pcm >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	return stream

func _animate_sample_to_slot(slot: int) -> void:
	var overlay = get_node_or_null("OverlayLayer")
	if not overlay: return
	
	var dot = VectorIcon.new()
	dot.type = VectorIcon.Type.WAVE
	dot.color = COLOR_CLAY_ORANGE
	dot.custom_minimum_size = Vector2(32, 32)
	overlay.add_child(dot)
	
	var from_pos = _record_orb.get_global_rect().get_center() - Vector2(16, 16)
	var to_pos = _sample_cards[slot].get_global_rect().get_center() - Vector2(16, 16)
	dot.global_position = from_pos
	
	var tw = create_tween().set_parallel(true)
	tw.tween_property(dot, "global_position", to_pos, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(dot, "scale", Vector2(0.2, 0.2), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.finished.connect(dot.queue_free)
