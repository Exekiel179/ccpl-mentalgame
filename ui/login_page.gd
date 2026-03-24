## LoginPage — refined UI using static illustrated background.
extends Control

@onready var btn_login: Button       = %BtnLogin
@onready var login_card: PanelContainer = %LoginCard
@onready var bg_sprite: Sprite2D      = %BGSprite
# IllustSprite is removed as the characters are baked into the new background

@onready var gemini_bg: Node          = $GeminiBG
@onready var gemini_header: Node      = $GeminiHeader

func _ready() -> void:
	# Signal connections
	btn_login.pressed.connect(_on_login_pressed)
	
	# Load and set the static illustrated background image
	var static_bg: Texture2D = preload("res://assets/ui/background_login.png")
	if static_bg:
		bg_sprite.texture = static_bg
		bg_sprite.position = get_viewport_rect().size / 2
		var s: Vector2 = get_viewport_rect().size / static_bg.get_size()
		bg_sprite.scale = Vector2(max(s.x, s.y), max(s.x, s.y))
		bg_sprite.modulate.a = 1.0
	
	# Visual Generation (subtle overlays only)
	_generate_visuals()
	
	# Entrance Animation
	_play_entrance_animation()
	
	# Background Music
	AmbientMusic.start(AmbientMusic.Track.MENU)

func _generate_visuals() -> void:
	# Background patterns are already in the image, we can skip or add very faint overlays
	# gemini_header.generate_background(...) 
	pass

func _play_entrance_animation() -> void:
	login_card.modulate.a = 0.0
	login_card.scale = Vector2(0.96, 0.96)
	login_card.pivot_offset = login_card.size / 2
	
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(login_card, "modulate:a", 1.0, 0.7).set_delay(0.2)
	tw.tween_property(login_card, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_login_pressed() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		get_tree().change_scene_to_file("res://ui/main_menu.tscn")
	)
