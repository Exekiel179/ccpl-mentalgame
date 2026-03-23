## GeminiService — generates background art via Gemini image API.
## Reads credentials from the .env at project root at runtime.
class_name GeminiService
extends Node

signal image_ready(texture: Texture2D)
signal image_failed(reason: String)

const ENV_PATH := "res://.env"

var _api_key: String = ""
var _endpoint: String = ""
var _http: HTTPRequest

func _ready() -> void:
	_load_env()
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

func _load_env() -> void:
	var file := FileAccess.open(ENV_PATH, FileAccess.READ)
	if not file:
		push_warning("GeminiService: .env not found at " + ENV_PATH)
		return
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.begins_with("GEMINI_API_KEY="):
			_api_key = line.substr("GEMINI_API_KEY=".length())
		elif line.begins_with("GEMINI_API_ENDPOINT="):
			_endpoint = line.substr("GEMINI_API_ENDPOINT=".length())
	file.close()

func generate_background(scenario: String) -> void:
	if _api_key.is_empty() or _endpoint.is_empty():
		image_failed.emit("API credentials not loaded")
		return

	var prompt := _build_prompt(scenario)
	var body := JSON.stringify({
		"contents": [{"parts": [{"text": prompt}]}],
		"generationConfig": {"responseModalities": ["IMAGE"], "responseMimeType": "image/png"}
	})
	var headers := [
		"Content-Type: application/json",
		"x-goog-api-key: " + _api_key
	]
	var err := _http.request(_endpoint, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		image_failed.emit("HTTP request error: %d" % err)

func _build_prompt(scenario: String) -> String:
	var base := "A soft, calm 2D anime-style game background illustration for a mental health game. "
	if scenario == "\u5b66\u4e1a\u538b\u529b":
		return base + "A warm classroom at dusk, scattered study notes, gentle lamp light, peaceful and slightly melancholic atmosphere."
	elif scenario == "\u5bb6\u5ead\u77db\u76fe":
		return base + "A cozy living room at evening, empty sofa, soft window light, quiet and reflective mood."
	elif scenario == "\u793e\u4ea4\u538b\u529b":
		return base + "A school hallway or cafeteria, blurred students in background, warm pastel tones, slightly lonely but hopeful."
	elif scenario == "\u4e3b\u83dc\u5355":
		return base + "A mystical moonlit maze entrance, soft glowing path through dark hedgerows, stars above, calm and inviting atmosphere, sense of discovery and inner journey."
	elif scenario == "\u7acb\u7ed8":
		return "A single anime-style character illustration for a mental health game main menu. A gentle, hopeful teenage student with soft pastel clothing, standing confidently with a warm smile. Full-body portrait, transparent or plain background, clean anime art style, high quality, emotionally warm and encouraging."
	return base + "A serene, pastel-toned indoor space with soft lighting."

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		image_failed.emit("HTTP %d, result %d" % [response_code, result])
		return

	var json := JSON.new()
	var parse_err := json.parse(body.get_string_from_utf8())
	if parse_err != OK:
		image_failed.emit("JSON parse error")
		return

	var data: Dictionary = json.get_data()
	var candidates: Array = data.get("candidates", [])
	if candidates.is_empty():
		image_failed.emit("No candidates in response")
		return
	var parts: Array = candidates[0].get("content", {}).get("parts", [])
	for part in parts:
		if part.has("inlineData"):
			var b64: String = part["inlineData"].get("data", "")
			var raw := Marshalls.base64_to_raw(b64)
			var img := Image.new()
			if img.load_png_from_buffer(raw) == OK:
				image_ready.emit(ImageTexture.create_from_image(img))
				return
	image_failed.emit("No image data in response")
