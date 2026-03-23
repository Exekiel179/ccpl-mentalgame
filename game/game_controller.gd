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

@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label     = %HealthLabel
@onready var score_label: Label      = %ScoreLabel
@onready var scenario_label: Label   = %ScenarioLabel
@onready var combo_label: Label      = %ComboLabel
@onready var countdown_label: Label  = %CountdownLabel
@onready var btn_fact: Button        = %BtnFact
@onready var btn_thought: Button     = %BtnThought

const PauseMenuScript := preload("res://ui/pause_menu.gd")
const VoiceServiceScript := preload("res://services/voice_service.gd")
var _pause_menu: CanvasLayer
var _voice_service: Node
var _mic_label: Label
var _voice_feedback: Label
var _top_bar_backdrop: Panel
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
	btn_fact.pressed.connect(func(): _answer_nearest_card("fact"))
	btn_thought.pressed.connect(func(): _answer_nearest_card("thought"))
	_style_hud()
	_style_hud_panels()

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

	_mic_label = Label.new()
	_mic_label.text = "[SPACE] 语音答题"
	_mic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mic_label.add_theme_font_size_override("font_size", 18)
	_mic_label.add_theme_color_override("font_color", Color(0.45, 0.4, 0.35)) # Muted Taupe
	_mic_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.5))
	_mic_label.add_theme_constant_override("outline_size", 2)
	_mic_label.position = Vector2(500, 678)
	_voice_feedback = Label.new()
	_voice_feedback.text = ""
	_voice_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_voice_feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_voice_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_voice_feedback.add_theme_font_size_override("font_size", 48)
	_voice_feedback.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15)) # Deep Warm Brown
	_voice_feedback.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.8))
	_voice_feedback.add_theme_constant_override("outline_size", 4)
	_voice_feedback.size = Vector2(400, 80)
	_voice_feedback.position = Vector2(440, 280)
	_voice_feedback.visible = false
	var hud_node := get_node_or_null("HUD")
	if hud_node:
		hud_node.add_child(_mic_label)
		hud_node.add_child(_voice_feedback)

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
	scenario_label.text = "\u7b2c%d\u5173 \u00b7 %s" % [GameManager.current_level, scenario]
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
	AmbientMusic.start(AmbientMusic.Track.PROCEDURAL)

func _process(delta: float) -> void:
	if not _game_active:
		return
	_time_left -= delta
	countdown_label.text = "\u23f1 %d" % maxi(0, int(ceil(_time_left)))
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
	if GameManager.current_level < 3:
		GameManager.current_level += 1
		await get_tree().create_timer(1.0).timeout
		GameManager.start_game(GameManager.current_scenario)
	else:
		GameManager.current_level = 1
		await get_tree().create_timer(0.5).timeout
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
	health_bar.value = current
	health_label.text = "🌿 身心能量: %d" % current
	var ratio := float(current) / float(max_health)
	var stylebox := health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if stylebox:
		# Soft green to Terra Cotta (0.8, 0.6, 0.5) transition
		var low_health_color := Color(0.8, 0.6, 0.5) # Terra Cotta
		var high_health_color := Color(0.52, 0.64, 0.54) # Sage Green
		stylebox.bg_color = low_health_color.lerp(high_health_color, ratio)

func _update_score() -> void:
	score_label.text = "✨ 积极成长: %d" % _score
	_pop_tween(score_label)

func _update_combo() -> void:
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
		return
	if not _game_active:
		return
	if event.is_action_pressed("answer_fact"):
		_answer_nearest_card("fact")
	elif event.is_action_pressed("answer_thought"):
		_answer_nearest_card("thought")

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
	# Style HUD labels
	for lbl in [health_label, score_label, scenario_label, countdown_label, combo_label]:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	health_label.add_theme_font_size_override("font_size", 16)
	health_label.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15)) # Deep Warm Brown
	score_label.add_theme_font_size_override("font_size", 16)
	score_label.add_theme_color_override("font_color", Color(0.45, 0.4, 0.35)) # Muted Taupe
	scenario_label.add_theme_font_size_override("font_size", 16)
	scenario_label.add_theme_color_override("font_color", Color(0.45, 0.4, 0.35)) # Muted Taupe
	countdown_label.add_theme_font_size_override("font_size", 18)
	countdown_label.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15))
	combo_label.add_theme_font_size_override("font_size", 22)
	combo_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.6)) # Gentle Coral Pink
	# Style answer buttons
	for btn in [btn_fact, btn_thought]:
		var b: Button = btn as Button
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1.0, 0.98, 0.95, 0.9) # Warm White
		sb.border_color = Color(0.85, 0.80, 0.75, 0.6)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(12)
		sb.content_margin_left = 20.0
		sb.content_margin_right = 20.0
		sb.content_margin_top = 8.0
		sb.content_margin_bottom = 8.0
		b.add_theme_stylebox_override("normal", sb)
		var sb_h := sb.duplicate() as StyleBoxFlat
		sb_h.bg_color = sb.bg_color.lightened(0.1) # Lightened hover
		sb_h.shadow_color = Color(0.4, 0.3, 0.2, 0.08) # Shadow alpha <= 0.1
		sb_h.shadow_size = 6
		b.add_theme_stylebox_override("hover", sb_h)
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15)) # Deep Warm Brown

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
	_show_voice_feedback(category)
	_update_mic_label()

func _on_voice_failed(reason: String) -> void:
	if _voice_feedback:
		_voice_feedback.visible = true
		_voice_feedback.text = "❌ " + reason
		_voice_feedback.add_theme_color_override("font_color", Color(0.75, 0.5, 0.5)) # Muted Rose
		_voice_feedback.scale = Vector2(1.0, 1.0)
		_voice_feedback.modulate = Color.WHITE
		var tw2 := create_tween()
		tw2.tween_interval(1.2)
		tw2.tween_property(_voice_feedback, "modulate:a", 0.0, 0.5)
		tw2.tween_callback(func(): _voice_feedback.visible = false)
	if _mic_label:
		_mic_label.text = reason
		_mic_label.modulate = Color(1.0, 0.5, 0.5)
		var tw := create_tween()
		tw.tween_property(_mic_label, "modulate:a", 0.0, 1.5)

func _update_mic_label() -> void:
	if _mic_label == null:
		return
	_mic_label.modulate = Color.WHITE
	if _voice_service.is_recording():
		_mic_label.text = "🎤 录音中... 说“事实”或“想法”"
		_mic_label.add_theme_color_override("font_color", Color(0.75, 0.5, 0.5)) # Muted Rose
	else:
		_mic_label.text = "[SPACE] 语音答题"
		_mic_label.add_theme_color_override("font_color", Color(0.45, 0.4, 0.35)) # Muted Taupe

func _show_voice_feedback(category: String) -> void:
	if _voice_feedback == null:
		return
	_voice_feedback.visible = true
	if category == "fact":
		_voice_feedback.text = "\U0001f3a4 \u4e8b\u5b9e"
		_voice_feedback.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	elif category == "thought":
		_voice_feedback.text = "\U0001f3a4 \u60f3\u6cd5"
		_voice_feedback.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
	else:
		_voice_feedback.text = "\U0001f3a4 " + category
		_voice_feedback.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	# Pop in then fade out
	_voice_feedback.scale = Vector2(0.5, 0.5)
	_voice_feedback.modulate = Color.WHITE
	var tw := create_tween()
	tw.tween_property(_voice_feedback, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.8)
	tw.tween_property(_voice_feedback, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): _voice_feedback.visible = false)

func _style_hud_panels() -> void:
	var hud := get_node_or_null("HUD") as CanvasLayer
	if hud == null:
		return
	_top_bar_backdrop = Panel.new()
	_top_bar_backdrop.position = Vector2(8, 6)
	_top_bar_backdrop.size = Vector2(1264, 54)
	_top_bar_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(1.0, 0.98, 0.96, 0.85) # Warm Glass
	top_style.border_color = Color(0.90, 0.85, 0.80, 0.5)
	top_style.set_border_width_all(1)
	top_style.set_corner_radius_all(18)
	top_style.shadow_color = Color(0.3, 0.2, 0.1, 0.07) # Alpha <= 0.1
	top_style.shadow_size = 12
	_top_bar_backdrop.add_theme_stylebox_override("panel", top_style)
	hud.add_child(_top_bar_backdrop)
	hud.move_child(_top_bar_backdrop, 0)

	_bottom_bar_backdrop = Panel.new()
	_bottom_bar_backdrop.position = Vector2(372, 610)
	_bottom_bar_backdrop.size = Vector2(536, 102)
	_bottom_bar_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bottom_style := top_style.duplicate() as StyleBoxFlat
	bottom_style.bg_color = Color(1.0, 0.98, 0.95, 0.92)
	bottom_style.shadow_size = 15
	_bottom_bar_backdrop.add_theme_stylebox_override("panel", bottom_style)
	hud.add_child(_bottom_bar_backdrop)
	hud.move_child(_bottom_bar_backdrop, 1)

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
		_slow_active = true
		for child in cards_layer.get_children():
			if child is SentenceCard:
				child._velocity *= 0.5
		get_tree().create_timer(8.0).timeout.connect(func(): _slow_active = false)
	elif pickup_type == 2:  # TIME
		_time_left += 10.0
	elif pickup_type == 3:  # SHIELD
		_shield_active = true
