## CogCardData — data module for the cognitive card game (玩法二).
## Adapted concept from godot-card-game-frame (1185724109).
## Usage: const CogData = preload("res://data/cog_card_data.gd")
extends RefCounted

# ── Enums ──────────────────────────────────────────────────────────────────────
enum CardType { SKILL, THOUGHT }

enum Distortion {
	CATASTROPHIZING     = 0,  # 灾难化
	MIND_READING        = 1,  # 读心术
	BLACK_WHITE         = 2,  # 非黑即白
	PERSONALIZATION     = 3,  # 个人化
	FORTUNE_TELLING     = 4,  # 预测未来
	EMOTIONAL_REASONING = 5,  # 情绪化推理
	SHOULD_STATEMENTS   = 6,  # 应该陈述
	MAGNIFICATION       = 7,  # 过度放大
}

# ── Static helpers ─────────────────────────────────────────────────────────────
static func distortion_name(d: int) -> String:
	match d:
		0: return "灾难化"
		1: return "读心术"
		2: return "非黑即白"
		3: return "个人化"
		4: return "预测未来"
		5: return "情绪推理"
		6: return "应该陈述"
		7: return "过度放大"
	return "未知"

static func get_skill_cards() -> Dictionary:
	return {
		"cognitive_reframe": {
			"display_name": "认知重构",
			"description":  "用更平衡的视角\n看待问题",
			"targets":       [0, 7],
			"effect_value":  20,
			"color":         Color(0.2, 0.6, 1.0),
		},
		"find_evidence": {
			"display_name": "寻找证据",
			"description":  "质疑假设，\n寻找真实证据",
			"targets":       [1, 4],
			"effect_value":  15,
			"color":         Color(0.3, 0.8, 0.5),
		},
		"mindful_breathing": {
			"display_name": "正念呼吸",
			"description":  "通过呼吸\n平复情绪",
			"targets":       [5],
			"effect_value":  10,
			"color":         Color(0.6, 0.3, 0.9),
		},
		"acceptance": {
			"display_name": "接纳自我",
			"description":  "接纳不完美，\n对自己更温柔",
			"targets":       [6, 3],
			"effect_value":  18,
			"color":         Color(1.0, 0.6, 0.2),
		},
		"perspective_shift": {
			"display_name": "换个角度",
			"description":  "从不同角度\n思考同一件事",
			"targets":       [2, 0],
			"effect_value":  16,
			"color":         Color(0.2, 0.8, 0.8),
		},
		"self_compassion": {
			"display_name": "自我关怀",
			"description":  "像对待朋友\n一样对待自己",
			"targets":       [3, 6],
			"effect_value":  14,
			"color":         Color(1.0, 0.4, 0.6),
		},
	}

static func get_thought_cards() -> Dictionary:
	return {
		"im_doomed": {
			"display_name": "我完蛋了",
			"description":  "考试没考好，\n人生就完了",
			"distortion":   0,
			"damage":        15,
			"scenario":      "学业压力",
		},
		"ill_fail": {
			"display_name": "我肯定会失败",
			"description":  "还没开始\n就预判失败",
			"distortion":   4,
			"damage":        16,
			"scenario":      "学业压力",
		},
		"i_feel_stupid": {
			"display_name": "我感觉自己很蠢",
			"description":  "把感受\n当事实看待",
			"distortion":   5,
			"damage":        13,
			"scenario":      "学业压力",
		},
		"im_worthless": {
			"display_name": "我一无是处",
			"description":  "极端化地\n评价自己的价值",
			"distortion":   2,
			"damage":        18,
			"scenario":      "家庭矛盾",
		},
		"its_my_fault": {
			"display_name": "都是我的错",
			"description":  "把所有问题\n归咎于自己",
			"distortion":   3,
			"damage":        14,
			"scenario":      "家庭矛盾",
		},
		"small_thing_huge": {
			"display_name": "这下全毁了",
			"description":  "把小错误\n无限放大",
			"distortion":   7,
			"damage":        17,
			"scenario":      "家庭矛盾",
		},
		"they_hate_me": {
			"display_name": "他们都讨厌我",
			"description":  "无证据猜测\n他人想法",
			"distortion":   1,
			"damage":        12,
			"scenario":      "社交压力",
		},
		"i_should_be_perfect": {
			"display_name": "我应该更完美",
			"description":  "用过高标准\n要求自己",
			"distortion":   6,
			"damage":        11,
			"scenario":      "社交压力",
		},
	}

static func get_thoughts_for_scenario(scenario: String) -> Array[String]:
	var result: Array[String] = []
	for key: String in get_thought_cards():
		if get_thought_cards()[key]["scenario"] == scenario:
			result.append(key)
	return result

static func get_all_skill_keys() -> Array[String]:
	var keys: Array[String] = []
	keys.assign(get_skill_cards().keys())
	return keys
