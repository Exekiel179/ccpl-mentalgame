## MainMenu — entry screen with balanced 3-column layout.
extends Control

const VoiceServiceScript := preload("res://services/voice_service.gd")

@onready var btn_academic: Button       = %BtnAcademic
@onready var btn_family: Button         = %BtnFamily
@onready var btn_social: Button         = %BtnSocial
@onready var btn_card_mode: Button      = %BtnCardMode
@onready var btn_knowledge: Button      = %BtnKnowledge
@onready var btn_knowledge_cards: Button = %BtnKnowledgeCards

@onready var main_card: PanelContainer  = %MainCard
@onready var bg_sprite: Sprite2D        = %BGSprite
@onready var char_sprite: Sprite2D      = %CharSprite
@onready var char_anchor: Marker2D      = %CharAnchor
@onready var diff_hbox: HBoxContainer   = %DifficultyHBox

@onready var gemini_service: Node       = $GeminiService
@onready var gemini_service_char: Node  = $GeminiServiceChar

var _status_label: Label

const SCENARIO_BUTTONS := {
	"学业压力": "📚  学业压力",
	"家庭矛盾": "🏠  家庭矛盾",
	"社交压力": "👥  社交压力",
}

func _ready() -> void:
	# Core connections
	btn_academic.toggle_mode = false
	btn_family.toggle_mode = false
	btn_social.toggle_mode = false
	btn_academic.pressed.connect(func(): _select_scenario("学业压力"))
	btn_family.pressed.connect(func(): _select_scenario("家庭矛盾"))
	btn_social.pressed.connect(func(): _select_scenario("社交压力"))
	btn_card_mode.pressed.connect(func(): _enter_selected_mode(GameManager.GameMode.CARD))
	btn_knowledge.pressed.connect(func(): _enter_selected_mode(GameManager.GameMode.MAZE))
	btn_knowledge_cards.pressed.connect(_open_knowledge_cards)
	_select_scenario(GameManager.current_scenario)

	# Load static background first
	var static_bg: Texture2D = preload("res://assets/ui/background_main.png")
	if static_bg:
		bg_sprite.texture = static_bg
		bg_sprite.position = get_viewport_rect().size / 2
		var s: Vector2 = get_viewport_rect().size / static_bg.get_size()
		bg_sprite.scale = Vector2(max(s.x, s.y), max(s.x, s.y))
		bg_sprite.modulate.a = 1.0

	_setup_difficulty_selection()
	_update_model_status()

	# Start Ambient Music
	AmbientMusic.start(AmbientMusic.Track.MENU)
	
	# Request AI Visuals
	_generate_visuals()

	# Entrance Animation
	_play_entrance_animation()

func _generate_visuals() -> void:
	# gemini_service.image_ready.connect(_on_bg_ready) # Disable dynamic BG overwriting
	
	gemini_service_char.image_ready.connect(_on_char_ready)
	gemini_service_char.generate_background("温柔亲切的心理咨询师立绘，高中生大姐姐风格，穿着柔软的针织衫，温和的微笑，高画质，精致二次元风格")

func _play_entrance_animation() -> void:
	main_card.modulate.a = 0.0
	main_card.scale = Vector2(0.96, 0.96)
	main_card.pivot_offset = main_card.size / 2
	
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(main_card, "modulate:a", 1.0, 0.5)
	tw.tween_property(main_card, "scale", Vector2(1.0, 1.0), 0.4)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)

func _on_bg_ready(tex: Texture2D) -> void:
	# Logic kept but unused by default to respect static BG
	pass

func _on_char_ready(tex: Texture2D) -> void:
	char_sprite.texture = tex
	char_sprite.position = char_anchor.global_position
	# Scale to fit left column nicely
	var target_h := get_viewport_rect().size.y * 0.8
	var s: float = target_h / tex.get_size().y
	char_sprite.scale = Vector2(s * 0.8, s * 0.8) # Start smaller
	char_sprite.modulate.a = 0.0
	
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(char_sprite, "modulate:a", 1.0, 1.2)
	tw.tween_property(char_sprite, "scale", Vector2(s, s), 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _setup_difficulty_selection() -> void:
	var diffs := ["轻松", "标准", "进阶"]
	for i in diffs.size():
		var b := Button.new()
		b.theme_type_variation = "DiffButton"
		b.toggle_mode = true
		b.text = diffs[i]
		b.custom_minimum_size = Vector2(70, 30)
		if GameManager.difficulty == i:
			b.button_pressed = true
		b.pressed.connect(func(): _on_difficulty_picked(i))
		diff_hbox.add_child(b)

func _select_scenario(scenario: String) -> void:
	if not SCENARIO_BUTTONS.has(scenario):
		scenario = "学业压力"
	GameManager.current_scenario = scenario
	_sync_scenario_buttons()

func _sync_scenario_buttons() -> void:
	var buttons := {
		"学业压力": btn_academic,
		"家庭矛盾": btn_family,
		"社交压力": btn_social,
	}
	for scenario in buttons.keys():
		var button: Button = buttons[scenario]
		var selected: bool = GameManager.current_scenario == scenario
		button.text = ("✓ " if selected else "") + String(SCENARIO_BUTTONS[scenario])
	btn_knowledge.text = "🌀  迷宫探索训练 · %s" % GameManager.current_scenario
	btn_knowledge_cards.text = "📖  心理知识卡片 · %s" % GameManager.current_scenario
	btn_card_mode.text = "🃏  CBT 卡牌挑战 · %s" % GameManager.current_scenario

func _enter_selected_mode(mode: int) -> void:
	GameManager.go_to_knowledge(mode)

func _open_knowledge_cards() -> void:
	GameManager.go_to_knowledge()

func _on_difficulty_picked(idx: int) -> void:
	GameManager.difficulty = idx
	for child in diff_hbox.get_children():
		if child is Button and child.theme_type_variation == "DiffButton":
			child.button_pressed = (child.get_index() - 1 == idx) # -1 because of the Label

func _update_model_status() -> void:
	if _status_label == null:
		_status_label = Label.new()
		_status_label.add_theme_font_size_override("font_size", 12)
		_status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.5))
		_status_label.position = Vector2(20, 690)
		add_child(_status_label)

	var status: Dictionary = GameManager.get_voice_calibration_status()
	var state_text := "本地就绪"
	if not status.get("ready", false):
		state_text = "需重新校准"
		var reason: String = String(status.get("reason", ""))
		if reason.is_empty():
			state_text = "在线模式"
		else:
			state_text += "（%s）" % reason
	_status_label.text = "语音引擎状态: " + state_text
