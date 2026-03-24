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
	queue_redraw()

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
	# Glow halo (brighter)
	draw_circle(Vector2.ZERO, 22.0, Color(0.4, 0.9, 1.0, 0.18))
	
	# Outer white stroke for contrast
	draw_circle(Vector2.ZERO, 14.5, Color(1, 1, 1, 1))
	
	# Body (Vivid Orange)
	draw_circle(Vector2.ZERO, 13.0, Color(1.0, 0.45, 0.1))
	draw_circle(Vector2.ZERO, 10.0, Color(1.0, 0.65, 0.2))
	
	# Head
	draw_circle(Vector2(0, -7), 6.5, Color(0.95, 0.82, 0.68))
	draw_circle(Vector2(0, -7), 5.5, Color(1.0, 0.88, 0.75))
	
	# Eyes
	draw_circle(Vector2(-2.5, -8), 1.8, Color(0.05, 0.05, 0.15))
	draw_circle(Vector2(2.5, -8), 1.8, Color(0.05, 0.05, 0.15))
	
	# Direction indicator arrow
	if _move_dir != Vector2.ZERO:
		var tip := _move_dir * 16.0
		draw_line(Vector2.ZERO, tip, Color(1, 1, 1, 1), 2.5)
		var perp := Vector2(-_move_dir.y, _move_dir.x) * 4.0
		draw_line(tip, tip - _move_dir * 5.0 + perp, Color(1, 1, 1, 1), 2.0)
		draw_line(tip, tip - _move_dir * 5.0 - perp, Color(1, 1, 1, 1), 2.0)
	
	# Outer ring (glowy cyan)
	draw_arc(Vector2.ZERO, 14.5, 0, TAU, 32, Color(0.4, 0.9, 1.0, 0.6), 2.0)
