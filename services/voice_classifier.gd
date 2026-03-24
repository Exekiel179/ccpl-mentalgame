## VoiceClassifier — dual-method classifier for "事实" vs "想法".
## Method 1: Global statistical features (fixed-length vector, no alignment needed)
## Method 2: Frame-level DTW (temporal shape matching)
## Final decision = weighted combination of both.
extends RefCounted

const FRAME_SIZE := 256
const SAVE_PATH := "user://voice_templates_v3.dat"
const MAX_TEMPLATES_PER_CLASS := 6
const GLOBAL_FEATURE_COUNT := 20
const FRAME_FEATURE_COUNT := 5

func get_max_templates_per_class() -> int:
	return MAX_TEMPLATES_PER_CLASS

var _templates_fact: Array = []    # Array of {global: PackedFloat32Array, frames: Array}
var _templates_thought: Array = []

func has_templates() -> bool:
	return _templates_fact.size() >= 1 and _templates_thought.size() >= 1

func is_model_ready() -> bool:
	return validate_model().is_empty()

func get_fact_count() -> int:
	return _templates_fact.size()

func get_thought_count() -> int:
	return _templates_thought.size()

func add_template(category: String, frames: PackedVector2Array) -> void:
	var t: Dictionary = _make_template(frames)
	if t.is_empty():
		return
	if category == "fact":
		_templates_fact.append(t)
		while _templates_fact.size() > MAX_TEMPLATES_PER_CLASS:
			_templates_fact.pop_front()
	elif category == "thought":
		_templates_thought.append(t)
		while _templates_thought.size() > MAX_TEMPLATES_PER_CLASS:
			_templates_thought.pop_front()

func remove_last_template(category: String) -> void:
	if category == "fact" and _templates_fact.size() > 0:
		_templates_fact.pop_back()
	elif category == "thought" and _templates_thought.size() > 0:
		_templates_thought.pop_back()

func remove_all_templates(category: String) -> void:
	if category == "fact":
		_templates_fact.clear()
	elif category == "thought":
		_templates_thought.clear()

func get_templates_copy() -> Dictionary:
	return {
		"fact": _duplicate_templates(_templates_fact),
		"thought": _duplicate_templates(_templates_thought),
	}

func set_templates(templates: Dictionary) -> bool:
	var fact_templates: Array = _sanitize_templates(templates.get("fact", []))
	var thought_templates: Array = _sanitize_templates(templates.get("thought", []))
	if not _validate_template_list(fact_templates, "fact").is_empty():
		return false
	if not _validate_template_list(thought_templates, "thought").is_empty():
		return false
	_templates_fact = _duplicate_templates(fact_templates)
	_templates_thought = _duplicate_templates(thought_templates)
	return true

func validate_model() -> PackedStringArray:
	var errors := PackedStringArray()
	errors.append_array(_validate_template_list(_templates_fact, "fact"))
	errors.append_array(_validate_template_list(_templates_thought, "thought"))
	if _templates_fact.is_empty():
		errors.append("fact templates missing")
	if _templates_thought.is_empty():
		errors.append("thought templates missing")
	if has_templates() and abs(_templates_fact.size() - _templates_thought.size()) > 4:
		errors.append("template counts imbalanced")
	return errors

func classify(frames: PackedVector2Array) -> Dictionary:
	if not is_model_ready():
		return {"result": "", "confidence": 0.0}
	var t: Dictionary = _make_template(frames)
	if t.is_empty():
		return {"result": "", "confidence": 0.0}
	# Method 1: Global feature distance
	var gf_fact := INF
	var gf_thought := INF
	for tmpl in _templates_fact:
		var d: float = _global_dist(t.global, tmpl.global)
		if d < gf_fact:
			gf_fact = d
	for tmpl in _templates_thought:
		var d: float = _global_dist(t.global, tmpl.global)
		if d < gf_thought:
			gf_thought = d
	# Method 2: DTW distance
	var dtw_fact := INF
	var dtw_thought := INF
	for tmpl in _templates_fact:
		var d: float = _dtw_multi(t.frames, tmpl.frames)
		if d < dtw_fact:
			dtw_fact = d
	for tmpl in _templates_thought:
		var d: float = _dtw_multi(t.frames, tmpl.frames)
		if d < dtw_thought:
			dtw_thought = d
	# Combine: normalize each method's scores, then average
	var gt: float = gf_fact + gf_thought + 0.0001
	var gf_score: float = gf_thought / gt  # higher = more likely fact
	var dt: float = dtw_fact + dtw_thought + 0.0001
	var dtw_score: float = dtw_thought / dt
	# Weighted average (global features weighted more since they're alignment-free)
	var combined: float = gf_score * 0.55 + dtw_score * 0.45
	var confidence: float = absf(combined - 0.5) * 2.0
	var result: String = "fact" if combined > 0.5 else "thought"
	print("[Classifier] global: f=%.3f t=%.3f | dtw: f=%.3f t=%.3f | combined=%.3f conf=%.1f%% -> %s" % [
		gf_fact, gf_thought, dtw_fact, dtw_thought, combined, confidence * 100.0, result])
	if confidence < 0.25:
		return {"result": "", "confidence": confidence}
	return {"result": result, "confidence": confidence}

func clear_templates() -> void:
	_templates_fact.clear()
	_templates_thought.clear()

## ---- Template Construction ----

func _make_template(raw_frames: PackedVector2Array) -> Dictionary:
	var n := raw_frames.size()
	if n < FRAME_SIZE * 3:
		return {}
	# Convert to mono
	var mono := PackedFloat32Array()
	mono.resize(n)
	for i in range(n):
		mono[i] = (raw_frames[i].x + raw_frames[i].y) * 0.5
	# Compute per-frame features
	var num_fr: int = int(floor(float(n) / float(FRAME_SIZE)))
	if num_fr < 3:
		return {}
	var f_energy := PackedFloat32Array(); f_energy.resize(num_fr)
	var f_zcr := PackedFloat32Array(); f_zcr.resize(num_fr)
	var f_hf := PackedFloat32Array(); f_hf.resize(num_fr)
	var f_band_lo := PackedFloat32Array(); f_band_lo.resize(num_fr)
	var f_band_mid := PackedFloat32Array(); f_band_mid.resize(num_fr)
	var f_band_hi := PackedFloat32Array(); f_band_hi.resize(num_fr)
	var f_peak := PackedFloat32Array(); f_peak.resize(num_fr)

	for i in range(num_fr):
		var off: int = i * FRAME_SIZE
		var energy := 0.0
		var zc := 0
		var hf_e := 0.0
		var pk := 0.0
		var lo_e := 0.0
		var mid_e := 0.0
		var hi_e := 0.0
		var prev_s: float = mono[off]
		# Simple 3-tap low-pass for band decomposition
		for j in range(FRAME_SIZE):
			var s: float = mono[off + j]
			energy += s * s
			if absf(s) > pk:
				pk = absf(s)
			# ZCR
			if j > 0 and ((s >= 0.0 and prev_s < 0.0) or (s < 0.0 and prev_s >= 0.0)):
				zc += 1
			# HF via first difference
			if j > 0:
				var diff: float = s - prev_s
				hf_e += diff * diff
			# Band energy: low (moving avg of 8), mid (diff of avg4-avg8), hi (diff of raw-avg4)
			if j >= 8:
				var avg8 := 0.0
				for k in range(8):
					avg8 += mono[off + j - k]
				avg8 /= 8.0
				var avg4 := 0.0
				for k in range(4):
					avg4 += mono[off + j - k]
				avg4 /= 4.0
				lo_e += avg8 * avg8
				mid_e += (avg4 - avg8) * (avg4 - avg8)
				hi_e += (s - avg4) * (s - avg4)
			prev_s = s
		f_energy[i] = sqrt(energy / float(FRAME_SIZE))
		f_zcr[i] = float(zc) / float(FRAME_SIZE)
		f_hf[i] = sqrt(hf_e / (energy + 0.0001))
		f_band_lo[i] = sqrt(lo_e / float(FRAME_SIZE))
		f_band_mid[i] = sqrt(mid_e / float(FRAME_SIZE))
		f_band_hi[i] = sqrt(hi_e / float(FRAME_SIZE))
		f_peak[i] = pk

	# Trim silence
	var max_e := 0.0001
	for i in f_energy.size():
		if f_energy[i] > max_e:
			max_e = f_energy[i]
	var thr := max_e * 0.06
	var si := 0
	while si < num_fr and f_energy[si] < thr:
		si += 1
	var ei := num_fr - 1
	while ei > si and f_energy[ei] < thr:
		ei -= 1
	if ei - si < 2:
		return {}
	var count: int = ei - si + 1

	# ---- Global features (20-dim) ----
	var g := PackedFloat32Array()
	# Stats for each of 7 raw features: mean + std = 14
	var arrays: Array = [f_energy, f_zcr, f_hf, f_band_lo, f_band_mid, f_band_hi, f_peak]
	for arr_idx in arrays.size():
		var arr: PackedFloat32Array = arrays[arr_idx]
		var mean := 0.0
		for k in range(si, ei + 1):
			mean += arr[k]
		mean /= float(count)
		var std := 0.0
		for k in range(si, ei + 1):
			std += (arr[k] - mean) * (arr[k] - mean)
		std = sqrt(std / float(count))
		g.append(mean)
		g.append(std)
	# Temporal shape: first-half vs second-half energy ratio
	var half: int = count / 2
	var first_e := 0.0
	var second_e := 0.0
	for k in range(si, si + half):
		first_e += f_energy[k]
	for k in range(si + half, ei + 1):
		second_e += f_energy[k]
	g.append(second_e / (first_e + 0.0001))
	# First-half vs second-half ZCR ratio
	var first_z := 0.0
	var second_z := 0.0
	for k in range(si, si + half):
		first_z += f_zcr[k]
	for k in range(si + half, ei + 1):
		second_z += f_zcr[k]
	g.append(second_z / (first_z + 0.0001))
	# Band ratio: hi / (lo + mid + 0.0001)
	var sum_lo := 0.0
	var sum_mid := 0.0
	var sum_hi := 0.0
	for k in range(si, ei + 1):
		sum_lo += f_band_lo[k]
		sum_mid += f_band_mid[k]
		sum_hi += f_band_hi[k]
	g.append(sum_hi / (sum_lo + sum_mid + 0.0001))
	g.append(sum_mid / (sum_lo + 0.0001))
	# Duration (normalized)
	g.append(float(count) / 50.0)
	# Energy peak position (0-1)
	var peak_idx := si
	for k in range(si, ei + 1):
		if f_energy[k] > f_energy[peak_idx]:
			peak_idx = k
	g.append(float(peak_idx - si) / float(count))
	if g.size() != GLOBAL_FEATURE_COUNT:
		push_warning("[Classifier] Unexpected global feature size: %d" % g.size())
		return {}

	# ---- Normalize global features ----
	# Packed arrays can throw on indexed writes if their size gets out of sync,
	# so duplicate the computed vector directly instead of copying element-by-element.
	var g_norm: PackedFloat32Array = g.duplicate()
	if g_norm.size() != GLOBAL_FEATURE_COUNT:
		push_warning("[Classifier] Global feature vector size mismatch: %d" % g_norm.size())
		return {}

	# ---- Frame features (5-dim) for DTW ----
	var maxes: Array = [0.0001, 0.0001, 0.0001, 0.0001, 0.0001]
	for k in range(si, ei + 1):
		if f_energy[k] > maxes[0]: maxes[0] = f_energy[k]
		if f_zcr[k] > maxes[1]: maxes[1] = f_zcr[k]
		if f_hf[k] > maxes[2]: maxes[2] = f_hf[k]
		if f_band_hi[k] > maxes[3]: maxes[3] = f_band_hi[k]
		if f_peak[k] > maxes[4]: maxes[4] = f_peak[k]
	var frame_feats: Array = []
	for k in range(si, ei + 1):
		var fv := PackedFloat32Array([
			f_energy[k] / maxes[0],
			f_zcr[k] / maxes[1],
			f_hf[k] / maxes[2],
			f_band_hi[k] / maxes[3],
			f_peak[k] / maxes[4],
		])
		if fv.size() != FRAME_FEATURE_COUNT:
			push_warning("[Classifier] Frame feature vector size mismatch: %d" % fv.size())
			return {}
		frame_feats.append(fv)

	return {"global": g_norm, "frames": frame_feats}

## ---- Global Feature Distance (weighted Euclidean) ----
## Weights emphasize spectral features over energy
const G_WEIGHTS: Array = [
	0.5, 0.3,   # energy mean/std
	2.5, 1.5,   # zcr mean/std
	2.0, 1.2,   # hf mean/std
	1.0, 0.5,   # band_lo mean/std
	1.5, 0.8,   # band_mid mean/std
	2.5, 1.5,   # band_hi mean/std
	0.5, 0.3,   # peak mean/std
	1.5,         # energy half ratio
	2.0,         # zcr half ratio
	2.5,         # band hi/(lo+mid) ratio
	1.5,         # band mid/lo ratio
	0.3,         # duration
	0.8,         # peak position
]

func _global_dist(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	var d := 0.0
	if a.size() != GLOBAL_FEATURE_COUNT or b.size() != GLOBAL_FEATURE_COUNT:
		return INF
	for k in range(GLOBAL_FEATURE_COUNT):
		var diff: float = a[k] - b[k]
		d += diff * diff * float(G_WEIGHTS[k])
	return sqrt(d)

## ---- DTW (5-dim) ----

const F_WEIGHTS: Array = [1.0, 2.5, 2.0, 2.0, 0.8]

func _dtw_multi(a: Array, b: Array) -> float:
	var na: int = a.size()
	var nb: int = b.size()
	if na == 0 or nb == 0:
		return INF
	var band: int = maxi(3, int(ceil(float(maxi(na, nb)) / 10.0)))
	var prev := PackedFloat32Array()
	prev.resize(nb)
	var curr := PackedFloat32Array()
	curr.resize(nb)
	prev[0] = _fv_dist(a[0], b[0])
	for j in range(1, mini(band, nb)):
		prev[j] = prev[j - 1] + _fv_dist(a[0], b[j])
	for j in range(mini(band, nb), nb):
		prev[j] = INF
	for i in range(1, na):
		var js: int = maxi(0, i - band)
		var je: int = mini(nb, i + band + 1)
		for j in range(0, js):
			curr[j] = INF
		for j in range(je, nb):
			curr[j] = INF
		for j in range(js, je):
			var cost: float = _fv_dist(a[i], b[j])
			var d0: float = prev[j]
			var d1: float = curr[j - 1] if j > 0 else INF
			var d2: float = prev[j - 1] if j > 0 else INF
			curr[j] = cost + minf(d0, minf(d1, d2))
		var tmp := prev
		prev = curr
		curr = tmp
	return prev[nb - 1] / float(maxi(na, nb))

func _fv_dist(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	var d := 0.0
	if a.size() != FRAME_FEATURE_COUNT or b.size() != FRAME_FEATURE_COUNT:
		return INF
	for k in range(FRAME_FEATURE_COUNT):
		var diff: float = a[k] - b[k]
		d += diff * diff * float(F_WEIGHTS[k])
	return d

## ---- Persistence ----

const VERSION := 3

func save_templates() -> void:
	if not is_model_ready():
		push_warning("[Classifier] Refused to save invalid template model")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
	file.store_32(VERSION)
	_save_list(file, _templates_fact)
	_save_list(file, _templates_thought)
	file.close()
	print("[Classifier] Saved %d+%d" % [_templates_fact.size(), _templates_thought.size()])

func _save_list(file: FileAccess, templates: Array) -> void:
	file.store_32(templates.size())
	for tmpl in templates:
		var g: PackedFloat32Array = tmpl.global
		if g.size() != GLOBAL_FEATURE_COUNT:
			continue
		for k in range(GLOBAL_FEATURE_COUNT):
			file.store_float(g[k])
		var fr: Array = tmpl.frames
		file.store_32(fr.size())
		for fv in fr:
			var v: PackedFloat32Array = fv
			if v.size() != FRAME_FEATURE_COUNT:
				continue
			for k in range(FRAME_FEATURE_COUNT):
				file.store_float(v[k])

func load_templates() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var ver: int = file.get_32()
	if ver != VERSION:
		file.close()
		clear_templates()
		return false
	var fact_templates: Array = _load_list(file)
	var thought_templates: Array = _load_list(file)
	file.close()
	if not set_templates({"fact": fact_templates, "thought": thought_templates}):
		push_warning("[Classifier] Loaded template file is invalid, forcing recalibration")
		clear_templates()
		return false
	print("[Classifier] Loaded %d+%d" % [_templates_fact.size(), _templates_thought.size()])
	if not is_model_ready():
		push_warning("[Classifier] Templates failed readiness validation, forcing recalibration")
		clear_templates()
		return false
	return true

func _load_list(file: FileAccess) -> Array:
	var result: Array = []
	var count: int = file.get_32()
	for i in count:
		var g := PackedFloat32Array()
		g.resize(GLOBAL_FEATURE_COUNT)
		for k in range(GLOBAL_FEATURE_COUNT):
			g[k] = file.get_float()
		var nf: int = file.get_32()
		var fr: Array = []
		for j in nf:
			var fv := PackedFloat32Array()
			fv.resize(FRAME_FEATURE_COUNT)
			for k in range(FRAME_FEATURE_COUNT):
				fv[k] = file.get_float()
			fr.append(fv)
		result.append({"global": g, "frames": fr})
	return result

func _duplicate_templates(templates: Array) -> Array:
	var copies: Array = []
	for tmpl in templates:
		if typeof(tmpl) != TYPE_DICTIONARY:
			continue
		var global_vec: PackedFloat32Array = tmpl.get("global", PackedFloat32Array())
		var frames: Array = tmpl.get("frames", [])
		var frame_copies: Array = []
		for fv in frames:
			if fv is PackedFloat32Array:
				frame_copies.append((fv as PackedFloat32Array).duplicate())
		copies.append({
			"global": global_vec.duplicate(),
			"frames": frame_copies,
		})
	return copies

func _sanitize_templates(raw_templates: Variant) -> Array:
	if typeof(raw_templates) != TYPE_ARRAY:
		return []
	return _duplicate_templates(raw_templates as Array)

func _validate_template_list(templates: Array, label: String) -> PackedStringArray:
	var errors := PackedStringArray()
	for index in range(templates.size()):
		var tmpl: Variant = templates[index]
		if typeof(tmpl) != TYPE_DICTIONARY:
			errors.append("%s template %d is not a dictionary" % [label, index])
			continue
		var global_vec: PackedFloat32Array = tmpl.get("global", PackedFloat32Array())
		if global_vec.size() != GLOBAL_FEATURE_COUNT:
			errors.append("%s template %d global size mismatch" % [label, index])
		var frames: Variant = tmpl.get("frames", [])
		if typeof(frames) != TYPE_ARRAY or (frames as Array).is_empty():
			errors.append("%s template %d frames missing" % [label, index])
			continue
		for frame_index in range((frames as Array).size()):
			var fv: Variant = (frames as Array)[frame_index]
			if not (fv is PackedFloat32Array):
				errors.append("%s template %d frame %d invalid" % [label, index, frame_index])
				continue
			if (fv as PackedFloat32Array).size() != FRAME_FEATURE_COUNT:
				errors.append("%s template %d frame %d size mismatch" % [label, index, frame_index])
	return errors
