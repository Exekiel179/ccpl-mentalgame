## Pickup — collectible power-up in the maze.
## Drawn programmatically, no external assets needed.
extends Area2D

signal collected(pickup_type: int)

enum Type { HEAL, SLOW, TIME, SHIELD }

const COLORS: Dictionary = {
	Type.HEAL:   Color(0.2, 0.9, 0.3),
	Type.SLOW:   Color(0.3, 0.5, 1.0),
	Type.TIME:   Color(1.0, 0.85, 0.2),
	Type.SHIELD: Color(0.9, 0.9, 1.0),
}
const ICONS: Dictionary = {
	Type.HEAL:   "+",
	Type.SLOW:   "S",
	Type.TIME:   "T",
	Type.SHIELD: "\u269b",
}

var pickup_type: int = Type.HEAL
var _phase: float = 0.0

func _ready() -> void:
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	cs.shape = circle
	add_child(cs)
	body_entered.connect(_on_body_entered)

func setup(type_val: int, pos: Vector2) -> void:
	pickup_type = type_val
	position = pos

func _process(delta: float) -> void:
	_phase += delta * 3.0
	queue_redraw()

func _draw() -> void:
	var col: Color = COLORS.get(pickup_type, Color.WHITE)
	var pulse: float = 0.7 + sin(_phase) * 0.3
	col.a = pulse
	draw_circle(Vector2.ZERO, 14.0, col)
	draw_arc(Vector2.ZERO, 14.0, 0, TAU, 16, Color(1, 1, 1, 0.5 * pulse), 2.0)
	# Icon letter
	var icon: String = ICONS.get(pickup_type, "?")
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(-6, 6), icon, HORIZONTAL_ALIGNMENT_CENTER, 20, 16, Color.WHITE)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		collected.emit(pickup_type)
		queue_free()
