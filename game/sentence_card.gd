## SentenceCard — a glowing ghost that homes in on the player.
## Only deals damage on physical contact. Timeout = player dodged = no damage.
class_name SentenceCard
extends Control

signal answered(card: SentenceCard, correct: bool)
signal timed_out(card: SentenceCard)

const CARD_W         := 260.0
const CARD_H         := 76.0
const CARD_SPEED_MIN := 80.0
const CARD_SPEED_MAX := 140.0
const TIME_LIMIT     := 6.0
const DAMAGE_WRONG   := 20
const DAMAGE_TOUCH   := 15
const TURN_RATE      := 1.4   # how fast ghost steers toward player

enum Side { LEFT, RIGHT, TOP, BOTTOM }

@onready var label_text: Label      = %SentenceLabel
@onready var timer_bar: ProgressBar = %TimerBar
@onready var feedback_label: Label  = %FeedbackLabel

var sentence_dict: Dictionary  = {}
var tracking_target: Node2D    = null
var _time_left: float          = TIME_LIMIT
var _velocity: Vector2         = Vector2.ZERO
var _answered: bool            = false
var is_nearest: bool           = false
var _spine_pos: Vector2        = Vector2.ZERO
var _phase: float              = 0.0
var tutorial_mode: bool        = false
var _answer_label: Label       = null

func setup(data: Dictionary, side: int) -> void:
	sentence_dict = data
	var spd := randf_range(CARD_SPEED_MIN, CARD_SPEED_MAX)
	var vp  := get_viewport_rect().size
	size = Vector2(CARD_W, CARD_H)
	_phase = randf() * TAU
	match side:
		Side.LEFT:
			position = Vector2(-CARD_W - 10, randf_range(60, vp.y - CARD_H - 60))
			_velocity = Vector2(spd, 0)
		Side.RIGHT:
			position = Vector2(vp.x + 10, randf_range(60, vp.y - CARD_H - 60))
			_velocity = Vector2(-spd, 0)
		Side.TOP:
			position = Vector2(randf_range(60, vp.x - CARD_W - 60), -CARD_H - 10)
			_velocity = Vector2(0, spd * 0.7)
		Side.BOTTOM:
			position = Vector2(randf_range(60, vp.x - CARD_W - 60), vp.y + 10)
			_velocity = Vector2(0, -spd * 0.7)
	_spine_pos = position
	if label_text:
		label_text.text = sentence_dict.get("text", "")

## Spawn near a world position with homing enabled.
func setup_near_player(data: Dictionary, player_world_pos: Vector2) -> void:
	sentence_dict = data
	var spd := randf_range(CARD_SPEED_MIN, CARD_SPEED_MAX)
	size = Vector2(CARD_W, CARD_H)
	_phase = randf() * TAU
	var angle := randf() * TAU
	var dist  := randf_range(380.0, 520.0)
	var offset := Vector2(cos(angle), sin(angle)) * dist
	position = player_world_pos + offset - size * 0.5
	_velocity = -offset.normalized() * spd
	_spine_pos = position
	if label_text:
		label_text.text = sentence_dict.get("text", "")

func _ready() -> void:
	label_text.text = sentence_dict.get("text", "")
	label_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.visible = false
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_bar.max_value = TIME_LIMIT
	timer_bar.value = TIME_LIMIT
	modulate = Color(1.0, 0.95, 0.85, 0.9) # Warm Cream
	# Polished panel style
	var panel := get_node_or_null("Panel") as Panel
	if panel:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1.0, 0.98, 0.96, 0.92) # Warm White
		sb.border_color = Color(0.9, 0.85, 0.75, 0.6)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(16)
		sb.shadow_color = Color(0.4, 0.3, 0.2, 0.08) # Alpha <= 0.1
		sb.shadow_size = 8
		panel.add_theme_stylebox_override("panel", sb)
	# Better label style
	label_text.add_theme_font_size_override("font_size", 18)
	label_text.add_theme_color_override("font_color", Color(0.25, 0.2, 0.15)) # Deep Warm Brown
	feedback_label.add_theme_font_size_override("font_size", 14)
	# Tutorial: show answer and "say it" prompt
	if tutorial_mode:
		timer_bar.visible = false
		_answer_label = Label.new()
		var cat: String = sentence_dict.get("category", "")
		var cat_cn: String = "事实" if cat == "fact" else "想法"
		_answer_label.text = "🎤 请说：“%s”" % cat_cn
		_answer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_answer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_answer_label.add_theme_font_size_override("font_size", 16)
		if cat == "fact":
			_answer_label.add_theme_color_override("font_color", Color(0.35, 0.55, 0.40)) # Sage
		else:
			_answer_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.6)) # Gentle Coral Pink
		_answer_label.position = Vector2(0, CARD_H - 6)
		_answer_label.size = Vector2(CARD_W, 24)
		add_child(_answer_label)

func _process(delta: float) -> void:
	if _answered:
		return

	# Tutorial: cards float gently, don't home aggressively
	if tutorial_mode:
		_phase += delta * 2.0
		_spine_pos += _velocity * delta * 0.3
		var perp2 := Vector2(-_velocity.y, _velocity.x).normalized()
		position = _spine_pos + perp2 * sin(_phase) * 6.0
		modulate = Color(1.0, 0.98, 0.9, 0.95 + sin(_phase) * 0.05)
		return

	# Home toward player (dynamic destination)
	if tracking_target != null and is_instance_valid(tracking_target):
		var card_center := _spine_pos + size * 0.5
		var to_target   := tracking_target.global_position - card_center
		if to_target.length() > 20.0:
			var desired := to_target.normalized() * _velocity.length()
			_velocity = _velocity.lerp(desired, TURN_RATE * delta)

	# Ghost wobble — spine moves straight-ish, card weaves sideways
	_phase += delta * 2.5
	_spine_pos += _velocity * delta
	var perp := Vector2(-_velocity.y, _velocity.x).normalized()
	position = _spine_pos + perp * sin(_phase) * 10.0

	# Pulsing glow — nearest card is warm orange, others are cream
	if is_nearest:
		modulate = Color(1.0, 0.85, 0.6, 0.95 + sin(_phase * 1.5) * 0.05)
	else:
		modulate = Color(1.0, 0.95, 0.85, 0.75 + sin(_phase * 0.9) * 0.1)

	# Countdown
	_time_left -= delta
	timer_bar.value = _time_left
	var ratio := _time_left / TIME_LIMIT
	var bar_stylebox := timer_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if bar_stylebox:
		# Soft green to Terra Cotta (0.8, 0.6, 0.5) transition
		var low_time_color := Color(0.8, 0.6, 0.5) # Terra Cotta
		var high_time_color := Color(0.52, 0.64, 0.54) # Sage Green
		bar_stylebox.bg_color = low_time_color.lerp(high_time_color, ratio)

	if _time_left <= 0.0:
		_on_timeout()
	elif _is_offscreen():
		_on_timeout()

func submit_answer(player_category: String) -> void:
	if _answered:
		return
	_answered = true
	var correct: bool = player_category == (sentence_dict.get("category", "") as String)
	_show_feedback(correct)
	answered.emit(self, correct)

## Called by game_controller when this card physically touches the player.
func on_hit_player() -> void:
	if _answered:
		return
	_answered = true
	feedback_label.visible = true
	feedback_label.text = "碰到了，深呼吸..."
	feedback_label.modulate = Color(0.75, 0.5, 0.5) # Muted Rose
	_spawn_particles(Color(0.8, 0.6, 0.5), 15)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func _on_timeout() -> void:
	if _answered:
		return
	_answered = true
	# Timeout = dodged successfully, no damage
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)
	timed_out.emit(self)

func _show_feedback(correct: bool) -> void:
	feedback_label.visible = true
	if correct:
		var distortion: String = sentence_dict.get("distortion", "")
		if distortion != "":
			feedback_label.text = "✓ 正确！[" + distortion + "]"
		else:
			feedback_label.text = "✓ 正确！"
		feedback_label.modulate = Color(0.35, 0.65, 0.45) # Sage Green
		_spawn_particles(Color(0.5, 0.8, 0.6), 20)
	else:
		feedback_label.text = "✗ " + sentence_dict.get("explanation", "再想想")
		feedback_label.modulate = Color(0.8, 0.6, 0.6) # Gentle Coral Pink
		_spawn_particles(Color(0.8, 0.6, 0.5), 12)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.2).set_delay(1.0)
	tween.tween_callback(queue_free)

func _is_offscreen() -> bool:
	return position.x > 2000.0 or position.x < -600.0 \
		or position.y > 1500.0 or position.y < -600.0

func _spawn_particles(color: Color, count: int) -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = count
	particles.lifetime = 0.6
	particles.explosiveness = 0.9
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 120.0
	particles.gravity = Vector2(0, 200)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = color
	particles.position = position + size * 0.5
	if get_parent():
		get_parent().add_child(particles)
		get_tree().create_timer(1.0).timeout.connect(particles.queue_free)
