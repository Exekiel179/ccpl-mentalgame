## FogLayer — fog of war effect.
## Camera2D is a child of Player so the player is always at screen center.
## The fog hole therefore stays at UV(0.5, 0.5) with no per-frame updates.
extends CanvasLayer

const FOG_SHADER = preload("res://game/fog.gdshader")

func _ready() -> void:
	layer = 5
	var fog_rect := ColorRect.new()
	fog_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = FOG_SHADER
	fog_rect.material = mat
	add_child(fog_rect)
