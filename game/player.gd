## Player — top-down CharacterBody2D with custom drawn character.
class_name Player
extends CharacterBody2D

const SPEED := 150.0

var _move_dir := Vector2.ZERO

func _ready() -> void:
	var cs := $CollisionShape2D
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	cs.shape = circle

func _physics_process(_delta: float) -> void:
	var dx := 0.0
	var dy := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dx -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dx += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dy -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dy += 1.0
	_move_dir = Vector2(dx, dy).normalized()
	velocity = _move_dir * SPEED
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	# Glow halo
	draw_circle(Vector2.ZERO, 18.0, Color(0.3, 0.8, 1.0, 0.12))
	# Body (gradient teal)
	draw_circle(Vector2.ZERO, 13.0, Color(0.18, 0.55, 0.80))
	draw_circle(Vector2.ZERO, 11.0, Color(0.25, 0.70, 0.95))
	# Head
	draw_circle(Vector2(0, -7), 6.0, Color(0.95, 0.82, 0.68))
	draw_circle(Vector2(0, -7), 5.0, Color(1.0, 0.88, 0.75))
	# Eyes
	draw_circle(Vector2(-2, -8), 1.5, Color(0.15, 0.15, 0.25))
	draw_circle(Vector2(2, -8), 1.5, Color(0.15, 0.15, 0.25))
	# Direction indicator arrow
	if _move_dir != Vector2.ZERO:
		var tip := _move_dir * 14.0
		draw_line(Vector2.ZERO, tip, Color(1, 1, 1, 0.8), 2.0)
		var perp := Vector2(-_move_dir.y, _move_dir.x) * 3.5
		draw_line(tip, tip - _move_dir * 4.0 + perp, Color(1, 1, 1, 0.6), 1.5)
		draw_line(tip, tip - _move_dir * 4.0 - perp, Color(1, 1, 1, 0.6), 1.5)
	# Outer ring
	draw_arc(Vector2.ZERO, 13.0, 0, TAU, 32, Color(0.5, 0.9, 1.0, 0.4), 1.5)
