## GameManager — single source of truth for game state.
extends Node

const MAIN_MENU_SCENE   := "res://ui/main_menu.tscn"
const KNOWLEDGE_SCENE   := "res://ui/knowledge_screen.tscn"
const GAME_SCENE        := "res://game/game_scene.tscn"
const VOICE_CALIB_SCENE := "res://ui/voice_calibration.tscn"
const VOICE_TEMPLATE_PATH := "user://voice_templates_v3.dat"

var current_scenario: String = "学业压力"
var current_level: int = 1
var high_score: int = 0
var last_score: int = 0
var last_stats: Dictionary = {}
var difficulty: int = 1  # 0=easy, 1=normal, 2=hard

func has_voice_calibration() -> bool:
	return FileAccess.file_exists(VOICE_TEMPLATE_PATH)

func go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func go_to_knowledge() -> void:
	get_tree().change_scene_to_file(KNOWLEDGE_SCENE)

func go_to_win() -> void:
	get_tree().change_scene_to_file("res://ui/game_win.tscn")

func start_game(scenario: String = "学业压力") -> void:
	current_scenario = scenario
	if current_level <= 0:
		current_level = 1
	# Always show calibration screen — player can skip if model exists
	get_tree().change_scene_to_file(VOICE_CALIB_SCENE)

func update_high_score(score: int) -> void:
	last_score = score
	if score > high_score:
		high_score = score
