## CardGameController — turn-based cognitive card battle (玩法二).
## Gameplay: Player drags skill cards onto thought cards to counter distortions.
## Adapted framework from godot-card-game-frame (1185724109).
extends Node2D

const CogData = preload("res://data/cog_card_data.gd")

# ── Constants ─────────────────────────────────────────────────────────────────
const CogCard := preload("res://game/card_game/cog_card.gd")
const MAX_HEALTH: int   = 100
const HAND_SIZE:  int   = 5
const THOUGHTS_PER_TURN: int = 2
const MAX_TURNS:  int   = 8

# ── State ─────────────────────────────────────────────────────────────────────
var _health:       int  = MAX_HEALTH
var _score:        int  = 0
var _turn:         int  = 1
var _game_active:  bool = false
var _scenario:     String = "学业压力"
var _hand_cards:   Array = []
var _thought_cards: Array = []
var _skill_pool:   Array[String]   = []
var _thought_pool: Array[String]   = []

# ── Node references (built in _ready) ─────────────────────────────────────────
var _bg_sprite:       Sprite2D
var _vfs_layer:       CanvasLayer
var _hud_layer:       CanvasLayer
var _health_bar:      ProgressBar
var _health_label:    Label
var _turn_label:      Label
var _scenario_label:  Label
var _score_label:     Label
var _feedback_label:  Label
var _end_turn_btn:    Button
var _challenge_area:  Control    # HBoxContainer for thought cards
var _hand_area:       Control    # HBoxContainer for hand cards
var _challenge_panel: Panel
var _hand_panel:      Panel
var _card_layer:      Control    # parent for all CogCard nodes
var _anchor_layer:    Control    # holds invisible anchor markers
var _challenge_drop:  Panel      # the droppable challenge panel
var _gemini_service:  Node

# ── Build scene at runtime ────────────────────────────────────────────────────
func _ready() -> void:
	_scenario = GameManager.current_scenario
	_build_scene()
	_connect_gemini()
	_start_game()

func _build_scene() -> void:
	# Background
	_bg_sprite = Sprite2D.new()
	_bg_sprite.name = "BackgroundSprite"
	add_child(_bg_sprite)

	# VFS layer — cards live here while dragged (spring ghost)
	_vfs_layer = CanvasLayer.new()
	_vfs_layer.layer = 10
	_vfs_layer.add_to_group("card_vfs_layer")
	add_child(_vfs_layer)

	# Card layer — card nodes' actual home
	_card_layer = Control.new()
	_card_layer.name = "CardLayer"
	_card_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_card_layer)

	# Anchor layer — invisible position markers cards float toward
	_anchor_layer = Control.new()
	_anchor_layer.name = "AnchorLayer"
	_anchor_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_anchor_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_anchor_layer)

	_build_challenge_zone()
	_build_hand_zone()
	_build_hud()

	# Gemini background service
	var GeminiScript := load("res://services/gemini_service.gd")
	if GeminiScript:
		_gemini_service = GeminiScript.new()
		_gemini_service.name = "GeminiService"
		add_child(_gemini_service)

func _build_challenge_zone() -> void:
	# Drop zone panel (challenge area, upper half)
	_challenge_drop = Panel.new()
	_challenge_drop.name = "ChallengeDropZone"
	_challenge_drop.position = Vector2(20, 80)
	_challenge_drop.size = Vector2(1240, 260)
	_challenge_drop.add_to_group("card_droppable")
	var drop_style := StyleBoxFlat.new()
	drop_style.bg_color = Color(0.28, 0.06, 0.06, 0.55)
	drop_style.border_color = Color(0.9, 0.3, 0.3, 0.6)
	drop_style.set_border_width_all(2)
	drop_style.set_corner_radius_all(14)
	_challenge_drop.add_theme_stylebox_override("panel", drop_style)
	add_child(_challenge_drop)

	var title_lbl := Label.new()
	title_lbl.text = "⚠  危机想法区 — 将技能牌拖拽至此化解"
	title_lbl.position = Vector2(20, 8)
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
	_challenge_drop.add_child(title_lbl)

	_challenge_area = HBoxContainer.new()
	_challenge_area.name = "ChallengeCards"
	_challenge_area.alignment = BoxContainer.ALIGNMENT_CENTER
	_challenge_area.add_theme_constant_override("separation", 20)
	_challenge_area.position = Vector2(0, 35)
	_challenge_area.size = Vector2(1240, 220)
	_challenge_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_challenge_drop.add_child(_challenge_area)

func _build_hand_zone() -> void:
	_hand_panel = Panel.new()
	_hand_panel.name = "HandPanel"
	_hand_panel.position = Vector2(20, 400)
	_hand_panel.size = Vector2(1240, 270)
	var hand_style := StyleBoxFlat.new()
	hand_style.bg_color = Color(0.04, 0.12, 0.28, 0.75)
	hand_style.border_color = Color(0.35, 0.6, 1.0, 0.55)
	hand_style.set_border_width_all(2)
	hand_style.set_corner_radius_all(14)
	_hand_panel.add_theme_stylebox_override("panel", hand_style)
	add_child(_hand_panel)

	var title_lbl := Label.new()
	title_lbl.text = "🃏  技能手牌 — 拖拽到上方化解危机想法"
	title_lbl.position = Vector2(20, 8)
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	_hand_panel.add_child(title_lbl)

	_hand_area = HBoxContainer.new()
	_hand_area.name = "HandCards"
	_hand_area.alignment = BoxContainer.ALIGNMENT_CENTER
	_hand_area.add_theme_constant_override("separation", 16)
	_hand_area.position = Vector2(0, 35)
	_hand_area.size = Vector2(1240, 230)
	_hand_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand_panel.add_child(_hand_area)

func _build_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "HUD"
	_hud_layer.layer = 5
	add_child(_hud_layer)

	# Top bar backdrop
	var top_bar := Panel.new()
	top_bar.position = Vector2(8, 6)
	top_bar.size = Vector2(1264, 68)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tb_style := StyleBoxFlat.new()
	tb_style.bg_color = Color(0.05, 0.09, 0.18, 0.82)
	tb_style.border_color = Color(0.36, 0.58, 0.95, 0.5)
	tb_style.set_border_width_all(2)
	tb_style.set_corner_radius_all(12)
	top_bar.add_theme_stylebox_override("panel", tb_style)
	_hud_layer.add_child(top_bar)

	# Health bar
	_health_bar = ProgressBar.new()
	_health_bar.position = Vector2(20, 12)
	_health_bar.size = Vector2(280, 20)
	_health_bar.max_value = MAX_HEALTH
	_health_bar.value = MAX_HEALTH
	_health_bar.show_percentage = false
	_hud_layer.add_child(_health_bar)

	_health_label = Label.new()
	_health_label.position = Vector2(20, 32)
	_health_label.add_theme_font_size_override("font_size", 14)
	_health_label.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))
	_hud_layer.add_child(_health_label)

	_scenario_label = Label.new()
	_scenario_label.position = Vector2(480, 16)
	_scenario_label.size = Vector2(320, 40)
	_scenario_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scenario_label.add_theme_font_size_override("font_size", 20)
	_scenario_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	_scenario_label.add_theme_color_override("font_outline_color", Color(0, 0, 0.1))
	_scenario_label.add_theme_constant_override("outline_size", 4)
	_hud_layer.add_child(_scenario_label)

	_turn_label = Label.new()
	_turn_label.position = Vector2(820, 16)
	_turn_label.add_theme_font_size_override("font_size", 16)
	_turn_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	_hud_layer.add_child(_turn_label)

	_score_label = Label.new()
	_score_label.position = Vector2(1020, 16)
	_score_label.add_theme_font_size_override("font_size", 16)
	_score_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	_hud_layer.add_child(_score_label)

	# Feedback label (center screen)
	_feedback_label = Label.new()
	_feedback_label.position = Vector2(340, 350)
	_feedback_label.size = Vector2(600, 50)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_font_size_override("font_size", 28)
	_feedback_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_feedback_label.add_theme_constant_override("outline_size", 5)
	_feedback_label.visible = false
	_hud_layer.add_child(_feedback_label)

	# End turn button
	_end_turn_btn = Button.new()
	_end_turn_btn.position = Vector2(1080, 688)
	_end_turn_btn.size = Vector2(182, 24)
	_end_turn_btn.text = "结束回合  ▶"
	_end_turn_btn.pressed.connect(_on_end_turn)
	var eb_style := StyleBoxFlat.new()
	eb_style.bg_color = Color(0.08, 0.18, 0.12, 0.92)
	eb_style.border_color = Color(0.3, 0.85, 0.5, 0.7)
	eb_style.set_border_width_all(2)
	eb_style.set_corner_radius_all(8)
	eb_style.content_margin_top = 4.0
	eb_style.content_margin_bottom = 4.0
	_end_turn_btn.add_theme_stylebox_override("normal", eb_style)
	var eb_hover := eb_style.duplicate() as StyleBoxFlat
	eb_hover.bg_color = Color(0.12, 0.30, 0.20, 0.96)
	eb_hover.border_color = Color(0.4, 1.0, 0.6)
	_end_turn_btn.add_theme_stylebox_override("hover", eb_hover)
	_end_turn_btn.add_theme_font_size_override("font_size", 14)
	_end_turn_btn.add_theme_color_override("font_color", Color(0.85, 1.0, 0.9))
	_hud_layer.add_child(_end_turn_btn)

	# Back to menu button
	var menu_btn := Button.new()
	menu_btn.position = Vector2(10, 688)
	menu_btn.size = Vector2(120, 24)
	menu_btn.text = "← 主菜单"
	menu_btn.pressed.connect(func(): GameManager.go_to_main_menu())
	var mb_style := StyleBoxFlat.new()
	mb_style.bg_color = Color(0.10, 0.10, 0.18, 0.86)
	mb_style.border_color = Color(0.4, 0.5, 0.8, 0.5)
	mb_style.set_border_width_all(2)
	mb_style.set_corner_radius_all(8)
	mb_style.content_margin_top = 4.0
	mb_style.content_margin_bottom = 4.0
	menu_btn.add_theme_stylebox_override("normal", mb_style)
	menu_btn.add_theme_font_size_override("font_size", 13)
	menu_btn.add_theme_color_override("font_color", Color(0.75, 0.80, 1.0))
	_hud_layer.add_child(menu_btn)

# ── Gemini background ─────────────────────────────────────────────────────────
func _connect_gemini() -> void:
	if _gemini_service == null:
		return
	if _gemini_service.has_signal("image_ready"):
		_gemini_service.image_ready.connect(_on_bg_ready)
	if _gemini_service.has_method("generate_background"):
		_gemini_service.generate_background(_scenario + " 卡牌对战")

func _on_bg_ready(texture: Texture2D) -> void:
	_bg_sprite.texture = texture
	var vp := get_viewport_rect().size
	_bg_sprite.position = vp * 0.5
	var ts := texture.get_size()
	if ts.x > 0 and ts.y > 0:
		_bg_sprite.scale = Vector2(vp.x / ts.x, vp.y / ts.y)

# ── Game start ────────────────────────────────────────────────────────────────
func _start_game() -> void:
	_skill_pool = CogData.get_all_skill_keys()
	_skill_pool.shuffle()
	_thought_pool = CogData.get_thoughts_for_scenario(_scenario)
	_thought_pool.shuffle()

	_update_hud()
	_deal_hand()
	_spawn_thoughts()
	_game_active = true
	AmbientMusic.start()

func _update_hud() -> void:
	_health_bar.value = _health
	_health_label.text = "心理健康: %d / %d" % [_health, MAX_HEALTH]
	_turn_label.text = "第 %d / %d 回合" % [_turn, MAX_TURNS]
	_score_label.text = "得分: %d" % _score
	_scenario_label.text = "【%s】卡牌对战" % _scenario
	var ratio := float(_health) / float(MAX_HEALTH)
	var sb := _health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if sb:
		sb.bg_color = Color(1.0 - ratio, ratio * 0.8, 0.1)

# ── Hand management ───────────────────────────────────────────────────────────
func _deal_hand() -> void:
	var needed := HAND_SIZE - _hand_cards.size()
	for i in needed:
		if _skill_pool.is_empty():
			_skill_pool = CogData.get_all_skill_keys()
			_skill_pool.shuffle()
		var key: String = _skill_pool.pop_front()
		_create_hand_card(key)

func _create_hand_card(key: String) -> void:
	var card = CogCard.new()
	_card_layer.add_child(card)
	card.init_card(key)
	card.pre_zone = _hand_panel

	# Create anchor marker in hand area
	var anchor := Control.new()
	anchor.custom_minimum_size = Vector2(130, 180)
	_hand_area.add_child(anchor)
	card.follow_target = anchor
	card.global_position = anchor.global_position

	card.card_played.connect(_on_card_played)
	card.card_returned.connect(_on_card_returned)
	card.play_appear_tween()
	_hand_cards.append(card)

# Called by CogCard when it lifts off
func on_card_lift(_card) -> void:
	pass  # could highlight valid drop zones here

# ── Thought spawning ──────────────────────────────────────────────────────────
func _spawn_thoughts() -> void:
	var count := mini(THOUGHTS_PER_TURN, _thought_pool.size())
	if count == 0:
		_thought_pool = CogData.get_thoughts_for_scenario(_scenario)
		_thought_pool.shuffle()
		count = mini(THOUGHTS_PER_TURN, _thought_pool.size())

	for i in count:
		var key: String = _thought_pool.pop_front()
		_create_thought_card(key)

func _create_thought_card(key: String) -> void:
	var card = CogCard.new()
	_card_layer.add_child(card)
	card.init_card(key)
	card.state = CogCard.CardState.FOLLOWING

	var anchor := Control.new()
	anchor.custom_minimum_size = Vector2(130, 180)
	_challenge_area.add_child(anchor)
	card.follow_target = anchor
	card.global_position = anchor.global_position

	card.play_appear_tween()
	_thought_cards.append(card)

# ── Card played onto challenge zone ───────────────────────────────────────────
func _on_card_played(skill_card, zone: Node) -> void:
	if zone != _challenge_drop:
		_on_card_returned(skill_card)
		return
	if _thought_cards.is_empty():
		_show_feedback("没有可化解的想法！", Color(1.0, 0.8, 0.3))
		_on_card_returned(skill_card)
		return

	# Find best matching thought card
	var target_thought: CogCard = null
	for t in _thought_cards:
		if skill_card.can_counter(t):
			target_thought = t
			break
	# If no perfect match, use first thought card (partial counter)
	if target_thought == null:
		target_thought = _thought_cards[0]

	_resolve_counter(skill_card, target_thought)

func _on_card_returned(card) -> void:
	# Return card to hand anchor
	var anchor := Control.new()
	anchor.custom_minimum_size = Vector2(130, 180)
	_hand_area.add_child(anchor)
	card.follow_target = anchor
	card.state = CogCard.CardState.FOLLOWING

func _resolve_counter(skill_card, thought_card) -> void:
	var is_match: bool = skill_card.can_counter(thought_card)
	_hand_cards.erase(skill_card)
	_thought_cards.erase(thought_card)

	# Remove thought card's anchor
	if thought_card.follow_target:
		thought_card.follow_target.queue_free()
		thought_card.follow_target = null

	if is_match:
		# Perfect counter — restore health, gain score
		var heal: int = skill_card.effect_value
		_health = mini(_health + heal, MAX_HEALTH)
		_score += 30 + skill_card.effect_value
		_show_feedback("✨ 完美化解！+%d 心理值" % heal, Color(0.4, 1.0, 0.6))
		SfxManager.play_correct()
	else:
		# Partial counter — just remove thought, no bonus
		_score += 10
		_show_feedback("🔄 部分化解", Color(0.8, 0.8, 0.4))
		SfxManager.play_correct()

	# Destroy both cards with animation
	var tw: Tween = skill_card.play_destroy_tween()
	await tw.finished
	skill_card.queue_free()
	var tw2: Tween = thought_card.play_destroy_tween()
	await tw2.finished
	thought_card.queue_free()

	_update_hud()

	# Auto end turn if all thoughts resolved
	if _thought_cards.is_empty() and _game_active:
		await get_tree().create_timer(0.8).timeout
		_advance_turn()

# ── Turn management ───────────────────────────────────────────────────────────
func _on_end_turn() -> void:
	if not _game_active:
		return
	# Unresolved thoughts damage player
	for t in _thought_cards:
		_health -= t.damage_value
		t.play_destroy_tween()
	await get_tree().create_timer(0.4).timeout
	for t in _thought_cards:
		if is_instance_valid(t) and t.follow_target:
			t.follow_target.queue_free()
		if is_instance_valid(t):
			t.queue_free()
	_thought_cards.clear()

	if _health <= 0:
		_on_game_over()
		return
	_advance_turn()

func _advance_turn() -> void:
	_turn += 1
	_update_hud()
	if _turn > MAX_TURNS:
		_on_victory()
		return
	_deal_hand()
	_spawn_thoughts()

# ── Win / Lose ────────────────────────────────────────────────────────────────
func _on_game_over() -> void:
	_game_active = false
	_health = 0
	_update_hud()
	_show_feedback("💔 心理健康耗尽，游戏结束", Color(1.0, 0.3, 0.3))
	AmbientMusic.stop()
	GameManager.update_high_score(_score)
	await get_tree().create_timer(2.5).timeout
	get_tree().change_scene_to_file("res://ui/game_over.tscn")

func _on_victory() -> void:
	_game_active = false
	_score += _health * 2
	_update_hud()
	_show_feedback("🌟 坚持下来了！认知重构成功！", Color(1.0, 0.95, 0.4))
	AmbientMusic.stop()
	GameManager.update_high_score(_score)
	await get_tree().create_timer(2.0).timeout
	GameManager.go_to_win()

# ── Feedback flash ────────────────────────────────────────────────────────────
func _show_feedback(text: String, color: Color) -> void:
	_feedback_label.text = text
	_feedback_label.add_theme_color_override("font_color", color)
	_feedback_label.modulate = Color.WHITE
	_feedback_label.visible = true
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(_feedback_label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): _feedback_label.visible = false)
