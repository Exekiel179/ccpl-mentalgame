## CogCard — draggable card for the cognitive card battle game.
## Spring-physics drag adapted from godot-card-game-frame (1185724109).
extends Control

const CogData = preload("res://data/cog_card_data.gd")

const CARD_CREAM: Color = Color(0.98, 0.96, 0.92, 0.98)
const CARD_CREAM_SOFT: Color = Color(0.95, 0.92, 0.86, 0.98)
const CARD_TEXT: Color = Color(0.27, 0.24, 0.20)
const CARD_MUTED: Color = Color(0.47, 0.41, 0.35)
const CARD_GREEN: Color = Color(0.55, 0.68, 0.57)
const CARD_TERRACOTTA: Color = Color(0.76, 0.57, 0.47)
const CARD_BLUE: Color = Color(0.65, 0.77, 0.84)

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

# Crisis / thought-like display properties
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
	var skill_cards: Dictionary = CogData.get_skill_cards()
	var crisis_cards: Dictionary = {}
	for encounter in CogData.get_encounters_for_scenario(CogData.SCENARIO_ACADEMIC):
		crisis_cards[encounter.get("id", "")] = {
			"display_name": encounter.get("title", ""),
			"description": encounter.get("situation_text", ""),
			"distortion": int(encounter.get("distortion_options", [{"id": 0}])[0].get("id", 0)),
			"damage": 0,
		}
	if skill_cards.has(key):
		card_type = CogData.CardType.SKILL
		card_info = skill_cards[key]
		targets_distortion = card_info["targets"]
		effect_value = card_info["effect_value"]
	elif crisis_cards.has(key):
		card_type = CogData.CardType.CRISIS
		card_info = crisis_cards[key]
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
		sb.bg_color = Color(
			lerpf(CARD_CREAM.r, c.r, 0.16),
			lerpf(CARD_CREAM.g, c.g, 0.14),
			lerpf(CARD_CREAM.b, c.b, 0.12),
			0.99
		)
		sb.border_color = Color(
			lerpf(c.r, CARD_GREEN.r, 0.20),
			lerpf(c.g, CARD_GREEN.g, 0.20),
			lerpf(c.b, CARD_GREEN.b, 0.20),
			0.92
		)
	else:
		sb.bg_color = CARD_CREAM_SOFT
		sb.border_color = CARD_TERRACOTTA
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(20)
	sb.shadow_color = Color(0.38, 0.31, 0.24, 0.18)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
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
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", CARD_TEXT)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	# Distortion / type badge
	var type_lbl := Label.new()
	type_lbl.name = "TypeLabel"
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 11)
	type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if card_type == CogData.CardType.SKILL:
		type_lbl.text = "【技能】"
		type_lbl.add_theme_color_override("font_color", CARD_GREEN)
	else:
		var d_name: String = CogData.distortion_name(distortion_type)
		type_lbl.text = "【危机卡｜%s】" % d_name
		type_lbl.add_theme_color_override("font_color", CARD_TERRACOTTA)
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
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", CARD_MUTED)
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
		val_lbl.text = "+%d 稳定收益" % effect_value
		val_lbl.add_theme_color_override("font_color", CARD_GREEN)
	else:
		val_lbl.text = "七步练习入口"
		val_lbl.add_theme_color_override("font_color", CARD_BLUE)
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
	if card_type != CogData.CardType.SKILL:
		return
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
