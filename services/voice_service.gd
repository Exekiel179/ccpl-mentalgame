## VoiceService — records microphone, classifies locally via 7-dim DTW.
## Calibration: record 3 samples each → verification → game.
extends Node

signal voice_result(category: String)
signal voice_failed(reason: String)
signal recording_started
signal recording_stopped
signal calibration_progress(word: String, count: int, needed: int)
signal calibration_verify(word: String)
signal calibration_verify_result(word: String, passed: bool)
signal calibration_done

const ClassifierScript := preload("res://services/voice_classifier.gd")
const RECORD_MAX := 1.8   # auto-stop after this many seconds
const RECORD_MIN_FRAMES := 13230  # 0.3s at 44100 Hz — minimum valid recording
const SAMPLES_NEEDED := 4
const VERIFY_PASSES := 2      # 2 consecutive correct passes per word
const MAX_VERIFY_FAILS := 3   # re-record word if this many failures in verify

enum Phase { IDLE, COLLECTING, VERIFYING }

var _mic_player: AudioStreamPlayer
var _capture: AudioEffectCapture
var _recording: bool = false
var _record_time: float = 0.0
var _classifier: RefCounted

## Calibration state
var _calibrating: bool = false
var _calib_word: String = ""
var _calib_step: int = 0
var _calib_phase: int = Phase.IDLE
var _verify_word: String = ""
var _verify_pass_count: int = 0   # consecutive correct
var _verify_fail_count: int = 0   # total failures for this word

func is_recording() -> bool:
	return _recording

func is_calibrating() -> bool:
	return _calibrating

func has_calibration() -> bool:
	return _classifier.has_templates()

func get_calib_phase() -> int:
	return _calib_phase

func _ready() -> void:
	_classifier = ClassifierScript.new()
	_classifier.load_templates()
	_setup_audio()
	if _classifier.has_templates():
		print("[VoiceService] Calibration data loaded")
	else:
		print("[VoiceService] No calibration — required before play")

func _setup_audio() -> void:
	var bus_idx := -1
	for i in AudioServer.bus_count:
		if AudioServer.get_bus_name(i) == "VoiceCapture":
			bus_idx = i
			break
	if bus_idx == -1:
		bus_idx = AudioServer.get_bus_count()
		AudioServer.add_bus(bus_idx)
		AudioServer.set_bus_name(bus_idx, "VoiceCapture")
		AudioServer.set_bus_mute(bus_idx, true)
		var effect := AudioEffectCapture.new()
		effect.buffer_length = 3.0   # must hold at least RECORD_MAX seconds
		AudioServer.add_bus_effect(bus_idx, effect)
	_capture = AudioServer.get_bus_effect(bus_idx, 0) as AudioEffectCapture
	_mic_player = AudioStreamPlayer.new()
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = &"VoiceCapture"
	add_child(_mic_player)

func start_recording() -> void:
	if _recording:
		return
	_recording = true
	_record_time = 0.0
	_capture.clear_buffer()
	_mic_player.play()
	recording_started.emit()

func stop_recording() -> void:
	if not _recording:
		return
	_recording = false
	_mic_player.stop()
	recording_stopped.emit()
	var frames := _capture.get_buffer(_capture.get_frames_available())
	print("[VoiceService] Recorded %d frames" % frames.size())
	if frames.size() < RECORD_MIN_FRAMES:
		voice_failed.emit("\u6ca1\u6709\u68c0\u6d4b\u5230\u58f0\u97f3\uff0c\u8bf7\u518d\u8bd5\u4e00\u6b21")
		return
	if _calibrating:
		_process_calibration(frames)
	else:
		_classify_gameplay(frames)

func _process(delta: float) -> void:
	if _recording:
		_record_time += delta
		if _record_time >= RECORD_MAX:
			stop_recording()

func _classify_gameplay(frames: PackedVector2Array) -> void:
	if not _classifier.has_templates():
		voice_failed.emit("\u8bf7\u5148\u6821\u51c6\u8bed\u97f3")
		return
	var res: Dictionary = _classifier.classify(frames)
	var result: String = res.get("result", "")
	var conf: float = res.get("confidence", 0.0)
	if result == "":
		voice_failed.emit("\u672a\u8bc6\u522b (%.0f%%)" % [conf * 100.0])
		return
	print("[VoiceService] Result: %s (conf=%.1f%%)" % [result, conf * 100.0])
	voice_result.emit(result)

## ---- Calibration Flow ----
## Phase 1 (COLLECTING): Record 3×fact + 3×thought
## Phase 2 (VERIFYING): Must correctly classify 1×fact + 1×thought
## If verify fails → re-record that word and re-verify

func start_calibration(reset: bool = true) -> void:
	_calibrating = true
	if reset:
		_classifier.clear_templates()
	_calib_phase = Phase.COLLECTING
	_calib_word = "fact"
	_calib_step = 0
	calibration_progress.emit("\u4e8b\u5b9e", 0, SAMPLES_NEEDED)
	print("[VoiceService] Calibration: say \"\u4e8b\u5b9e\" (%d times)" % SAMPLES_NEEDED)

func _process_calibration(frames: PackedVector2Array) -> void:
	if _calib_phase == Phase.COLLECTING:
		_on_collect_sample(frames)
	elif _calib_phase == Phase.VERIFYING:
		_on_verify_sample(frames)

func _on_collect_sample(frames: PackedVector2Array) -> void:
	_classifier.add_template(_calib_word, frames)
	_calib_step += 1
	var word_cn: String = "\u4e8b\u5b9e" if _calib_word == "fact" else "\u60f3\u6cd5"
	print("[VoiceService] Collected %s %d/%d" % [word_cn, _calib_step, SAMPLES_NEEDED])
	if _calib_step < SAMPLES_NEEDED:
		calibration_progress.emit(word_cn, _calib_step, SAMPLES_NEEDED)
	elif _calib_word == "fact":
		_calib_word = "thought"
		_calib_step = 0
		calibration_progress.emit("\u60f3\u6cd5", 0, SAMPLES_NEEDED)
		print("[VoiceService] Now say \"\u60f3\u6cd5\"")
	else:
		# All collected → start verification
		_calib_phase = Phase.VERIFYING
		_verify_word = "fact"
		_verify_pass_count = 0
		_verify_fail_count = 0
		calibration_verify.emit("\u4e8b\u5b9e")
		print("[VoiceService] Verify: say \"\u4e8b\u5b9e\" (%d times)" % VERIFY_PASSES)

func _on_verify_sample(frames: PackedVector2Array) -> void:
	var res: Dictionary = _classifier.classify(frames)
	var got: String = res.get("result", "")
	var conf: float = res.get("confidence", 0.0)
	# NOTE: templates are NOT modified during verification — only pure collected
	# samples are used. Adding failed/ambiguous verify samples contaminated the
	# model (caused fact=6 thought=17 imbalance and cross-class confusion).
	var n_fact: int = _classifier.get_fact_count()
	var n_thought: int = _classifier.get_thought_count()
	var expected_cn: String = "\u4e8b\u5b9e" if _verify_word == "fact" else "\u60f3\u6cd5"
	var got_cn: String = "\u4e8b\u5b9e" if got == "fact" else ("\u60f3\u6cd5" if got == "thought" else "\u672a\u8bc6\u522b")
	print("[VoiceService] Verify: expected=%s got=%s conf=%.1f%% pass=%d/%d fail=%d/%d" % [
		expected_cn, got_cn, conf * 100.0, _verify_pass_count, VERIFY_PASSES,
		_verify_fail_count, MAX_VERIFY_FAILS])

	if got == _verify_word:
		_verify_pass_count += 1
		calibration_verify_result.emit(expected_cn, true)
		if _verify_pass_count >= VERIFY_PASSES:
			if _verify_word == "fact":
				_verify_word = "thought"
				_verify_pass_count = 0
				_verify_fail_count = 0
				calibration_verify.emit("\u60f3\u6cd5")
				print("[VoiceService] \"\u4e8b\u5b9e\" verified! Now verify \"\u60f3\u6cd5\"")
			else:
				_calibrating = false
				_calib_phase = Phase.IDLE
				_classifier.save_templates()
				calibration_done.emit()
				print("[VoiceService] Calibration complete! (fact=%d thought=%d templates)" % [
					n_fact, n_thought])
		else:
			calibration_verify.emit(expected_cn)
	else:
		_verify_pass_count = 0
		_verify_fail_count += 1
		calibration_verify_result.emit(expected_cn, false)
		if _verify_fail_count >= MAX_VERIFY_FAILS:
			# Collected samples for this word are poor quality — re-record it
			print("[VoiceService] Too many verify failures (%d), re-collecting \"%s\"" % [
				_verify_fail_count, expected_cn])
			_classifier.remove_all_templates(_verify_word)
			_calib_phase = Phase.COLLECTING
			_calib_word = _verify_word
			_calib_step = 0
			_verify_fail_count = 0
			_verify_pass_count = 0
			calibration_progress.emit(expected_cn, 0, SAMPLES_NEEDED)
		else:
			calibration_verify.emit(expected_cn)

func reset_calibration() -> void:
	_calibrating = false
	_calib_phase = Phase.IDLE
	_classifier.clear_templates()
	for path in ["user://voice_templates.dat", "user://voice_templates_v2.dat", "user://voice_templates_v3.dat"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("[VoiceService] Calibration data cleared")
