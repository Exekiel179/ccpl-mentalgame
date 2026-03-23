## EventBus — global signal hub for loose coupling between systems.
extends Node

# Game flow
signal game_started
signal game_over(final_score: int)
signal game_won
signal scene_change_requested(scene_path: String)

# Health
signal health_changed(current: int, max_health: int)
signal health_depleted

# Gameplay
signal sentence_answered(correct: bool)
signal sentence_timed_out
signal score_changed(new_score: int)
signal combo_changed(combo: int)

# Background image
signal background_image_loaded(texture: Texture2D)
signal background_image_failed(reason: String)
