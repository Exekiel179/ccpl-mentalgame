## HealthComponent — reusable mental-health-points tracker.
class_name HealthComponent
extends Node

signal health_changed(current: int, max_health: int)
signal health_depleted

@export var max_health: int = 100
var current_health: int

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> void:
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		health_depleted.emit()

func heal(amount: int) -> void:
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func get_percent() -> float:
	return float(current_health) / float(max_health)

func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
