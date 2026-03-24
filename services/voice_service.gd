## VoiceService — records microphone, classifies locally via 7-dim DTW.
## Calibration: record 4 samples each → verification → game.
extends Node

signal voice_result(category: String)
signal voice_failed(reason: String)
signal recording_started
signal recording_stopped
signal calibration_progress(word: String, count: int, needed: int)
signal calibration_verify(word: String)
signal calibration_verify_result(word: String, passed: bool)
signal calibration_done
signal calibration_sample_collected(word: String, count: int, frames: PackedVector2Array)

const ClassifierScript := preload("res://services/voice_classifier.gd")
const RECORD_MAX := 1.8   # auto-stop after this many seconds
const RECORD_MIN_FRAMES := 13230  # 0.3s at 44100 Hz — minimum valid recording
const SAMPLES_NEEDED := 4
const VERIFY_PASSES := 2      # 2 consecutive correct passes per word
const MAX_VERIFY_FAILS := 3   # re-record word if this many failures in verify

const WORD_FACT := "fact"
const WORD_THOUGHT := "thought"
const WORDS := [WORD_FACT, WORD_THOUGHT]
const WORD_LABELS := {
	WORD_FACT: "事实",
	WORD_THOUGHT: "想法",
}

enum Phase { IDLE, COLLECTING, VERIFYING }
enum CalibrationMode { REFINE, RESET }

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
var _calibration_mode: int = CalibrationMode.REFINE
var _baseline_templates: Dictionary = {}
var _session_samples: Dictionary = {}
var _session_classifier: RefCounted
var _in_recollect: bool = false          # true when re-collecting after too many verify fails
var _recollect_verify_word: String = ""  # which word to re-verify after re-collection

func is_recording() -> bool:
	return _recording

func is_calibrating() -> bool:
	return _calibrating

func has_calibration() -> bool:
	return _classifier != null and _classifier.is_model_ready()

func get_calib_phase() -> int:
	return _calib_phase

func get_calibration_status() -> Dictionary:
	if _classifier == null:
		return {"ready": false, "reason": "classifier unavailable"}
	var errors: PackedStringArray = _classifier.validate_model()
	return {
		"ready": errors.is_empty(),
		"reason": "" if errors.is_empty() else errors[0],
		"errors": errors,
	}

func _ready() -> void:
	_classifier = ClassifierScript.new()
	_classifier.load_templates()
	_setup_audio()
	if _classifier.is_model_ready():
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
		voice_failed.emit("没有检测到声音，请再试一次")
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
	if not has_calibration():
		voice_failed.emit("请先校准语音")
		return
	var res: Dictionary = _classifier.classify(frames)
	var result: String = res.get("result", "")
	var conf: float = res.get("confidence", 0.0)
	if result == "":
		voice_failed.emit("未识别 (%.0f%%)" % [conf * 100.0])
		return
	print("[VoiceService] Result: %s (conf=%.1f%%)" % [result, conf * 100.0])
	voice_result.emit(result)

## ---- Calibration Flow ----
## Phase 1 (COLLECTING): Record 4×fact + 4×thought into session data
## Phase 2 (VERIFYING): Classify probe samples against the staged session model
## Only commit the staged model after both words pass verification

func start_calibration(reset: bool = true) -> void:
	_calibrating = true
	_calibration_mode = CalibrationMode.RESET if reset else CalibrationMode.REFINE
	_baseline_templates = {} if reset else _classifier.get_templates_copy()
	if _calibration_mode == CalibrationMode.REFINE and not _classifier.is_model_ready():
		_baseline_templates = {}
	_reset_session_samples()
	_rebuild_session_classifier()
	_calib_phase = Phase.COLLECTING
	_in_recollect = false
	_recollect_verify_word = ""
	_begin_collect_for_word(WORD_FACT)
	print("[VoiceService] Calibration: say \"事实\" (%d times)" % SAMPLES_NEEDED)

func _process_calibration(frames: PackedVector2Array) -> void:
	if _calib_phase == Phase.COLLECTING:
		_on_collect_sample(frames)
	elif _calib_phase == Phase.VERIFYING:
		_on_verify_sample(frames)

func _on_collect_sample(frames: PackedVector2Array) -> void:
	var staged_templates: Dictionary = _build_templates_for_word(_calib_word, frames)
	if staged_templates.is_empty():
		voice_failed.emit("录音特征不足，请换个更清晰的发音再试一次")
		return
	_session_samples[_calib_word].append({
		"frames": frames,
		"templates": staged_templates,
	})
	_rebuild_session_classifier()
	_calib_step = _session_samples[_calib_word].size()
	var word_cn: String = _word_to_cn(_calib_word)
	calibration_sample_collected.emit(word_cn, _calib_step, frames)
	print("[VoiceService] Collected %s %d/%d" % [word_cn, _calib_step, SAMPLES_NEEDED])
	if _calib_step < SAMPLES_NEEDED:
		calibration_progress.emit(word_cn, _calib_step, SAMPLES_NEEDED)
	elif _in_recollect:
		# Finished re-collecting after too many verification failures — go back to verify same word
		_in_recollect = false
		var target := _recollect_verify_word
		_recollect_verify_word = ""
		_begin_verification_for_word(target)
		print("[VoiceService] Re-collected \"%s\", resuming verification" % _word_to_cn(target))
	elif _calib_word == WORD_FACT:
		_begin_collect_for_word(WORD_THOUGHT)
		print("[VoiceService] Now say \"想法\"")
	else:
		_begin_verification_for_word(WORD_FACT)
		print("[VoiceService] Verify: say \"事实\" (%d times)" % VERIFY_PASSES)

func _on_verify_sample(frames: PackedVector2Array) -> void:
	if _session_classifier == null or not _session_classifier.is_model_ready():
		voice_failed.emit("当前训练模型不可用，请重新采集样本")
		_in_recollect = false
		_recollect_verify_word = ""
		_begin_collect_for_word(WORD_FACT)
		return
	var res: Dictionary = _session_classifier.classify(frames)
	var got: String = res.get("result", "")
	var conf: float = res.get("confidence", 0.0)
	var n_fact: int = _session_classifier.get_fact_count()
	var n_thought: int = _session_classifier.get_thought_count()
	var expected_cn: String = _word_to_cn(_verify_word)
	var got_cn: String = _word_to_cn(got)
	print("[VoiceService] Verify: expected=%s got=%s conf=%.1f%% pass=%d/%d fail=%d/%d staged=%d+%d" % [
		expected_cn, got_cn, conf * 100.0, _verify_pass_count, VERIFY_PASSES,
		_verify_fail_count, MAX_VERIFY_FAILS, n_fact, n_thought])

	if got == _verify_word:
		_verify_pass_count += 1
		calibration_verify_result.emit(expected_cn, true)
		if _verify_pass_count >= VERIFY_PASSES:
			if _verify_word == WORD_FACT:
				_begin_verification_for_word(WORD_THOUGHT)
				print("[VoiceService] \"事实\" verified! Now verify \"想法\"")
			else:
				if not _commit_session_model():
					return
				_calibrating = false
				_calib_phase = Phase.IDLE
				calibration_done.emit()
				print("[VoiceService] Calibration complete! (fact=%d thought=%d templates)" % [
					_classifier.get_fact_count(), _classifier.get_thought_count()])
		else:
			calibration_verify.emit(expected_cn)
	else:
		_verify_pass_count = 0
		_verify_fail_count += 1
		# Add this misidentified recording (with correct label) to training set and retrain
		var new_templates: Dictionary = _build_templates_for_word(_verify_word, frames)
		if not new_templates.is_empty():
			_session_samples[_verify_word].append({
				"frames": frames,
				"templates": new_templates,
			})
			_rebuild_session_classifier()
			print("[VoiceService] Added failed sample to training set, retrained (fact=%d thought=%d)" % [
				_session_classifier.get_fact_count(), _session_classifier.get_thought_count()])
		calibration_verify_result.emit(expected_cn, false)
		if _verify_fail_count >= MAX_VERIFY_FAILS:
			print("[VoiceService] Too many verify failures (%d), re-collecting \"%s\"" % [
				_verify_fail_count, expected_cn])
			_session_samples[_verify_word].clear()
			_rebuild_session_classifier()
			_in_recollect = true
			_recollect_verify_word = _verify_word
			_begin_collect_for_word(_verify_word)
		else:
			calibration_verify.emit(expected_cn)

func reset_calibration() -> void:
	_calibrating = false
	_calib_phase = Phase.IDLE
	_in_recollect = false
	_recollect_verify_word = ""
	_classifier.clear_templates()
	_baseline_templates = {}
	_reset_session_samples()
	_rebuild_session_classifier()
	for path in ["user://voice_templates.dat", "user://voice_templates_v2.dat", "user://voice_templates_v3.dat"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("[VoiceService] Calibration data cleared")

func _begin_collect_for_word(word: String) -> void:
	_calib_phase = Phase.COLLECTING
	_calib_word = word
	_calib_step = _session_samples[word].size()
	calibration_progress.emit(_word_to_cn(word), _calib_step, SAMPLES_NEEDED)

func _begin_verification_for_word(word: String) -> void:
	_calib_phase = Phase.VERIFYING
	_verify_word = word
	_verify_pass_count = 0
	_verify_fail_count = 0
	calibration_verify.emit(_word_to_cn(word))

func _reset_session_samples() -> void:
	_session_samples = {
		WORD_FACT: [],
		WORD_THOUGHT: [],
	}

func _rebuild_session_classifier() -> void:
	_session_classifier = ClassifierScript.new()
	var templates := {
		"fact": _collect_word_templates(WORD_FACT),
		"thought": _collect_word_templates(WORD_THOUGHT),
	}
	if not _session_classifier.set_templates(templates):
		_session_classifier.clear_templates()

func _collect_word_templates(word: String) -> Array:
	var templates: Array = []
	var baseline_word: Array = _baseline_templates.get(word, [])
	for tmpl in baseline_word:
		templates.append(tmpl)
	for entry in _session_samples.get(word, []):
		var entry_templates: Dictionary = entry.get("templates", {})
		var sample_templates: Array = entry_templates.get(word, [])
		for tmpl in sample_templates:
			templates.append(tmpl)
	var max_templates: int = _session_classifier.get_max_templates_per_class()
	while templates.size() > max_templates:
		templates.pop_front()
	return templates

func _build_templates_for_word(word: String, frames: PackedVector2Array) -> Dictionary:
	var builder = ClassifierScript.new()
	builder.add_template(word, frames)
	var templates: Dictionary = builder.get_templates_copy()
	if (templates.get(word, []) as Array).is_empty():
		return {}
	return templates

func _commit_session_model() -> bool:
	var templates := {
		"fact": _collect_word_templates(WORD_FACT),
		"thought": _collect_word_templates(WORD_THOUGHT),
	}
	if not _classifier.set_templates(templates):
		voice_failed.emit("模型保存失败，请重新校准")
		return false
	if not _classifier.is_model_ready():
		voice_failed.emit("模型校验失败，请重新校准")
		return false
	_classifier.save_templates()
	_baseline_templates = _classifier.get_templates_copy()
	return true

func _word_to_cn(word: String) -> String:
	return WORD_LABELS.get(word, "未识别")
