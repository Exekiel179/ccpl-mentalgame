## GameManager — single source of truth for game state.
extends Node

const MAIN_MENU_SCENE      := "res://ui/main_menu.tscn"
const KNOWLEDGE_SCENE      := "res://ui/knowledge_screen.tscn"
const KNOWLEDGE_MATCH_SCENE := "res://ui/knowledge_match_screen.tscn"
const GAME_SCENE           := "res://game/game_scene.tscn"
const VOICE_CALIB_SCENE    := "res://ui/voice_calibration.tscn"
const VoiceServiceScript   := preload("res://services/voice_service.gd")
const CARD_GAME_SCENE      := "res://game/card_game/card_game_scene.tscn"

enum GameMode { MAZE, CARD }

var current_scenario: String = "学业压力"
var current_level: int = 1
var high_score: int = 0
var last_score: int = 0
var last_stats: Dictionary = {}
var difficulty: int = 1  # 0=easy, 1=normal, 2=hard
var current_mode: int = GameMode.MAZE
var knowledge_return_mode: int = GameMode.MAZE

func get_voice_calibration_status() -> Dictionary:
	var probe = VoiceServiceScript.new()
	add_child(probe)
	var status: Dictionary = probe.get_calibration_status()
	probe.queue_free()
	return status

func has_voice_calibration() -> bool:
	return bool(get_voice_calibration_status().get("ready", false))

func go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func go_to_knowledge(mode: int = -1) -> void:
	if mode == -1:
		knowledge_return_mode = current_mode
	else:
		knowledge_return_mode = mode
	get_tree().change_scene_to_file(KNOWLEDGE_SCENE)

func go_to_knowledge_match() -> void:
	get_tree().change_scene_to_file(KNOWLEDGE_MATCH_SCENE)

func go_to_win() -> void:
	get_tree().change_scene_to_file("res://ui/game_win.tscn")

func go_to_game_over() -> void:
	get_tree().change_scene_to_file("res://ui/game_over.tscn")

func start_game(scenario: String = "学业压力") -> void:
	current_scenario = scenario
	current_mode = GameMode.MAZE
	if current_level <= 0:
		current_level = 1
	# Always show calibration screen — player can skip if model exists
	get_tree().change_scene_to_file(VOICE_CALIB_SCENE)

func continue_game(scenario: String = "学业压力") -> void:
	current_scenario = scenario
	current_mode = GameMode.MAZE
	if current_level <= 0:
		current_level = 1
	get_tree().change_scene_to_file(GAME_SCENE)

func start_card_game(scenario: String = "学业压力") -> void:
	current_scenario = scenario
	current_mode = GameMode.CARD
	get_tree().change_scene_to_file(CARD_GAME_SCENE)

func retry_current_mode() -> void:
	if current_mode == GameMode.CARD:
		start_card_game(current_scenario)
	else:
		start_game(current_scenario)

func save_mode_stats(stats: Dictionary) -> void:
	last_stats = stats.duplicate(true)
	last_stats["mode"] = current_mode

func update_high_score(score: int) -> void:
	last_score = score
	if score > high_score:
		high_score = score
