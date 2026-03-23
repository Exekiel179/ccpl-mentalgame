## CogCard — draggable card for the cognitive card battle game.
## Spring-physics drag adapted from godot-card-game-frame (1185724109).
extends Control

const CogData = preload("res://data/cog_card_data.gd")

# ── Spring physics (from card.gd in the framework) ────────────────────────────
var velocity: Vector2 = Vector2.ZERO
const DAMPING:   float = 0.35
const STIFFNESS: float = 500.0

# ── State ─────────────────────────────────────────────────────────────────────
enum CardState { FOLLOWING, DRAGGING, VFS, FAKE }
var state: CardState = CardState.FOLLOWING

var follow_target: Node = null     # anchor marker this card floats toward
var pre_zone: Node    = null       # zone this card belongs to
var _drop_zone: Node  = null       # zone under mouse while dragging
var _dup: Control     = null       # ghost copy shown while dragging

# ── Card data ─────────────────────────────────────────────────────────────────
var card_key:   String     = ""
var card_type:  int        = -1    # CogCardData.CardType
var card_info:  Dictionary = {}

# Skill card properties
var targets_distortion: Array = []
var effect_value:       int   = 0

# Thought card properties
var distortion_type: int = -1
var damage_value:    int = 0

# Signals
signal card_played(card: Control, target_zone: Node)
signal card_returned(card: Control)

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	custom_minimum_size = Vector2(130, 180)
	size = Vector2(130, 180)
	mouse_filter = Control.MOUSE_FILTER_PASS

func _process(delta: float) -> void:
	match state:
		CardState.DRAGGING:
			follow(get_global_mouse_position() - size * 0.5, delta)
			_update_drop_zone()
		CardState.FOLLOWING:
			if follow_target != null:
				follow(follow_target.global_position, delta)
		CardState.VFS:
			follow(get_global_mouse_position() - size * 0.5, delta)

func follow(target: Vector2, delta: float) -> void:
	var displacement := target - global_position
	velocity += displacement * STIFFNESS * delta
	velocity *= (1.0 - DAMPING)
	global_position += velocity * delta

func _update_drop_zone() -> void:
	var mouse_pos := get_global_mouse_position()
	_drop_zone = null
	for zone in get_tree().get_nodes_in_group("card_droppable"):
		if zone.visible and zone.get_global_rect().has_point(mouse_pos):
			_drop_zone = zone

# ── Initialization ─────────────────────────────────────────────────────────────
func init_card(key: String) -> void:
	card_key = key
	var skill_cards := CogData.get_skill_cards()
	var thought_cards := CogData.get_thought_cards()
	if skill_cards.has(key):
		card_type = CogData.CardType.SKILL
		card_info = skill_cards[key]
		targets_distortion = card_info["targets"]
		effect_value = card_info["effect_value"]
	elif thought_cards.has(key):
		card_type = CogData.CardType.THOUGHT
		card_info = thought_cards[key]
		distortion_type = card_info["distortion"]
		damage_value = card_info["damage"]
	_build_visual()

func _build_visual() -> void:
	if card_info.is_empty():
		return
	# Panel background
	var panel := Panel.new()
	panel.name = "CardBody"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	if card_type == CogData.CardType.SKILL:
		var c: Color = card_info["color"]
		sb.bg_color = Color(c.r * 0.18, c.g * 0.18, c.b * 0.18, 0.97)
		sb.border_color = c
	else:
		sb.bg_color = Color(0.28, 0.06, 0.06, 0.97)
		sb.border_color = Color(0.92, 0.28, 0.28)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 5
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	# Layout inside card
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	# Card name
	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = card_info["display_name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	name_lbl.add_theme_constant_override("outline_size", 3)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	# Distortion / type badge
	var type_lbl := Label.new()
	type_lbl.name = "TypeLabel"
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 10)
	type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if card_type == CogData.CardType.SKILL:
		type_lbl.text = "【技能】"
		type_lbl.add_theme_color_override("font_color", card_info["color"])
	else:
		var d_name: String = CogData.distortion_name(distortion_type)
		type_lbl.text = "【%s】" % d_name
		type_lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	vbox.add_child(type_lbl)

	# Separator
	var sep := HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sep)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.name = "DescLabel"
	desc_lbl.text = card_info["description"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.80, 0.84, 0.92))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc_lbl)

	# Value label at bottom
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	var val_lbl := Label.new()
	val_lbl.name = "ValueLabel"
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_size_override("font_size", 11)
	val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if card_type == CogData.CardType.SKILL:
		val_lbl.text = "+%d 心理值" % effect_value
		val_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	else:
		val_lbl.text = "-%d 心理值" % damage_value
		val_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	vbox.add_child(val_lbl)

	# Invisible drag button overlay
	var btn := Button.new()
	btn.name = "DragButton"
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	var btn_style := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_stylebox_override("hover", btn_style)
	btn.add_theme_stylebox_override("pressed", btn_style)
	btn.add_theme_stylebox_override("focus", btn_style)
	btn.button_down.connect(_on_drag_start)
	btn.button_up.connect(_on_drag_end)
	add_child(btn)

# ── Drag ──────────────────────────────────────────────────────────────────────
func _on_drag_start() -> void:
	if state != CardState.FOLLOWING:
		return
	if card_type == CogData.CardType.THOUGHT:
		return  # thought cards are not draggable by player
	# Create ghost duplicate in VFS layer
	_dup = _make_ghost()
	# Start dragging
	state = CardState.DRAGGING
	if follow_target != null:
		follow_target.queue_free()
		follow_target = null
	if pre_zone != null and pre_zone.has_method("on_card_lift"):
		pre_zone.on_card_lift(self)
	z_index = 200

func _on_drag_end() -> void:
	if _dup != null:
		_dup.queue_free()
		_dup = null
	z_index = 0
	if _drop_zone != null:
		card_played.emit(self, _drop_zone)
	else:
		card_returned.emit(self)
	state = CardState.FOLLOWING

func _make_ghost() -> Control:
	var ghost = get_script().new()
	var vfs := get_tree().get_first_node_in_group("card_vfs_layer")
	if vfs == null:
		return ghost
	vfs.add_child(ghost)
	ghost.init_card(card_key)
	ghost.global_position = global_position
	ghost.state = CardState.VFS
	ghost.modulate.a = 0.5
	ghost.z_index = 100
	return ghost

# ── Helpers ───────────────────────────────────────────────────────────────────
func can_counter(thought_card) -> bool:
	if card_type != CogData.CardType.SKILL:
		return false
	return thought_card.distortion_type in targets_distortion

func play_appear_tween() -> void:
	modulate.a = 0.0
	scale = Vector2(0.7, 0.7)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func play_destroy_tween() -> Tween:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_property(self, "scale", Vector2(1.3, 1.3), 0.3)
	return tw
