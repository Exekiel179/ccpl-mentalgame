## FogLayer — therapeutic exploration overlay with dissolving cloud cover.
extends CanvasLayer

const FOG_SHADER := preload("res://game/fog.gdshader")
const MazeBuilder := preload("res://game/maze_builder.gd")
const EXPLORED_TEXTURE_SIZE := Vector2i(1024, 640)

var _fog_rect: ColorRect
var _fog_material: ShaderMaterial
var _exploration_tween: Tween
var _explored_image: Image
var _explored_texture: ImageTexture
var _last_reveal_uv: Vector2 = Vector2(0.5, 0.5)

func _ready() -> void:
	layer = 5
	_fog_rect = ColorRect.new()
	_fog_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog_material = ShaderMaterial.new()
	_fog_material.shader = FOG_SHADER
	_fog_rect.material = _fog_material
	add_child(_fog_rect)
	visible = false
	_configure_exploration_mask()
	_update_shader_layout_params()
	reset_exploration()
	set_combo_visibility(0)
	set_reveal_screen_position(get_viewport().get_visible_rect().size * 0.5)

func _configure_exploration_mask() -> void:
	_explored_image = Image.create(EXPLORED_TEXTURE_SIZE.x, EXPLORED_TEXTURE_SIZE.y, false, Image.FORMAT_RF)
	_explored_texture = ImageTexture.create_from_image(_explored_image)
	if _fog_material:
		_fog_material.set_shader_parameter("explored_mask", _explored_texture)

func _update_shader_layout_params() -> void:
	if _fog_material == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var maze_origin := Vector2(MazeBuilder.OFFSET_X, MazeBuilder.OFFSET_Y)
	var maze_size := Vector2((MazeBuilder.ROOMS_COLS * 2 + 1) * MazeBuilder.CELL, (MazeBuilder.ROOMS_ROWS * 2 + 1) * MazeBuilder.CELL)
	_fog_material.set_shader_parameter("canvas_offset", viewport_size * 0.5)
	_fog_material.set_shader_parameter("maze_origin", maze_origin)
	_fog_material.set_shader_parameter("maze_size", maze_size)

func reset_exploration() -> void:
	if _explored_image == null or _explored_texture == null:
		return
	_explored_image.fill(Color.BLACK)
	_explored_texture.update(_explored_image)
	if _fog_material:
		_fog_material.set_shader_parameter("completion_amount", 0.0)
		_fog_material.set_shader_parameter("reveal_boost", 0.0)

func set_reveal_screen_position(screen_pos: Vector2) -> void:
	if _fog_material == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	_update_shader_layout_params()
	var reveal_uv := Vector2(
		clampf(screen_pos.x / viewport_size.x, 0.0, 1.0),
		clampf(screen_pos.y / viewport_size.y, 0.0, 1.0)
	)
	_last_reveal_uv = reveal_uv
	_fog_material.set_shader_parameter("reveal_center", reveal_uv)

func stamp_exploration(world_pos: Vector2, strength: float = 0.22, radius_world: float = 46.0) -> void:
	if _explored_image == null or _explored_texture == null:
		return
	var maze_origin := Vector2(MazeBuilder.OFFSET_X, MazeBuilder.OFFSET_Y)
	var maze_size := Vector2((MazeBuilder.ROOMS_COLS * 2 + 1) * MazeBuilder.CELL, (MazeBuilder.ROOMS_ROWS * 2 + 1) * MazeBuilder.CELL)
	if maze_size.x <= 0.0 or maze_size.y <= 0.0:
		return
	var uv := Vector2(
		(world_pos.x - maze_origin.x) / maze_size.x,
		(world_pos.y - maze_origin.y) / maze_size.y
	)
	if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
		return
	var center := Vector2(uv.x * float(EXPLORED_TEXTURE_SIZE.x - 1), uv.y * float(EXPLORED_TEXTURE_SIZE.y - 1))
	var radius_px := maxi(6, int(round(radius_world / maze_size.x * float(EXPLORED_TEXTURE_SIZE.x))))
	var radius_sq := float(radius_px * radius_px)
	var min_x := maxi(0, int(floor(center.x)) - radius_px)
	var max_x := mini(EXPLORED_TEXTURE_SIZE.x - 1, int(ceil(center.x)) + radius_px)
	var min_y := maxi(0, int(floor(center.y)) - radius_px)
	var max_y := mini(EXPLORED_TEXTURE_SIZE.y - 1, int(ceil(center.y)) + radius_px)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var delta := Vector2(float(x) - center.x, float(y) - center.y)
			var dist_sq := delta.length_squared()
			if dist_sq > radius_sq:
				continue
			var falloff: float = 1.0 - smoothstep(0.0, 1.0, sqrt(dist_sq) / float(radius_px))
			var current: float = _explored_image.get_pixel(x, y).r
			var value: float = max(current, strength * falloff)
			_explored_image.set_pixel(x, y, Color(value, 0.0, 0.0, 1.0))
	_explored_texture.update(_explored_image)

func set_combo_visibility(combo: int) -> void:
	if _fog_material == null:
		return
	var combo_clamped: int = clampi(combo, 0, 15)
	var ratio := float(combo_clamped) / 15.0
	var radius: float = lerpf(0.24, 0.38, ratio)
	var strength: float = lerpf(0.56, 0.22, ratio)
	var clear_core: float = lerpf(0.16, 0.24, ratio)
	var softness: float = lerpf(0.09, 0.14, ratio)
	_fog_material.set_shader_parameter("radius", radius)
	_fog_material.set_shader_parameter("cloud_strength", strength)
	_fog_material.set_shader_parameter("clear_core", clear_core)
	_fog_material.set_shader_parameter("softness", softness)

func pulse_exploration() -> void:
	if _fog_material == null:
		return
	if _exploration_tween:
		_exploration_tween.kill()
	_exploration_tween = create_tween()
	_exploration_tween.tween_method(_set_reveal_boost, 0.0, 0.14, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_exploration_tween.tween_method(_set_reveal_boost, 0.14, 0.0, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func clear_all_shadows() -> void:
	if _fog_material == null:
		return
	if _exploration_tween:
		_exploration_tween.kill()
	var tw := create_tween()
	tw.tween_method(_set_completion_amount, 0.0, 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(_set_reveal_boost, 0.0, 0.32, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _set_reveal_boost(value: float) -> void:
	if _fog_material:
		_fog_material.set_shader_parameter("reveal_boost", value)

func _set_completion_amount(value: float) -> void:
	if _fog_material:
		_fog_material.set_shader_parameter("completion_amount", value)
