## GameController — maze gameplay loop with level progression.
extends Node2D

const SENTENCE_CARD_SCENE := preload("res://game/sentence_card.tscn")
const MazeBuilder          := preload("res://game/maze_builder.gd")
const PickupScript         := preload("res://game/pickup.gd")

## Per-level tuning: [level1, level2, level3]
const TIME_LIMITS:  Array = [120.0, 90.0, 60.0]
const SPAWN_STARTS: Array = [4.0,   3.0,  2.0]
const SPAWN_MINS:   Array = [1.8,   1.4,  1.0]
const SPAWN_DECAYS: Array = [0.04,  0.05, 0.06]

@onready var health_component: HealthComponent = $HealthComponent
@onready var bg_sprite: Sprite2D               = $BackgroundSprite
@onready var spawn_timer: Timer                = $SpawnTimer
@onready var gemini_service: Node              = $GeminiService
@onready var cards_layer: Node                 = $CardsLayer
@onready var player: CharacterBody2D           = $Player
@onready var exit_zone: Area2D                 = $ExitZone
@onready var fog_layer: CanvasLayer            = $FogLayer

@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label     = %HealthLabel
@onready var score_label: Label      = %ScoreLabel
@onready var scenario_label: Label   = %ScenarioLabel
@onready var combo_label: Label      = %ComboLabel
@onready var countdown_label: Label  = %CountdownLabel

const PauseMenuScript := preload("res://ui/pause_menu.gd")
const VoiceServiceScript := preload("res://services/voice_service.gd")
var _pause_menu: CanvasLayer
var _voice_service: Node
var _mic_label: Label
var _voice_feedback: Label
var _hud_root: Control
var _health_card: PanelContainer
var _score_card: PanelContainer
var _completion_glow: ColorRect
var _completion_label: Label
var _score_growth: Control
var _hud_font: SystemFont
var _last_player_position: Vector2
var _maze_move_accum: float = 0.0
var _bottom_bar_backdrop: Panel

var _sentences: Array[Dictionary] = []
var _queue: Array[Dictionary] = []
var _score: int = 0
var _combo: int = 0
var _current_interval: float = 4.0
var _time_left: float = 120.0
var _game_active: bool = false
var _shield_active: bool = false
var _slow_active: bool = false
var _card_speed_multiplier: float = 1.0
var _slow_token: int = 0
var _total_cards: int = 0
var _correct_count: int = 0
var _wrong_count: int = 0
var _touched_count: int = 0
var _dodged_count: int = 0
var _best_combo: int = 0
var _wrong_sentences: Array[Dictionary] = []

func _ready() -> void:
	health_component.health_depleted.connect(_on_health_depleted)
	health_component.health_changed.connect(_on_health_changed)
	_style_hud()
	_build_hud_layout()

	_voice_service = VoiceServiceScript.new()
	add_child(_voice_service)
	_voice_service.voice_result.connect(_on_voice_result)
	_voice_service.voice_failed.connect(_on_voice_failed)
	_voice_service.recording_started.connect(_on_voice_recording_started)
	_voice_service.recording_stopped.connect(_on_voice_recording_stopped)

	var scenario := GameManager.current_scenario
	_sentences = ScenarioDatabase.get_sentences(scenario)
	_queue = _sentences.duplicate()
	_queue.shuffle()
	_setup_normal_level()
	_last_player_position = player.global_position
	_update_fog_reveal_position()
	if fog_layer and fog_layer.has_method("reset_exploration"):
		fog_layer.call("reset_exploration")
	if fog_layer and fog_layer.has_method("stamp_exploration"):
		fog_layer.call("stamp_exploration", player.global_position, 0.46, 88.0)
	if fog_layer and fog_layer.has_method("set_combo_visibility"):
		fog_layer.call("set_combo_visibility", 0)
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.enabled = true
		cam.make_current()

func _setup_normal_level() -> void:
	var exit_cs := exit_zone.get_node_or_null("ExitShape") as CollisionShape2D
	if exit_cs:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(60.0, 60.0)
		exit_cs.shape = rect
	exit_zone.position = MazeBuilder.get_exit_world()
	exit_zone.body_entered.connect(_on_exit_entered)

	var lvl: int = clampi(GameManager.current_level - 1, 0, 2)
	_time_left        = TIME_LIMITS[lvl]
	_current_interval = SPAWN_STARTS[lvl]
	var diff: int = GameManager.difficulty
	if diff == 0:
		_time_left *= 1.3
		_current_interval *= 1.3
		health_component.max_health = 130
		health_component.reset()
	elif diff == 2:
		_time_left *= 0.8
		_current_interval *= 0.7
		health_component.max_health = 80
		health_component.reset()

	var scenario := GameManager.current_scenario
	scenario_label.text = "第 %d 关\n%s" % [GameManager.current_level, scenario]
	combo_label.visible = false

	player.global_position = MazeBuilder.get_start_world()
	_spawn_pickups()

	gemini_service.image_ready.connect(_on_bg_ready)
	gemini_service.image_failed.connect(_on_bg_failed)
	gemini_service.generate_background(scenario)

	spawn_timer.wait_time = _current_interval
	spawn_timer.timeout.connect(_spawn_card)
	spawn_timer.start()
	_game_active = true
	_pause_menu = PauseMenuScript.new()
	add_child(_pause_menu)
	AmbientMusic.start(AmbientMusic.Track.MAZE_GAME)

func _process(delta: float) -> void:
	if not _game_active:
		return
	_update_fog_reveal_position()
	_time_left -= delta
	countdown_label.text = "\u23f1 %d" % maxi(0, int(ceil(_time_left)))
	_track_maze_exploration()
	if _time_left <= 0.0:
		_on_time_up()
	_check_card_hits()
	_highlight_nearest_card()

func _check_card_hits() -> void:
	var player_pos := player.global_position
	for child in cards_layer.get_children():
		if child is SentenceCard and not child._answered:
			var card: SentenceCard = child as SentenceCard
			var card_center: Vector2 = card.position + card.size * 0.5
			if player_pos.distance_to(card_center) < 48.0:
				child.on_hit_player()
				_touched_count += 1
				if _shield_active:
					_shield_active = false
				else:
					health_component.take_damage(SentenceCard.DAMAGE_TOUCH)
					SfxManager.play_hit()
					_shake_camera(8.0, 0.3)
					_damage_flash()
				_combo = 0
				_update_combo()

func _spawn_card() -> void:
	if not _game_active:
		return
	if _queue.is_empty():
		_queue = _sentences.duplicate()
		_queue.shuffle()
	var data: Dictionary = _queue.pop_front()
	var card: SentenceCard = SENTENCE_CARD_SCENE.instantiate()
	cards_layer.add_child(card)
	card.setup_near_player(data, player.global_position)
	card.tracking_target = player
	# Difficulty speed modifier
	var diff: int = GameManager.difficulty
	if diff == 0:
		card._velocity *= 0.8
	elif diff == 2:
		card._velocity *= 1.2
	card._velocity *= _card_speed_multiplier
	card.answered.connect(_on_card_answered)
	card.timed_out.connect(_on_card_timed_out)

	var lvl: int = clampi(GameManager.current_level - 1, 0, 2)
	_current_interval = maxf(float(SPAWN_MINS[lvl]),
							 _current_interval - float(SPAWN_DECAYS[lvl]))
	spawn_timer.wait_time = _current_interval

func _on_exit_entered(body: Node2D) -> void:
	if body == player and _game_active:
		_on_win()

func _save_stats() -> void:
	GameManager.last_stats = {
		"total": _total_cards,
		"correct": _correct_count,
		"wrong": _wrong_count,
		"touched": _touched_count,
		"dodged": _dodged_count,
		"best_combo": _best_combo,
		"wrong_sentences": _wrong_sentences,
	}

func _on_win() -> void:
	_game_active = false
	spawn_timer.stop()
	AmbientMusic.stop()
	_score += int(_time_left) * 2
	GameManager.update_high_score(_score)
	_save_stats()
	_show_completion_feedback()
	if GameManager.current_level < 3:
		GameManager.current_level += 1
		await get_tree().create_timer(1.4).timeout
		GameManager.continue_game(GameManager.current_scenario)
	else:
		GameManager.current_level = 1
		await get_tree().create_timer(1.0).timeout
		GameManager.go_to_win()

func _on_time_up() -> void:
	_game_active = false
	spawn_timer.stop()
	AmbientMusic.stop()
	GameManager.update_high_score(_score)
	_save_stats()
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://ui/game_over.tscn")

func _on_card_answered(_card: SentenceCard, correct: bool) -> void:
	_total_cards += 1
	if correct:
		_correct_count += 1
		_combo += 1
		if _combo > _best_combo:
			_best_combo = _combo
		var bonus: int = 10 + (_combo - 1) * 5
		_score += bonus
		_update_score()
		_update_combo()
		SfxManager.play_correct()
		# Combo healing
		if _combo == 3:
			health_component.heal(5)
		elif _combo == 5:
			health_component.heal(10)
		elif _combo >= 7 and _combo % 2 == 1:
			health_component.heal(8)
	else:
		_wrong_count += 1
		_wrong_sentences.append(_card.sentence_dict)
		_combo = 0
		_update_combo()
		health_component.take_damage(SentenceCard.DAMAGE_WRONG)
		SfxManager.play_wrong()
		_shake_camera(6.0, 0.25)
		_damage_flash()

func _on_card_timed_out(_card: SentenceCard) -> void:
	_dodged_count += 1
	_combo = 0
	_update_combo()
	# Timeout = player dodged = no damage

func _on_health_changed(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current
	health_label.text = "心理健康  %d / %d" % [current, max_health]
	var ratio: float = float(current) / float(max_health)
	var stylebox := health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if stylebox:
		var low_health_color := Color(0.72, 0.60, 0.50)
		var high_health_color := Color(0.52, 0.64, 0.54)
		stylebox.bg_color = low_health_color.lerp(high_health_color, ratio)

func _update_score() -> void:
	score_label.text = "分数: %d" % _score
	var tween_target: Control = _score_card if _score_card != null else score_label
	_pop_tween(tween_target)
	_play_score_growth()

func _update_combo() -> void:
	if fog_layer and fog_layer.has_method("set_combo_visibility"):
		fog_layer.call("set_combo_visibility", _combo)
	if _combo >= 2:
		combo_label.visible = true
		combo_label.text = "\u8fde\u51fb x%d!" % _combo
		_pop_tween(combo_label)
	else:
		combo_label.visible = false

func _pop_tween(node: Control) -> void:
	var tween := create_tween()
	tween.tween_property(node, "scale", Vector2(1.25, 1.25), 0.08)
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.12)

func _play_score_growth() -> void:
	if _score_growth == null:
		return
	for child in _score_growth.get_children():
		child.queue_free()
	for i in 3:
		var blade := ColorRect.new()
		blade.color = Color(0.60, 0.74, 0.57, 0.0)
		blade.size = Vector2(8, 20 + i * 8)
		blade.position = Vector2(208 + i * 16, 96)
		blade.rotation = deg_to_rad(-16 + i * 14)
		_score_growth.add_child(blade)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(blade, "modulate:a", 0.85, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(blade, "position:y", blade.position.y - blade.size.y, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.chain().tween_interval(0.30)
		tw.tween_property(blade, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.finished.connect(blade.queue_free)

func _track_maze_exploration() -> void:
	var travel: float = player.global_position.distance_to(_last_player_position)
	_last_player_position = player.global_position
	_maze_move_accum += travel
	if _maze_move_accum >= 22.0:
		_maze_move_accum = 0.0
		if fog_layer and fog_layer.has_method("stamp_exploration"):
			fog_layer.call("stamp_exploration", player.global_position, 0.34, 72.0)
		if fog_layer and fog_layer.has_method("pulse_exploration"):
			fog_layer.call("pulse_exploration")

func _update_fog_reveal_position() -> void:
	if fog_layer == null or not fog_layer.has_method("set_reveal_screen_position"):
		return
	var canvas_transform := get_viewport().get_canvas_transform()
	var screen_pos := canvas_transform * player.global_position
	fog_layer.call("set_reveal_screen_position", screen_pos)

func _show_completion_feedback() -> void:
	if fog_layer and fog_layer.has_method("clear_all_shadows"):
		fog_layer.call("clear_all_shadows")
	if _completion_glow:
		var glow_tween := create_tween()
		glow_tween.tween_property(_completion_glow, "color:a", 0.58, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		glow_tween.tween_property(_completion_glow, "color:a", 0.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _completion_label:
		_completion_label.visible = true
		_completion_label.modulate.a = 0.0
		_completion_label.scale = Vector2(0.94, 0.94)
		var label_tween := create_tween()
		label_tween.set_parallel(true)
		label_tween.tween_property(_completion_label, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		label_tween.tween_property(_completion_label, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		label_tween.chain().tween_interval(0.55)
		label_tween.tween_property(_completion_label, "modulate:a", 0.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		label_tween.finished.connect(func() -> void:
			_completion_label.visible = false
		)

func _on_health_depleted() -> void:
	_game_active = false
	spawn_timer.stop()
	AmbientMusic.stop()
	GameManager.update_high_score(_score)
	_save_stats()
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://ui/game_over.tscn")

func _on_bg_ready(texture: Texture2D) -> void:
	bg_sprite.texture = texture
	var vp := get_viewport_rect().size
	bg_sprite.position = vp * 0.5
	var tex_size := texture.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		bg_sprite.scale = Vector2(vp.x / tex_size.x, vp.y / tex_size.y)

func _on_bg_failed(reason: String) -> void:
	push_warning("Background generation failed: " + reason)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SPACE:
		if event.pressed and not event.is_echo():
			_voice_service.start_recording()
			_update_mic_label()
		elif not event.pressed:
			_voice_service.stop_recording()
		get_viewport().set_input_as_handled()
		return
	if not _game_active:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_answer_nearest_card("fact")
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_answer_nearest_card("thought")
			get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _pause_menu:
			_pause_menu.toggle()

func _answer_nearest_card(category: String) -> void:
	var player_pos := player.global_position
	var nearest: SentenceCard = null
	var min_dist: float = 99999.0
	for child in cards_layer.get_children():
		if child is SentenceCard and not child._answered:
			var card: SentenceCard = child as SentenceCard
			var card_center: Vector2 = card.position + card.size * 0.5
			var dist: float = player_pos.distance_to(card_center)
			if dist < min_dist:
				min_dist = dist
				nearest = card
	if nearest != null:
		nearest.submit_answer(category)

func _style_hud() -> void:
	_hud_font = SystemFont.new()
	_hud_font.font_names = PackedStringArray(["Source Han Sans SC", "Noto Sans CJK SC", "Microsoft YaHei UI", "Microsoft YaHei"])

	for lbl in [health_label, score_label, scenario_label, countdown_label, combo_label]:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", _hud_font)

	health_label.add_theme_font_size_override("font_size", 20)
	health_label.add_theme_color_override("font_color", Color(0.31, 0.29, 0.25))
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color(0.31, 0.29, 0.25))
	scenario_label.add_theme_font_size_override("font_size", 18)
	scenario_label.add_theme_color_override("font_color", Color(0.42, 0.40, 0.36))
	countdown_label.add_theme_font_size_override("font_size", 18)
	countdown_label.add_theme_color_override("font_color", Color(0.76, 0.54, 0.40))
	combo_label.add_theme_font_size_override("font_size", 26)
	combo_label.add_theme_color_override("font_color", Color(0.48, 0.66, 0.78))

func _highlight_nearest_card() -> void:
	var player_pos := player.global_position
	var nearest: SentenceCard = null
	var min_dist: float = 99999.0
	for child in cards_layer.get_children():
		if child is SentenceCard and not child._answered:
			var card: SentenceCard = child as SentenceCard
			card.is_nearest = false
			var card_center: Vector2 = card.position + card.size * 0.5
			var dist: float = player_pos.distance_to(card_center)
			if dist < min_dist:
				min_dist = dist
				nearest = card
	if nearest != null:
		nearest.is_nearest = true

func _on_voice_result(category: String) -> void:
	_answer_nearest_card(category)

func _on_voice_failed(_reason: String) -> void:
	pass

func _update_mic_label() -> void:
	pass

func _build_hud_layout() -> void:
	var hud := get_node_or_null("HUD") as CanvasLayer
	if hud == null:
		return

	var top_bar := hud.get_node_or_null("TopBar") as Control
	if top_bar:
		top_bar.visible = false
	var answer_buttons := hud.get_node_or_null("AnswerButtons") as HBoxContainer
	if answer_buttons:
		answer_buttons.visible = false

	_hud_root = Control.new()
	_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(_hud_root)
	hud.move_child(_hud_root, 0)

	_health_card = _make_hud_card(Vector2(24, 18), Vector2(286, 132))
	_score_card = _make_hud_card(Vector2(970, 18), Vector2(286, 132))

	_hud_root.add_child(_health_card)
	_hud_root.add_child(_score_card)

	_arrange_health_card()
	_arrange_score_card()

	_completion_glow = ColorRect.new()
	_completion_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_completion_glow.color = Color(0.84, 0.54, 0.36, 0.0)
	_completion_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.add_child(_completion_glow)

	_completion_label = Label.new()
	_completion_label.set_anchors_preset(Control.PRESET_CENTER)
	_completion_label.offset_left = -260.0
	_completion_label.offset_top = -50.0
	_completion_label.offset_right = 260.0
	_completion_label.offset_bottom = 50.0
	_completion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_completion_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_completion_label.visible = false
	_completion_label.text = "完成了一次认知探索，你的心智更加平衡了！"
	_completion_label.add_theme_font_override("font", _hud_font)
	_completion_label.add_theme_font_size_override("font_size", 28)
	_completion_label.add_theme_color_override("font_color", Color(0.32, 0.22, 0.18))
	_completion_label.add_theme_color_override("font_outline_color", Color(1.0, 0.97, 0.92, 0.92))
	_completion_label.add_theme_constant_override("outline_size", 4)
	_hud_root.add_child(_completion_label)

func _make_hud_card(position: Vector2, card_size: Vector2, radius: int = 28) -> PanelContainer:
	var card := PanelContainer.new()
	card.position = position
	card.size = card_size
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.99, 0.97, 0.93, 0.95)
	style.border_color = Color(0.87, 0.81, 0.74, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.46, 0.39, 0.31, 0.14)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	card.add_theme_stylebox_override("panel", style)
	return card

func _arrange_health_card() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 18)
	_health_card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "心理健康"
	title.add_theme_font_override("font", _hud_font)
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color(0.32, 0.30, 0.26))
	vbox.add_child(title)

	_reparent_to(health_label, vbox)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	_reparent_to(health_bar, vbox)
	health_bar.custom_minimum_size = Vector2(0, 24)
	health_bar.max_value = health_component.max_health
	health_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.90, 0.89, 0.84, 0.95)
	bg.set_corner_radius_all(16)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.52, 0.64, 0.54)
	fill.set_corner_radius_all(16)
	health_bar.add_theme_stylebox_override("background", bg)
	health_bar.add_theme_stylebox_override("fill", fill)
	vbox.add_child(health_bar)

func _arrange_score_card() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_score_card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	_reparent_to(score_label, vbox)
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_reparent_to(scenario_label, vbox)
	scenario_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_reparent_to(countdown_label, vbox)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_score_growth = Control.new()
	_score_growth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_growth.set_anchors_preset(Control.PRESET_FULL_RECT)
	_score_card.add_child(_score_growth)

func _reparent_to(control: Control, new_parent: Node) -> void:
	var old_parent: Node = control.get_parent()
	if old_parent:
		old_parent.remove_child(control)
	new_parent.add_child(control)

func _on_voice_recording_started() -> void:
	AmbientMusic.stop()
	_update_mic_label()

func _on_voice_recording_stopped() -> void:
	_update_mic_label()
	if _game_active:
		AmbientMusic.start()

func _shake_camera(intensity: float, duration: float) -> void:
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	var tw := create_tween()
	var steps := 5
	var step_dur := duration / float(steps)
	for i in steps:
		var off := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(cam, "offset", off, step_dur)
	tw.tween_property(cam, "offset", Vector2.ZERO, step_dur)

func _damage_flash() -> void:
	pass  # removed — player.modulate tinted the viewport red via Camera2D child

func _spawn_pickups() -> void:
	var maze_node := get_node_or_null("Maze")
	if maze_node == null:
		return
	var positions: Array = maze_node.get_pickup_positions(5)
	var types: Array = [0, 0, 1, 2, 3]  # 2 HEAL, 1 SLOW, 1 TIME, 1 SHIELD
	types.shuffle()
	for i in mini(positions.size(), types.size()):
		var pickup := Area2D.new()
		pickup.set_script(PickupScript)
		add_child(pickup)
		pickup.setup(int(types[i]), positions[i] as Vector2)
		pickup.collected.connect(_on_pickup_collected)

func _on_pickup_collected(pickup_type: int) -> void:
	SfxManager.play_pickup()
	if pickup_type == 0:  # HEAL
		health_component.heal(15)
		SfxManager.play_heal()
	elif pickup_type == 1:  # SLOW
		_apply_slow_effect(0.5, 8.0)
	elif pickup_type == 2:  # TIME
		_time_left += 10.0
	elif pickup_type == 3:  # SHIELD
		_shield_active = true

func _apply_slow_effect(multiplier: float, duration: float) -> void:
	var was_active := _slow_active
	_slow_active = true
	_slow_token += 1
	var token := _slow_token
	if not was_active:
		_card_speed_multiplier = multiplier
		for child in cards_layer.get_children():
			if child is SentenceCard:
				child._velocity *= multiplier
	get_tree().create_timer(duration).timeout.connect(func():
		if token != _slow_token:
			return
		_slow_active = false
		if _card_speed_multiplier != 0.0:
			var restore_factor := 1.0 / _card_speed_multiplier
			for child in cards_layer.get_children():
				if child is SentenceCard:
					child._velocity *= restore_factor
		_card_speed_multiplier = 1.0
	)
