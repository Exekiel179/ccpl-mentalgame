## CogCardData — data module for the CBT card battle.
extends RefCounted

const SCENARIO_ACADEMIC := "学业压力"
const SCENARIO_FAMILY := "家庭矛盾"
const SCENARIO_SOCIAL := "社交压力"

enum CardType {
	CRISIS,
	DISTORTION,
	EVIDENCE,
	SKILL,
	BALANCED_THOUGHT,
}

enum Step {
	SITUATION,
	AUTOMATIC_THOUGHT,
	EMOTION,
	DISTORTION,
	EVIDENCE,
	REFRAME,
	RERATE,
}

enum Distortion {
	CATASTROPHIZING,
	MIND_READING,
	BLACK_WHITE,
	PERSONALIZATION,
	FORTUNE_TELLING,
	EMOTIONAL_REASONING,
	SHOULD_STATEMENTS,
	MAGNIFICATION,
	OVERGENERALIZATION,
	LABELING,
	DISCOUNTING_POSITIVES,
	MENTAL_FILTER,
}

static func step_name(step: int) -> String:
	match step:
		Step.SITUATION:
			return "情境"
		Step.AUTOMATIC_THOUGHT:
			return "自动化想法"
		Step.EMOTION:
			return "情绪标记"
		Step.DISTORTION:
			return "认知偏差"
		Step.EVIDENCE:
			return "证据检验"
		Step.REFRAME:
			return "认知重构"
		Step.RERATE:
			return "情绪重评"
	return ""

static func distortion_name(d: int) -> String:
	match d:
		Distortion.CATASTROPHIZING:
			return "灾难化"
		Distortion.MIND_READING:
			return "读心术"
		Distortion.BLACK_WHITE:
			return "非黑即白"
		Distortion.PERSONALIZATION:
			return "个性化"
		Distortion.FORTUNE_TELLING:
			return "预测未来"
		Distortion.EMOTIONAL_REASONING:
			return "情绪推理"
		Distortion.SHOULD_STATEMENTS:
			return "应该陈述"
		Distortion.MAGNIFICATION:
			return "过度放大"
		Distortion.OVERGENERALIZATION:
			return "过度概括"
		Distortion.LABELING:
			return "标签化"
		Distortion.DISCOUNTING_POSITIVES:
			return "忽视积极面"
		Distortion.MENTAL_FILTER:
			return "心理过滤"
	return "未知"

static func get_distortion_cards() -> Dictionary:
	return {
		"catastrophizing": {"id": Distortion.CATASTROPHIZING, "display_name": "灾难化", "description": "把困难直接推演成最糟结果。"},
		"mind_reading": {"id": Distortion.MIND_READING, "display_name": "读心术", "description": "在没有证据时替别人下结论。"},
		"black_white": {"id": Distortion.BLACK_WHITE, "display_name": "非黑即白", "description": "把表现看成全好或全坏。"},
		"personalization": {"id": Distortion.PERSONALIZATION, "display_name": "个性化", "description": "把复杂结果都归到自己身上。"},
		"fortune_telling": {"id": Distortion.FORTUNE_TELLING, "display_name": "预测未来", "description": "还没发生就认定结局。"},
		"emotional_reasoning": {"id": Distortion.EMOTIONAL_REASONING, "display_name": "情绪推理", "description": "把感受当成事实。"},
		"should_statements": {"id": Distortion.SHOULD_STATEMENTS, "display_name": "应该陈述", "description": "用很高标准要求自己。"},
		"magnification": {"id": Distortion.MAGNIFICATION, "display_name": "过度放大", "description": "把一次波动放得非常大。"},
		"overgeneralization": {"id": Distortion.OVERGENERALIZATION, "display_name": "过度概括", "description": "从一次经历推到一直如此。"},
		"labeling": {"id": Distortion.LABELING, "display_name": "标签化", "description": "用固定标签定义自己。"},
		"discounting_positives": {"id": Distortion.DISCOUNTING_POSITIVES, "display_name": "忽视积极面", "description": "看见问题，却忽略已经做到的部分。"},
		"mental_filter": {"id": Distortion.MENTAL_FILTER, "display_name": "心理过滤", "description": "只盯着负面细节，忽略整体。"},
	}

static func get_skill_cards() -> Dictionary:
	return {
		"cognitive_reframe": {
			"display_name": "认知重构",
			"description": "把极端想法调整成更平衡的表达。",
			"targets": [Distortion.CATASTROPHIZING, Distortion.BLACK_WHITE, Distortion.LABELING, Distortion.OVERGENERALIZATION],
			"effect_value": 14,
			"insight_cost": 1,
			"color": Color(0.34, 0.62, 1.0),
		},
		"find_evidence": {
			"display_name": "寻找证据",
			"description": "把推测和事实分开，看看有哪些证据。",
			"targets": [Distortion.FORTUNE_TELLING, Distortion.MIND_READING, Distortion.MENTAL_FILTER],
			"effect_value": 12,
			"insight_cost": 1,
			"color": Color(0.28, 0.82, 0.64),
		},
		"self_compassion": {
			"display_name": "自我关怀",
			"description": "在压力下仍然以温和态度对待自己。",
			"targets": [Distortion.SHOULD_STATEMENTS, Distortion.LABELING, Distortion.PERSONALIZATION],
			"effect_value": 10,
			"insight_cost": 1,
			"color": Color(1.0, 0.55, 0.72),
		},
		"perspective_shift": {
			"display_name": "换个角度",
			"description": "尝试从更完整的视角理解当下。",
			"targets": [Distortion.MAGNIFICATION, Distortion.BLACK_WHITE, Distortion.DISCOUNTING_POSITIVES],
			"effect_value": 11,
			"insight_cost": 1,
			"color": Color(0.42, 0.86, 0.90),
		},
		"accept_emotion": {
			"display_name": "接纳情绪",
			"description": "先允许情绪存在，再决定下一步。",
			"targets": [Distortion.EMOTIONAL_REASONING, Distortion.MAGNIFICATION],
			"effect_value": 9,
			"insight_cost": 1,
			"color": Color(0.82, 0.58, 1.0),
		},
	}

static func get_all_skill_keys() -> Array[String]:
	return get_skill_cards().keys()

static func get_encounters_for_scenario(scenario: String) -> Array[Dictionary]:
	match scenario:
		SCENARIO_ACADEMIC:
			return _academic_encounters()
		SCENARIO_FAMILY:
			return _family_encounters()
		SCENARIO_SOCIAL:
			return _social_encounters()
	return _academic_encounters()

static func _fallback_encounter(scenario: String) -> Dictionary:
	return {
		"id": scenario + "_placeholder",
		"scenario": scenario,
		"title": scenario + "练习整理中",
		"situation_text": "这个场景的完整卡组正在整理中。现在你仍可以体验完整的七步流程。",
		"automatic_thoughts": [
			{"id": "t1", "text": "我现在有点担心后面会不会更难。", "weight": 3},
			{"id": "t2", "text": "这只是一个过渡阶段，我可以先一步一步来。", "weight": 2},
		],
		"emotion_options": [
			{"id": "e1", "label": "担心", "intensity": 55},
			{"id": "e2", "label": "紧张", "intensity": 60},
			{"id": "e3", "label": "有点失落", "intensity": 45},
		],
		"distortion_options": [
			{"id": Distortion.FORTUNE_TELLING, "weight": 3},
			{"id": Distortion.MAGNIFICATION, "weight": 2},
			{"id": Distortion.MENTAL_FILTER, "weight": 2},
		],
		"evidence_cards": [
			{"id": "ev1", "text": "目前只是内容还没补齐，不代表你处理不了这个场景。", "kind": "counter", "weight": 3},
			{"id": "ev2", "text": "我现在确实还不知道后续会怎样。", "kind": "support", "weight": 1},
			{"id": "ev3", "text": "可以先完成眼前这一步，再看下一步。", "kind": "counter", "weight": 2},
		],
		"skill_options": ["find_evidence", "accept_emotion", "perspective_shift"],
		"balanced_thought_options": [
			{"id": "b1", "text": "这个场景还在整理，不确定是正常的，我可以先体验当前流程。", "weight": 3},
			{"id": "b2", "text": "我需要一次性把所有内容都想清楚。", "weight": 1},
		],
		"feedback": {
			"situation": "先看清眼前发生了什么，再决定怎么回应。",
			"automatic_thought": "你已经在留意脑中最先冒出的想法了。",
			"emotion": "给情绪命名，本身就是在建立距离。",
			"distortion": "这是一种可以继续观察的思维方式。",
			"evidence": "把支持证据和反证都摆出来，有助于看得更完整。",
			"reframe": "你正在练习让想法更平衡。",
			"rerate": "即使情绪没有完全消失，只要出现松动，就是有价值的变化。",
		},
	}

static func _academic_encounters() -> Array[Dictionary]:
	return [
		{
			"id": "academic_mock_exam_drop",
			"scenario": SCENARIO_ACADEMIC,
			"title": "模考成绩下滑",
			"situation_text": "这次模考成绩比上次低了很多，你看到成绩单时心里一沉。",
			"automatic_thoughts": [
				{"id": "t1", "text": "我这次下滑这么多，后面肯定会越来越差。", "weight": 3},
				{"id": "t2", "text": "我是不是根本不适合继续学下去。", "weight": 2},
				{"id": "t3", "text": "一次成绩波动不一定代表整体能力。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "焦虑", "intensity": 80},
				{"id": "e2", "label": "失落", "intensity": 72},
				{"id": "e3", "label": "羞愧", "intensity": 68},
			],
			"distortion_options": [
				{"id": Distortion.FORTUNE_TELLING, "weight": 3},
				{"id": Distortion.OVERGENERALIZATION, "weight": 3},
				{"id": Distortion.MAGNIFICATION, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "这次成绩确实比上次低。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "以前也有过波动，后面通过复盘又提上来了。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "一次模考无法完整代表之后所有考试。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "最近复习节奏被打乱，说明还有可以调整的空间。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["find_evidence", "cognitive_reframe", "perspective_shift"],
			"balanced_thought_options": [
				{"id": "b1", "text": "这次下滑让我不舒服，但它更像一个提醒，我还能通过复盘调整。", "weight": 3},
				{"id": "b2", "text": "我这次发挥一般，可这不等于之后一定越来越差。", "weight": 3},
				{"id": "b3", "text": "只要分数掉了，就说明我不行。", "weight": 1},
			],
			"feedback": _default_feedback("你在把一次成绩波动和整体未来分开看。"),
		},
		{
			"id": "academic_homework_deadline",
			"scenario": SCENARIO_ACADEMIC,
			"title": "作业快到截止",
			"situation_text": "晚上已经很晚了，明天要交的作业还有一大半没写完。",
			"automatic_thoughts": [
				{"id": "t1", "text": "我又拖到最后，说明我一点自制力都没有。", "weight": 3},
				{"id": "t2", "text": "如果这次没写完，老师一定会觉得我很差。", "weight": 2},
				{"id": "t3", "text": "我现在有压力，但还可以先完成最关键的部分。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "慌张", "intensity": 78},
				{"id": "e2", "label": "自责", "intensity": 70},
				{"id": "e3", "label": "烦躁", "intensity": 62},
			],
			"distortion_options": [
				{"id": Distortion.LABELING, "weight": 3},
				{"id": Distortion.MIND_READING, "weight": 2},
				{"id": Distortion.BLACK_WHITE, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "作业确实还剩很多。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "作业没做完不等于我整个人都没有自制力。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "老师对这次怎么看，还没有直接证据。", "kind": "counter", "weight": 2},
				{"id": "ev4", "text": "我可以先列优先级，把最重要的题先完成。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["self_compassion", "find_evidence", "cognitive_reframe"],
			"balanced_thought_options": [
				{"id": "b1", "text": "我现在确实有点赶，但这说明我需要调整节奏，不代表我整个人都很差。", "weight": 3},
				{"id": "b2", "text": "先完成重点部分，比继续慌张更有帮助。", "weight": 3},
				{"id": "b3", "text": "我总是这样，改不了了。", "weight": 1},
			],
			"feedback": _default_feedback("你已经把自责和可执行的下一步分开了。"),
		},
		{
			"id": "academic_freeze_in_class",
			"scenario": SCENARIO_ACADEMIC,
			"title": "课堂被点名卡住",
			"situation_text": "老师突然点你回答问题，你一时脑子空白，没有立刻说出来。",
			"automatic_thoughts": [
				{"id": "t1", "text": "大家肯定都觉得我很笨。", "weight": 3},
				{"id": "t2", "text": "我怎么连这么简单的问题都不会。", "weight": 2},
				{"id": "t3", "text": "我刚刚卡住了，但这不等于所有人都在否定我。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "尴尬", "intensity": 82},
				{"id": "e2", "label": "紧张", "intensity": 76},
				{"id": "e3", "label": "羞愧", "intensity": 64},
			],
			"distortion_options": [
				{"id": Distortion.MIND_READING, "weight": 3},
				{"id": Distortion.LABELING, "weight": 2},
				{"id": Distortion.MAGNIFICATION, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "我刚刚确实没有马上回答出来。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "我并不知道同学们具体在想什么。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "课堂上卡住一次很常见，并不等于能力低。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "紧张时大脑变空白，不代表以后都会这样。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["find_evidence", "accept_emotion", "self_compassion"],
			"balanced_thought_options": [
				{"id": "b1", "text": "我刚才有点卡住，这很尴尬，但它不足以定义我的能力。", "weight": 3},
				{"id": "b2", "text": "我不知道别人怎么想，比起猜测，更重要的是先缓下来。", "weight": 3},
				{"id": "b3", "text": "只要卡壳一次，别人就会一直记得。", "weight": 1},
			],
			"feedback": _default_feedback("你在把当下的尴尬体验和对他人的猜测区分开。"),
		},
		{
			"id": "academic_rank_drop",
			"scenario": SCENARIO_ACADEMIC,
			"title": "排名下降",
			"situation_text": "阶段考试后，你看到自己的排名比之前下降了十几名。",
			"automatic_thoughts": [
				{"id": "t1", "text": "我一掉排名，就说明我已经跟不上了。", "weight": 3},
				{"id": "t2", "text": "如果排名继续掉，我以后就没有希望了。", "weight": 3},
				{"id": "t3", "text": "排名能反映阶段状态，但不等于全部。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "焦虑", "intensity": 84},
				{"id": "e2", "label": "挫败", "intensity": 75},
				{"id": "e3", "label": "不安", "intensity": 70},
			],
			"distortion_options": [
				{"id": Distortion.BLACK_WHITE, "weight": 3},
				{"id": Distortion.FORTUNE_TELLING, "weight": 3},
				{"id": Distortion.MAGNIFICATION, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "排名这次确实下降了。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "排名受试卷难度和群体波动影响，不只由单一能力决定。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "阶段排名下降不等于未来没有希望。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "我可以从薄弱题型里找到更具体的调整方向。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["perspective_shift", "find_evidence", "cognitive_reframe"],
			"balanced_thought_options": [
				{"id": "b1", "text": "排名下降让我紧张，但它更像阶段信号，不是对未来的定论。", "weight": 3},
				{"id": "b2", "text": "我可以关注这次失分点，而不是直接把未来也判掉。", "weight": 3},
				{"id": "b3", "text": "排名只要掉了，就说明以后都不行。", "weight": 1},
			],
			"feedback": _default_feedback("你正在把阶段结果和长远前景分开看。"),
		},
		{
			"id": "academic_compare_with_top_student",
			"scenario": SCENARIO_ACADEMIC,
			"title": "和高分同学比较",
			"situation_text": "你看到同学轻松拿到高分，自己却还在反复订正错题。",
			"automatic_thoughts": [
				{"id": "t1", "text": "别人都能做到，我做不到就说明我不够聪明。", "weight": 3},
				{"id": "t2", "text": "我再努力也赶不上他们。", "weight": 2},
				{"id": "t3", "text": "我和别人节奏不同，不代表我没有进步空间。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "羡慕", "intensity": 65},
				{"id": "e2", "label": "自卑", "intensity": 78},
				{"id": "e3", "label": "沮丧", "intensity": 72},
			],
			"distortion_options": [
				{"id": Distortion.LABELING, "weight": 3},
				{"id": Distortion.DISCOUNTING_POSITIVES, "weight": 3},
				{"id": Distortion.BLACK_WHITE, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "那位同学这次确实考得很好。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "别人的高分并不能直接证明我不够聪明。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "我最近也有一些题型比之前更稳定。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "比较时我更容易只看见自己的不足。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["self_compassion", "perspective_shift", "cognitive_reframe"],
			"balanced_thought_options": [
				{"id": "b1", "text": "别人的表现会让我有压力，但这不等于我的能力已经被定义。", "weight": 3},
				{"id": "b2", "text": "我可以参考别人，也要看到自己正在进步的部分。", "weight": 3},
				{"id": "b3", "text": "只要别人更强，就说明我不行。", "weight": 1},
			],
			"feedback": _default_feedback("你开始同时看见外界比较和自己的实际进展。"),
		},
		{
			"id": "academic_parent_disappointed",
			"scenario": SCENARIO_ACADEMIC,
			"title": "父母对成绩失望",
			"situation_text": "家长看到成绩后沉默了很久，还说你最近是不是不够用心。",
			"automatic_thoughts": [
				{"id": "t1", "text": "我让他们失望了，说明我是个失败的人。", "weight": 3},
				{"id": "t2", "text": "如果我成绩不好，家里一定会一直责怪我。", "weight": 2},
				{"id": "t3", "text": "他们现在很担心，但这不等于我整个人都失败。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "内疚", "intensity": 78},
				{"id": "e2", "label": "难过", "intensity": 74},
				{"id": "e3", "label": "压力", "intensity": 82},
			],
			"distortion_options": [
				{"id": Distortion.LABELING, "weight": 3},
				{"id": Distortion.FORTUNE_TELLING, "weight": 2},
				{"id": Distortion.PERSONALIZATION, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "他们确实对这次成绩有担心。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "一次成绩和一个人的整体价值不是同一件事。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "他们的反应也可能混合了焦虑和期待，不全是对我的否定。", "kind": "counter", "weight": 2},
				{"id": "ev4", "text": "我可以就学习安排和他们沟通，而不是只把自己贴上标签。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["self_compassion", "find_evidence", "accept_emotion"],
			"balanced_thought_options": [
				{"id": "b1", "text": "他们的失望会让我难过，但这不等于我就是失败的人。", "weight": 3},
				{"id": "b2", "text": "我可以把注意力放回接下来能怎么调整，而不是只否定自己。", "weight": 3},
				{"id": "b3", "text": "只要家里不满意，我就没有价值。", "weight": 1},
			],
			"feedback": _default_feedback("你在把别人的反应和自我价值分开。"),
		},
		{
			"id": "academic_teacher_criticism",
			"scenario": SCENARIO_ACADEMIC,
			"title": "老师批评学习方法",
			"situation_text": "老师指出你最近做题很多，但方法比较散，复盘不够系统。",
			"automatic_thoughts": [
				{"id": "t1", "text": "老师都这样说了，说明我做什么都没用。", "weight": 3},
				{"id": "t2", "text": "我是不是连努力都努力错了。", "weight": 2},
				{"id": "t3", "text": "被指出方法问题虽然难受，但也给了我调整方向。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "委屈", "intensity": 66},
				{"id": "e2", "label": "挫败", "intensity": 74},
				{"id": "e3", "label": "担心", "intensity": 70},
			],
			"distortion_options": [
				{"id": Distortion.BLACK_WHITE, "weight": 3},
				{"id": Distortion.DISCOUNTING_POSITIVES, "weight": 2},
				{"id": Distortion.MAGNIFICATION, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "老师确实指出了方法上的问题。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "方法需要调整，不代表努力完全没用。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "能指出具体问题，也意味着有具体改进点。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "我过去也有一些题靠复盘改进过。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["perspective_shift", "cognitive_reframe", "find_evidence"],
			"balanced_thought_options": [
				{"id": "b1", "text": "这次反馈让我不舒服，但它更像在提醒我优化方法，而不是否定努力。", "weight": 3},
				{"id": "b2", "text": "如果我把批评转成可执行建议，压力会更容易落地。", "weight": 3},
				{"id": "b3", "text": "老师一批评，就说明我没救了。", "weight": 1},
			],
			"feedback": _default_feedback("你正在把评价变成可操作的信息。"),
		},
		{
			"id": "academic_weak_subject_repeat",
			"scenario": SCENARIO_ACADEMIC,
			"title": "弱科反复出错",
			"situation_text": "你在同一门弱科里又出现了类似错误，改完后还是觉得很挫败。",
			"automatic_thoughts": [
				{"id": "t1", "text": "我在这门课上就是学不会。", "weight": 3},
				{"id": "t2", "text": "同样的错又出现，说明我没有进步。", "weight": 2},
				{"id": "t3", "text": "重复出错说明这里还薄弱，但不等于完全学不会。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "沮丧", "intensity": 80},
				{"id": "e2", "label": "无力", "intensity": 74},
				{"id": "e3", "label": "烦躁", "intensity": 68},
			],
			"distortion_options": [
				{"id": Distortion.OVERGENERALIZATION, "weight": 3},
				{"id": Distortion.DISCOUNTING_POSITIVES, "weight": 2},
				{"id": Distortion.LABELING, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "类似错误确实又出现了。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "重复出错说明还需要练习，不等于永远学不会。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "我能指出错因，说明并不是完全没有理解。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "进步有时是波动式的，不一定是直线上升。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["cognitive_reframe", "self_compassion", "find_evidence"],
			"balanced_thought_options": [
				{"id": "b1", "text": "这门课目前对我更难，但难不代表没有进步空间。", "weight": 3},
				{"id": "b2", "text": "重复错误提醒我这里需要更具体的练习方法。", "weight": 3},
				{"id": "b3", "text": "只要又错一次，就说明我根本学不会。", "weight": 1},
			],
			"feedback": _default_feedback("你在把‘还不稳定’和‘永远学不会’区分开。"),
		},
		{
			"id": "academic_future_uncertainty",
			"scenario": SCENARIO_ACADEMIC,
			"title": "担心未来升学",
			"situation_text": "想到升学竞争和未来方向，你越想越觉得前面一片模糊。",
			"automatic_thoughts": [
				{"id": "t1", "text": "如果我现在没准备好，以后一定会很惨。", "weight": 3},
				{"id": "t2", "text": "别人都比我更清楚自己要做什么。", "weight": 2},
				{"id": "t3", "text": "我现在不确定很正常，可以先处理最近的一步。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "焦虑", "intensity": 86},
				{"id": "e2", "label": "迷茫", "intensity": 74},
				{"id": "e3", "label": "压力", "intensity": 80},
			],
			"distortion_options": [
				{"id": Distortion.FORTUNE_TELLING, "weight": 3},
				{"id": Distortion.MIND_READING, "weight": 2},
				{"id": Distortion.CATASTROPHIZING, "weight": 3},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "我对未来确实有很多不确定。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "不确定并不等于结果一定很糟。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "我并不知道别人是不是真的都比我清楚。", "kind": "counter", "weight": 2},
				{"id": "ev4", "text": "把关注点放到最近能做的一步，会比一直预演最坏情况更有帮助。", "kind": "counter", "weight": 3},
			],
			"skill_options": ["find_evidence", "accept_emotion", "perspective_shift"],
			"balanced_thought_options": [
				{"id": "b1", "text": "未来有不确定性是真的，但我不需要今天就把全部答案都想完。", "weight": 3},
				{"id": "b2", "text": "先把最近的学习安排稳下来，会比反复预演最坏结果更实际。", "weight": 3},
				{"id": "b3", "text": "只要现在不确定，以后就一定会很糟。", "weight": 1},
			],
			"feedback": _default_feedback("你在把未来的不确定和当下可做的事放回同一张图里。"),
		},
		{
			"id": "academic_sleep_before_exam",
			"scenario": SCENARIO_ACADEMIC,
			"title": "考前没睡好",
			"situation_text": "重要考试前一晚你没有睡好，第二天一早就开始担心自己会彻底崩掉。",
			"automatic_thoughts": [
				{"id": "t1", "text": "我昨晚没睡好，今天肯定全完了。", "weight": 3},
				{"id": "t2", "text": "我现在这么慌，说明我一定考不好。", "weight": 3},
				{"id": "t3", "text": "睡眠不足会影响状态，但不等于整场考试都没有机会。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "恐慌", "intensity": 84},
				{"id": "e2", "label": "焦虑", "intensity": 82},
				{"id": "e3", "label": "无助", "intensity": 70},
			],
			"distortion_options": [
				{"id": Distortion.CATASTROPHIZING, "weight": 3},
				{"id": Distortion.EMOTIONAL_REASONING, "weight": 3},
				{"id": Distortion.FORTUNE_TELLING, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "我昨晚确实没睡好。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "状态受影响不等于今天一定会完全失控。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "现在很慌，说明我在意这场考试，不等于结果已经确定。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "我可以通过呼吸、节奏控制和先做熟悉题来稳定自己。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["accept_emotion", "find_evidence", "cognitive_reframe"],
			"balanced_thought_options": [
				{"id": "b1", "text": "我今天状态可能受一点影响，但这不等于整场考试都会失控。", "weight": 3},
				{"id": "b2", "text": "我现在很紧张，可以先把自己稳定下来，再处理眼前的题。", "weight": 3},
				{"id": "b3", "text": "只要没睡好，这场考试就一定没戏。", "weight": 1},
			],
			"feedback": _default_feedback("你在把身体状态、情绪和考试结果分开看。"),
		},
	]

static func _family_encounters() -> Array[Dictionary]:
	return [
		{
			"id": "family_misunderstood_lazy",
			"scenario": SCENARIO_FAMILY,
			"title": "被误会成偷懒",
			"situation_text": "你刚写完一轮作业想休息一会儿，家长路过时皱着眉说你是不是又在偷懒。",
			"automatic_thoughts": [
				{"id": "t1", "text": "他们都这么说了，说明我在家里就是没人在乎努力。", "weight": 3},
				{"id": "t2", "text": "我是不是怎么做都会被看成不够好。", "weight": 2},
				{"id": "t3", "text": "这句评价让我难受，但它不一定完整反映我刚才的状态。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "委屈", "intensity": 82},
				{"id": "e2", "label": "生气", "intensity": 74},
				{"id": "e3", "label": "无奈", "intensity": 68},
			],
			"distortion_options": [
				{"id": Distortion.OVERGENERALIZATION, "weight": 3},
				{"id": Distortion.MIND_READING, "weight": 2},
				{"id": Distortion.PERSONALIZATION, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "家长刚才确实批评了我。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "他们只看到了休息的那一刻，没有看到我前面已经学了一段时间。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "一句话让我受伤，不等于他们真的完全不在乎我的努力。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "我可以等情绪缓一点，再说明自己刚才在做什么。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["find_evidence", "self_compassion", "perspective_shift"],
			"balanced_thought_options": [
				{"id": "b1", "text": "他们这一句让我很委屈，但它不等于我的努力全都被否定了。", "weight": 3},
				{"id": "b2", "text": "我可以先稳住自己，再决定要不要把刚才的实际情况说清楚。", "weight": 3},
				{"id": "b3", "text": "只要被误会一次，就说明这个家永远不会理解我。", "weight": 1},
			],
			"feedback": _default_feedback("你在把当下的误会和更大的关系结论分开。"),
		},
		{
			"id": "family_scolded_for_phone",
			"scenario": SCENARIO_FAMILY,
			"title": "因为手机被批评",
			"situation_text": "你刚拿起手机回同学消息，家长就说你成绩起不来都是因为整天玩手机。",
			"automatic_thoughts": [
				{"id": "t1", "text": "他们已经认定问题都在我身上了。", "weight": 3},
				{"id": "t2", "text": "只要我碰手机，在他们眼里我就是没救。", "weight": 2},
				{"id": "t3", "text": "他们现在很敏感，但不代表所有原因都被简单归到我身上。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "烦躁", "intensity": 79},
				{"id": "e2", "label": "委屈", "intensity": 72},
				{"id": "e3", "label": "反感", "intensity": 68},
			],
			"distortion_options": [
				{"id": Distortion.BLACK_WHITE, "weight": 3},
				{"id": Distortion.LABELING, "weight": 2},
				{"id": Distortion.PERSONALIZATION, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "他们刚才确实把手机和成绩问题连在一起说了。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "这句话很武断，但它不一定代表他们已经对我下了完整结论。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "学习状态受很多因素影响，不是一个动作就能全部解释。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "我可以之后讨论使用手机的边界，而不是立刻把自己判成问题本身。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["cognitive_reframe", "find_evidence", "self_compassion"],
			"balanced_thought_options": [
				{"id": "b1", "text": "他们的说法让我很不舒服，但不等于所有问题都只说明我一个人有错。", "weight": 3},
				{"id": "b2", "text": "如果要谈手机问题，我更需要谈具体习惯，而不是直接给自己下结论。", "weight": 3},
				{"id": "b3", "text": "只要他们提到手机，就证明我已经彻底没希望了。", "weight": 1},
			],
			"feedback": _default_feedback("你在把尖锐评价和对自己的整体定性分开。"),
		},
		{
			"id": "family_cold_war_after_argument",
			"scenario": SCENARIO_FAMILY,
			"title": "争吵后的冷战",
			"situation_text": "昨晚和家里吵完之后，今天吃饭时大家都没怎么说话，气氛很僵。",
			"automatic_thoughts": [
				{"id": "t1", "text": "这次气氛这么差，肯定都是我把家里搞砸了。", "weight": 3},
				{"id": "t2", "text": "只要一吵架，我们的关系就回不去了。", "weight": 2},
				{"id": "t3", "text": "现在很僵是真的，但关系不一定会一直卡在这里。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "内疚", "intensity": 77},
				{"id": "e2", "label": "紧绷", "intensity": 73},
				{"id": "e3", "label": "难过", "intensity": 69},
			],
			"distortion_options": [
				{"id": Distortion.PERSONALIZATION, "weight": 3},
				{"id": Distortion.FORTUNE_TELLING, "weight": 2},
				{"id": Distortion.CATASTROPHIZING, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "家里现在的气氛确实很僵。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "一次冲突通常是多方情绪累积，不会只由我一个人造成。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "关系紧张不舒服，但并不自动等于再也修复不了。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "等情绪缓下来后，仍然有机会从一句更平静的话重新开始。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["accept_emotion", "find_evidence", "self_compassion"],
			"balanced_thought_options": [
				{"id": "b1", "text": "这次冲突让我很难受，但我不用把整个家庭气氛都一个人扛下来。", "weight": 3},
				{"id": "b2", "text": "现在的沉默很刺耳，不过它更像一个阶段，不一定是关系的终点。", "weight": 3},
				{"id": "b3", "text": "只要吵到这种程度，就说明我们永远没法好好相处。", "weight": 1},
			],
			"feedback": _default_feedback("你在把冲突带来的内疚感和真实责任范围分开。"),
		},
		{
			"id": "family_compared_with_other_kids",
			"scenario": SCENARIO_FAMILY,
			"title": "被拿去和别人比较",
			"situation_text": "家长又提起亲戚家的孩子，说别人比你懂事又上进，让你多学学。",
			"automatic_thoughts": [
				{"id": "t1", "text": "在他们眼里，我永远都比不上别人。", "weight": 3},
				{"id": "t2", "text": "既然总被比较，说明我本来就不够好。", "weight": 2},
				{"id": "t3", "text": "这种比较让我受伤，但不代表我的价值只能由别人来决定。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "受伤", "intensity": 80},
				{"id": "e2", "label": "自卑", "intensity": 75},
				{"id": "e3", "label": "生气", "intensity": 66},
			],
			"distortion_options": [
				{"id": Distortion.OVERGENERALIZATION, "weight": 3},
				{"id": Distortion.LABELING, "weight": 2},
				{"id": Distortion.DISCOUNTING_POSITIVES, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "他们刚才确实拿别人和我比较了。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "被比较很刺痛，但不等于我在所有方面都比不上别人。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "我身上也有一些已经做到、只是此刻没被看见的部分。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "他们用比较表达焦虑，不代表这种表达就是对我价值的准确定义。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["self_compassion", "perspective_shift", "cognitive_reframe"],
			"balanced_thought_options": [
				{"id": "b1", "text": "被比较让我很受伤，但我不需要把别人的尺子直接变成对自己的判决。", "weight": 3},
				{"id": "b2", "text": "我可以承认自己有压力，同时继续看见自己的节奏和已有的努力。", "weight": 3},
				{"id": "b3", "text": "只要有人比我强，就说明我毫无价值。", "weight": 1},
			],
			"feedback": _default_feedback("你在把外界比较和对自己的整体评价拆开。"),
		},
		{
			"id": "family_expectations_too_high",
			"scenario": SCENARIO_FAMILY,
			"title": "被期待必须更好",
			"situation_text": "家长说你现在这样还不够，既然有潜力就应该做到更好，不要让人失望。",
			"automatic_thoughts": [
				{"id": "t1", "text": "如果我达不到他们想要的样子，我就是让人失望的人。", "weight": 3},
				{"id": "t2", "text": "我必须一直表现很好，才配被认可。", "weight": 3},
				{"id": "t3", "text": "他们的期待会给我压力，但我的价值不该只靠表现来证明。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "压力", "intensity": 84},
				{"id": "e2", "label": "焦虑", "intensity": 76},
				{"id": "e3", "label": "疲惫", "intensity": 70},
			],
			"distortion_options": [
				{"id": Distortion.SHOULD_STATEMENTS, "weight": 3},
				{"id": Distortion.LABELING, "weight": 2},
				{"id": Distortion.BLACK_WHITE, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "他们确实对我提出了更高期待。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "期待存在，不等于我一旦没做到就整个人都让人失望。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "长期只靠紧绷来证明自己，反而更容易把人压垮。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "我可以追求进步，但不必用苛刻的方式一直逼迫自己。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["self_compassion", "cognitive_reframe", "accept_emotion"],
			"balanced_thought_options": [
				{"id": "b1", "text": "我会在意他们的期待，但我不需要把‘必须完美’当成唯一标准。", "weight": 3},
				{"id": "b2", "text": "追求更好可以存在，不过它不该等于不停否定现在的自己。", "weight": 3},
				{"id": "b3", "text": "如果我做不到最好，就说明我根本不值得被认可。", "weight": 1},
			],
			"feedback": _default_feedback("你在把想进步和必须靠苛责才有价值区分开。"),
		},
		{
			"id": "family_parent_emotion_dump",
			"scenario": SCENARIO_FAMILY,
			"title": "被家长情绪波及",
			"situation_text": "家长在外面受了气，回家后说话很冲，你只是问了一句就被怼得很难受。",
			"automatic_thoughts": [
				{"id": "t1", "text": "他们这样冲我，肯定是我又做错了什么。", "weight": 3},
				{"id": "t2", "text": "是不是我总是会把家里气氛弄得更糟。", "weight": 2},
				{"id": "t3", "text": "他们现在情绪很重，但这不一定是因为我本身有问题。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "害怕", "intensity": 71},
				{"id": "e2", "label": "委屈", "intensity": 78},
				{"id": "e3", "label": "紧张", "intensity": 74},
			],
			"distortion_options": [
				{"id": Distortion.PERSONALIZATION, "weight": 3},
				{"id": Distortion.MIND_READING, "weight": 2},
				{"id": Distortion.MAGNIFICATION, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "他们刚才确实把火气发到了我身上。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "对方情绪很冲，不等于起因就全部在我。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "他们今天在外面本来就积累了情绪，这可能影响了说话方式。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "我可以先保护好自己，不必立刻把对方的情绪都吞成自己的责任。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["accept_emotion", "find_evidence", "self_compassion"],
			"balanced_thought_options": [
				{"id": "b1", "text": "他们现在情绪失控让我很难受，但这不自动说明问题都出在我身上。", "weight": 3},
				{"id": "b2", "text": "我可以先拉开一点距离，等氛围缓下来再看要不要沟通。", "weight": 3},
				{"id": "b3", "text": "只要家里有人心情差，就一定是我害的。", "weight": 1},
			],
			"feedback": _default_feedback("你在把别人的情绪风暴和自己的责任边界分开。"),
		},
		{
			"id": "family_blame_self_for_tension",
			"scenario": SCENARIO_FAMILY,
			"title": "把紧张气氛都怪到自己头上",
			"situation_text": "最近家里一直有点压抑，你一想到这种气氛，就开始觉得是不是自己让大家都不开心。",
			"automatic_thoughts": [
				{"id": "t1", "text": "家里现在这样，大概都是因为我不够懂事。", "weight": 3},
				{"id": "t2", "text": "如果我再乖一点，家里就不会这么累了。", "weight": 2},
				{"id": "t3", "text": "我会受气氛影响，但一个家庭的压力通常不是由我一个人决定。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "内疚", "intensity": 81},
				{"id": "e2", "label": "压抑", "intensity": 72},
				{"id": "e3", "label": "无力", "intensity": 69},
			],
			"distortion_options": [
				{"id": Distortion.PERSONALIZATION, "weight": 3},
				{"id": Distortion.MAGNIFICATION, "weight": 2},
				{"id": Distortion.EMOTIONAL_REASONING, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "家里的气氛最近确实比较紧。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "家庭气氛通常受到很多人的压力、工作和相处方式影响。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "我现在很内疚，不代表这些压力真的都因我而起。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "把所有责任都揽过来，只会让我更累，不一定真的能帮助关系。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["find_evidence", "accept_emotion", "self_compassion"],
			"balanced_thought_options": [
				{"id": "b1", "text": "家里的紧张氛围会影响我，但我不需要把整个家庭系统都缩成‘都是我的错’。", "weight": 3},
				{"id": "b2", "text": "我可以关心家里的状态，同时保留对自己更公平的看法。", "weight": 3},
				{"id": "b3", "text": "只要家里不开心，就说明我没有做好孩子。", "weight": 1},
			],
			"feedback": _default_feedback("你在把内疚感和真实因果拆开来看。"),
		},
		{
			"id": "family_called_too_sensitive",
			"scenario": SCENARIO_FAMILY,
			"title": "表达感受却被说太敏感",
			"situation_text": "你鼓起勇气说自己被某句话伤到了，对方却回你一句：你怎么这么敏感。",
			"automatic_thoughts": [
				{"id": "t1", "text": "连我的感受都被这样说，说明我真的很矫情。", "weight": 3},
				{"id": "t2", "text": "以后我还是别表达了，反正不会被认真听。", "weight": 2},
				{"id": "t3", "text": "被这样回应会更受伤，但有感受不等于我就有问题。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "受伤", "intensity": 84},
				{"id": "e2", "label": "羞愧", "intensity": 63},
				{"id": "e3", "label": "退缩", "intensity": 71},
			],
			"distortion_options": [
				{"id": Distortion.LABELING, "weight": 3},
				{"id": Distortion.OVERGENERALIZATION, "weight": 2},
				{"id": Distortion.EMOTIONAL_REASONING, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "对方刚才确实说了我太敏感。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "别人用‘敏感’回应，不等于我的感受就一定不合理。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "这次沟通没被接住，不代表我以后所有表达都不会被听见。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "我可以换时间、换方式表达，而不是立刻否定自己有感受这件事。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["self_compassion", "cognitive_reframe", "accept_emotion"],
			"balanced_thought_options": [
				{"id": "b1", "text": "这句‘太敏感’让我更难受，但它不等于我的感受本身就是错的。", "weight": 3},
				{"id": "b2", "text": "我可以承认自己被刺痛了，同时慢慢找更容易被听见的表达方式。", "weight": 3},
				{"id": "b3", "text": "既然有人嫌我敏感，那我以后最好什么都别说。", "weight": 1},
			],
			"feedback": _default_feedback("你在把别人没有接住你的感受，和你是否有资格表达感受区分开。"),
		},
		{
			"id": "family_chores_unfair",
			"scenario": SCENARIO_FAMILY,
			"title": "家务分配让人委屈",
			"situation_text": "家里临时又把一堆家务交给你，你心里觉得不太公平，但也怕一开口就被说顶嘴。",
			"automatic_thoughts": [
				{"id": "t1", "text": "在这个家里，我的感受根本不重要。", "weight": 3},
				{"id": "t2", "text": "如果我拒绝一点，就一定会被骂不懂事。", "weight": 2},
				{"id": "t3", "text": "我现在觉得委屈是真的，但我还不确定沟通后一定会变成最坏情况。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "委屈", "intensity": 80},
				{"id": "e2", "label": "烦闷", "intensity": 70},
				{"id": "e3", "label": "紧张", "intensity": 66},
			],
			"distortion_options": [
				{"id": Distortion.MENTAL_FILTER, "weight": 3},
				{"id": Distortion.FORTUNE_TELLING, "weight": 2},
				{"id": Distortion.BLACK_WHITE, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "这些家务现在确实落到了我身上。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "我现在更容易只盯着不公平的部分，而忽略其他可能的沟通空间。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "担心被骂可以理解，但结果还没有真的发生。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "我可以先提出一个更具体的分工建议，而不是只能忍着或爆发。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["find_evidence", "perspective_shift", "accept_emotion"],
			"balanced_thought_options": [
				{"id": "b1", "text": "我现在觉得不公平很正常，但这不等于我的处境已经完全没有商量空间。", "weight": 3},
				{"id": "b2", "text": "与其把委屈闷成结论，我更可以想想要怎样把需求说得具体一点。", "weight": 3},
				{"id": "b3", "text": "只要我一表达不满，就一定会把事情闹得更糟。", "weight": 1},
			],
			"feedback": _default_feedback("你在把委屈本身和对未来沟通结果的预演分开。"),
		},
		{
			"id": "family_interest_not_understood",
			"scenario": SCENARIO_FAMILY,
			"title": "兴趣和选择不被理解",
			"situation_text": "你认真提起自己想尝试的方向，家长却直接说这条路不靠谱，让你别乱想。",
			"automatic_thoughts": [
				{"id": "t1", "text": "他们这样否定，说明我的想法真的很幼稚。", "weight": 3},
				{"id": "t2", "text": "只要不是他们认可的路，我就没资格认真考虑。", "weight": 2},
				{"id": "t3", "text": "被泼冷水会让我怀疑自己，但不等于我的兴趣就没有价值。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "失落", "intensity": 82},
				{"id": "e2", "label": "挫败", "intensity": 74},
				{"id": "e3", "label": "不被理解", "intensity": 79},
			],
			"distortion_options": [
				{"id": Distortion.LABELING, "weight": 3},
				{"id": Distortion.BLACK_WHITE, "weight": 2},
				{"id": Distortion.DISCOUNTING_POSITIVES, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "他们刚才确实直接否定了这条路。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "他们的担心可能来自现实顾虑，不等于我的兴趣本身很幼稚。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "一个方向值不值得探索，需要更多信息，而不是一句否定就能定案。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "我可以继续收集资料、整理理由，再决定怎么和他们讨论。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["find_evidence", "cognitive_reframe", "self_compassion"],
			"balanced_thought_options": [
				{"id": "b1", "text": "他们现在不理解这条路，会让我泄气，但这不等于我的兴趣就不值得认真看待。", "weight": 3},
				{"id": "b2", "text": "与其立刻否定自己，我更可以先把这条路了解得更具体一些。", "weight": 3},
				{"id": "b3", "text": "只要家里不同意，就说明我的想法根本不配被考虑。", "weight": 1},
			],
			"feedback": _default_feedback("你在把他人的质疑和自己探索方向的权利分开。"),
		},
	]

static func _social_encounters() -> Array[Dictionary]:
	return [
		{
			"id": "social_message_not_replied",
			"scenario": SCENARIO_SOCIAL,
			"title": "消息迟迟没回",
			"situation_text": "你给朋友发了消息，过了很久都没收到回复，聊天框一直停在已发送。",
			"automatic_thoughts": [
				{"id": "t1", "text": "Ta不回我，肯定是嫌我烦了。", "weight": 3},
				{"id": "t2", "text": "是不是我刚才哪里说错了。", "weight": 2},
				{"id": "t3", "text": "我现在会多想，但没回复不一定等于负面态度。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "不安", "intensity": 79},
				{"id": "e2", "label": "焦虑", "intensity": 73},
				{"id": "e3", "label": "失落", "intensity": 64},
			],
			"distortion_options": [
				{"id": Distortion.MIND_READING, "weight": 3},
				{"id": Distortion.FORTUNE_TELLING, "weight": 2},
				{"id": Distortion.PERSONALIZATION, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "对方到现在确实还没回复。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "我并不知道对方此刻在做什么，也不知道没回的具体原因。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "回复变慢可能和忙碌、没看到、晚点再回等很多因素有关。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "我现在的不安是真的，但它不等于我已经被讨厌。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["find_evidence", "accept_emotion", "cognitive_reframe"],
			"balanced_thought_options": [
				{"id": "b1", "text": "消息没回会让我不安，但我还没有足够证据把它解释成‘Ta嫌我烦’。", "weight": 3},
				{"id": "b2", "text": "我可以先让自己从聊天框里退一步，而不是立刻补上最糟解释。", "weight": 3},
				{"id": "b3", "text": "只要对方没秒回，就说明我在Ta心里很讨厌。", "weight": 1},
			],
			"feedback": _default_feedback("你在把等待中的不安和对他人想法的猜测区分开。"),
		},
		{
			"id": "social_ignored_in_group_chat",
			"scenario": SCENARIO_SOCIAL,
			"title": "群聊里像被略过",
			"situation_text": "你在群里发了一句话，后面大家继续聊别的话题，没人接你的内容。",
			"automatic_thoughts": [
				{"id": "t1", "text": "他们都故意无视我。", "weight": 3},
				{"id": "t2", "text": "我发什么都不会有人想接。", "weight": 2},
				{"id": "t3", "text": "这一刻像被略过了，但不一定是故意针对我。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "尴尬", "intensity": 76},
				{"id": "e2", "label": "失落", "intensity": 72},
				{"id": "e3", "label": "退缩", "intensity": 65},
			],
			"distortion_options": [
				{"id": Distortion.MIND_READING, "weight": 3},
				{"id": Distortion.OVERGENERALIZATION, "weight": 2},
				{"id": Distortion.MENTAL_FILTER, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "我那条消息确实没有被接到。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "群聊节奏很快，没接到不一定说明别人是在故意忽视我。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "一次没被回应，不足以证明我发什么都不会有人理。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "我现在更容易只盯着这次落空，而忽略之前也有被接住的时候。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["find_evidence", "perspective_shift", "self_compassion"],
			"balanced_thought_options": [
				{"id": "b1", "text": "这次在群里被略过去让我尴尬，但我不需要立刻把它解释成‘大家都在排斥我’。", "weight": 3},
				{"id": "b2", "text": "我可以承认这一下不好受，同时提醒自己群聊本来就很容易漏消息。", "weight": 3},
				{"id": "b3", "text": "只要群里没人接话，就说明我说什么都很讨人嫌。", "weight": 1},
			],
			"feedback": _default_feedback("你在把一次社交落空和更大的自我结论分开。"),
		},
		{
			"id": "social_not_invited",
			"scenario": SCENARIO_SOCIAL,
			"title": "朋友没约自己",
			"situation_text": "你后来才知道几个朋友周末一起出去玩了，但没有叫你。",
			"automatic_thoughts": [
				{"id": "t1", "text": "他们没叫我，说明我根本不算他们的朋友。", "weight": 3},
				{"id": "t2", "text": "是不是大家其实一直都不太想带我。", "weight": 2},
				{"id": "t3", "text": "没被叫上会很刺痛，但这件事不一定能直接定义整段关系。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "难过", "intensity": 80},
				{"id": "e2", "label": "失落", "intensity": 77},
				{"id": "e3", "label": "被排除", "intensity": 74},
			],
			"distortion_options": [
				{"id": Distortion.OVERGENERALIZATION, "weight": 3},
				{"id": Distortion.MIND_READING, "weight": 2},
				{"id": Distortion.DISCOUNTING_POSITIVES, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "这次活动我确实没有被叫上。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "一次没被邀请会让人受伤，但不一定足以说明我根本不算朋友。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "活动是怎么约成的、人数限制、临时起意等情况，我目前并不清楚。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "如果我只盯着这一次，很容易忽略之前关系里真实存在的连结。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["find_evidence", "self_compassion", "perspective_shift"],
			"balanced_thought_options": [
				{"id": "b1", "text": "这次没被约上确实让我受伤，但它还不足以直接证明我对他们毫无位置。", "weight": 3},
				{"id": "b2", "text": "我可以先照顾被落下的感觉，再决定要不要用更具体的方式了解情况。", "weight": 3},
				{"id": "b3", "text": "只要有一次没被叫上，就说明我一直都是多余的。", "weight": 1},
			],
			"feedback": _default_feedback("你在把被排除感和对整段关系的结论区分开。"),
		},
		{
			"id": "social_see_others_together",
			"scenario": SCENARIO_SOCIAL,
			"title": "看见别人结伴",
			"situation_text": "走廊上你看见几个同学聊得很开心地走在一起，自己一下子觉得特别格格不入。",
			"automatic_thoughts": [
				{"id": "t1", "text": "大家都有自己的圈子，只有我融不进去。", "weight": 3},
				{"id": "t2", "text": "我这样的人本来就很难被喜欢。", "weight": 2},
				{"id": "t3", "text": "我现在很孤单，但这不等于我永远只能站在外面。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "孤单", "intensity": 82},
				{"id": "e2", "label": "自卑", "intensity": 74},
				{"id": "e3", "label": "失落", "intensity": 70},
			],
			"distortion_options": [
				{"id": Distortion.MENTAL_FILTER, "weight": 3},
				{"id": Distortion.LABELING, "weight": 2},
				{"id": Distortion.OVERGENERALIZATION, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "我刚刚确实看到别人聊得很热闹。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "看到别人结伴，并不能直接证明我永远融不进去。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "我此刻只看到别人热闹的一面，没有看到他们关系里的全部。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "孤单感很真实，但它不是对我社交价值的客观判决。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["perspective_shift", "self_compassion", "accept_emotion"],
			"balanced_thought_options": [
				{"id": "b1", "text": "看见别人结伴会刺到我的孤单感，但这不等于我注定被排在外面。", "weight": 3},
				{"id": "b2", "text": "我现在更像是被某个画面触发了，而不是看见了关于自己的全部真相。", "weight": 3},
				{"id": "b3", "text": "只要我一个人走着，就说明没人会真心喜欢我。", "weight": 1},
			],
			"feedback": _default_feedback("你在把瞬间被触发的孤单感和对自己的固定标签分开。"),
		},
		{
			"id": "social_post_talk_overthinking",
			"scenario": SCENARIO_SOCIAL,
			"title": "发言后反复复盘",
			"situation_text": "你在聊天时接了一句，回去后却一直在想自己刚才是不是说得很尴尬。",
			"automatic_thoughts": [
				{"id": "t1", "text": "我刚才那句话一定很社死，大家肯定都记住了。", "weight": 3},
				{"id": "t2", "text": "我果然不太会聊天。", "weight": 2},
				{"id": "t3", "text": "我会因为尴尬感放大刚才那一刻，但别人未必像我一样反复回想。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "尴尬", "intensity": 83},
				{"id": "e2", "label": "焦虑", "intensity": 70},
				{"id": "e3", "label": "懊恼", "intensity": 75},
			],
			"distortion_options": [
				{"id": Distortion.MAGNIFICATION, "weight": 3},
				{"id": Distortion.MIND_READING, "weight": 2},
				{"id": Distortion.LABELING, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "我现在确实在反复想刚才那句话。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "我自己在反复复盘，不代表别人也把那句放得同样大。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "一次聊天里的小卡顿，不足以证明我整体都不会聊天。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "尴尬是社交里常见的体验，不需要被立刻变成永久标签。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["accept_emotion", "cognitive_reframe", "find_evidence"],
			"balanced_thought_options": [
				{"id": "b1", "text": "我现在很在意刚才的发言，但我可能正在用自己的尴尬感把它越放越大。", "weight": 3},
				{"id": "b2", "text": "就算那一句不够自然，也不代表我整个人都很不会社交。", "weight": 3},
				{"id": "b3", "text": "只要说错一句，别人就会一直记得我有多尴尬。", "weight": 1},
			],
			"feedback": _default_feedback("你在把瞬间的尴尬放回更真实的社交比例里。"),
		},
		{
			"id": "social_conflict_friendship_over",
			"scenario": SCENARIO_SOCIAL,
			"title": "和朋友闹别扭后担心完了",
			"situation_text": "你和朋友因为一件小事气氛僵了，分开后你脑子里一直在想这段关系是不是结束了。",
			"automatic_thoughts": [
				{"id": "t1", "text": "我们都这样了，关系肯定完了。", "weight": 3},
				{"id": "t2", "text": "Ta现在一定很烦我，不想再理我。", "weight": 2},
				{"id": "t3", "text": "这次别扭让我害怕，但冲突不一定自动等于关系结束。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "害怕", "intensity": 80},
				{"id": "e2", "label": "难过", "intensity": 74},
				{"id": "e3", "label": "不安", "intensity": 77},
			],
			"distortion_options": [
				{"id": Distortion.CATASTROPHIZING, "weight": 3},
				{"id": Distortion.MIND_READING, "weight": 2},
				{"id": Distortion.FORTUNE_TELLING, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "我们刚才确实闹得有点僵。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "一次别扭很难受，但不自动等于整段关系彻底结束。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "我现在无法直接知道对方是不是已经决定不再理我。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "很多关系都需要在情绪过去后重新沟通，而不是当场就有最终结论。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["find_evidence", "accept_emotion", "cognitive_reframe"],
			"balanced_thought_options": [
				{"id": "b1", "text": "这次冲突让我很怕失去Ta，但我还没有证据说明关系已经走到终点。", "weight": 3},
				{"id": "b2", "text": "我可以先让情绪退一点，再看这段关系需要怎样的修补。", "weight": 3},
				{"id": "b3", "text": "只要和朋友闹僵一次，就说明我们以后再也回不去了。", "weight": 1},
			],
			"feedback": _default_feedback("你在把冲突当下的强烈感觉和关系的长期结论分开。"),
		},
		{
			"id": "social_hurt_by_joke",
			"scenario": SCENARIO_SOCIAL,
			"title": "被玩笑刺到",
			"situation_text": "别人开了个关于你的玩笑，周围有人笑了，你一下子觉得脸上发热。",
			"automatic_thoughts": [
				{"id": "t1", "text": "他们笑成这样，肯定都看不起我。", "weight": 3},
				{"id": "t2", "text": "我在大家眼里就是个笑话。", "weight": 2},
				{"id": "t3", "text": "这句玩笑让我受伤，但它不一定等于所有人都在否定我。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "难堪", "intensity": 84},
				{"id": "e2", "label": "受伤", "intensity": 78},
				{"id": "e3", "label": "生气", "intensity": 71},
			],
			"distortion_options": [
				{"id": Distortion.MIND_READING, "weight": 3},
				{"id": Distortion.LABELING, "weight": 2},
				{"id": Distortion.MAGNIFICATION, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "刚才确实有人笑了。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "别人笑，可能是顺着气氛反应，不等于每个人都在看不起我。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "一句玩笑越界会让人受伤，但它不足以定义我在所有人心里的位置。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "我可以承认这句玩笑不舒服，同时保留对自己更稳的看法。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["self_compassion", "find_evidence", "accept_emotion"],
			"balanced_thought_options": [
				{"id": "b1", "text": "这句玩笑确实刺到我了，但我不需要把那一瞬间的笑声翻译成‘所有人都看不起我’。", "weight": 3},
				{"id": "b2", "text": "我可以先照顾被刺痛的感觉，再判断要不要设边界或换开这段气氛。", "weight": 3},
				{"id": "b3", "text": "只要别人拿我开玩笑，就说明我本身就是个笑话。", "weight": 1},
			],
			"feedback": _default_feedback("你在把被冒犯的体验和对自己整个人的标签区分开。"),
		},
		{
			"id": "social_feel_weird_in_conversation",
			"scenario": SCENARIO_SOCIAL,
			"title": "社交时觉得自己很怪",
			"situation_text": "大家聊天时你一时想不到要接什么，站在旁边越站越觉得自己怪怪的。",
			"automatic_thoughts": [
				{"id": "t1", "text": "我连话都接不上，果然是个很怪的人。", "weight": 3},
				{"id": "t2", "text": "别人肯定一眼就看出来我不合群。", "weight": 2},
				{"id": "t3", "text": "我现在有点卡住，但卡住不等于我本身就很奇怪。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "局促", "intensity": 78},
				{"id": "e2", "label": "自卑", "intensity": 72},
				{"id": "e3", "label": "紧张", "intensity": 74},
			],
			"distortion_options": [
				{"id": Distortion.LABELING, "weight": 3},
				{"id": Distortion.MIND_READING, "weight": 2},
				{"id": Distortion.EMOTIONAL_REASONING, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "我刚才确实一时不知道接什么。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "社交里卡壳是常见状态，不足以证明我整个人都很怪。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "我感觉自己格格不入，不代表别人此刻真的都在这样看我。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "就算当下没接上话，我仍然可以先观察、等更自然的时机再加入。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["self_compassion", "accept_emotion", "find_evidence"],
			"balanced_thought_options": [
				{"id": "b1", "text": "我现在有点卡住很正常，但这不等于我本身就是一个很怪的人。", "weight": 3},
				{"id": "b2", "text": "我可以允许自己先不完美地待在这里，而不是急着给自己贴标签。", "weight": 3},
				{"id": "b3", "text": "只要我没法顺利接话，就说明我根本不适合社交。", "weight": 1},
			],
			"feedback": _default_feedback("你在把当下的社交卡顿和对自己的固定标签分开。"),
		},
		{
			"id": "social_discount_positive_signal",
			"scenario": SCENARIO_SOCIAL,
			"title": "把友好信号当客套",
			"situation_text": "有同学主动跟你打招呼，还问你要不要一起走一段路，你嘴上答应了，心里却觉得对方只是客套。",
			"automatic_thoughts": [
				{"id": "t1", "text": "Ta只是出于礼貌，不是真的想和我待在一起。", "weight": 3},
				{"id": "t2", "text": "别人对我稍微好一点，多半都是表面功夫。", "weight": 2},
				{"id": "t3", "text": "我会怀疑这份善意，但主动靠近本身也是一个真实信号。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "不自在", "intensity": 66},
				{"id": "e2", "label": "怀疑", "intensity": 72},
				{"id": "e3", "label": "期待又退缩", "intensity": 61},
			],
			"distortion_options": [
				{"id": Distortion.DISCOUNTING_POSITIVES, "weight": 3},
				{"id": Distortion.MIND_READING, "weight": 2},
				{"id": Distortion.MENTAL_FILTER, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "对方刚才确实主动来和我说话了。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "我现在把它解释成客套，但我没有直接证据证明对方并不真诚。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "如果我总把友好都过滤掉，就更难看见关系里已经存在的连接。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "先把这次互动当作一个普通的积极信号，会比立刻否定它更公平。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["perspective_shift", "find_evidence", "self_compassion"],
			"balanced_thought_options": [
				{"id": "b1", "text": "我会下意识怀疑这份友好，但它也可能就是一次真实的靠近。", "weight": 3},
				{"id": "b2", "text": "先允许积极信号存在，不代表我要立刻把关系想得很满。", "weight": 3},
				{"id": "b3", "text": "只要我一感觉到不自在，就说明别人对我的友善肯定都是装的。", "weight": 1},
			],
			"feedback": _default_feedback("你在练习不把出现的善意立刻过滤掉。"),
		},
		{
			"id": "social_afraid_to_invite",
			"scenario": SCENARIO_SOCIAL,
			"title": "不敢主动邀请",
			"situation_text": "你很想约同学一起做点什么，但消息打了又删，脑子里先浮现出被拒绝的画面。",
			"automatic_thoughts": [
				{"id": "t1", "text": "我一开口，对方大概只会觉得麻烦。", "weight": 3},
				{"id": "t2", "text": "如果被拒绝，就说明我真的没有人想靠近。", "weight": 2},
				{"id": "t3", "text": "害怕被拒绝很正常，但还没发出去之前，结果并没有真的发生。", "weight": 1},
			],
			"emotion_options": [
				{"id": "e1", "label": "紧张", "intensity": 81},
				{"id": "e2", "label": "害怕", "intensity": 76},
				{"id": "e3", "label": "犹豫", "intensity": 69},
			],
			"distortion_options": [
				{"id": Distortion.FORTUNE_TELLING, "weight": 3},
				{"id": Distortion.MIND_READING, "weight": 2},
				{"id": Distortion.CATASTROPHIZING, "weight": 2},
			],
			"evidence_cards": [
				{"id": "ev1", "text": "我现在确实很怕收到拒绝。", "kind": "support", "weight": 1},
				{"id": "ev2", "text": "我还没有发出邀请，所以对方会怎么回应目前只是预测。", "kind": "counter", "weight": 3},
				{"id": "ev3", "text": "就算对方这次不方便，也不等于我这个人就没人想靠近。", "kind": "counter", "weight": 3},
				{"id": "ev4", "text": "我可以先发一个更轻一点的邀请，而不是在脑内一次性预演最坏结局。", "kind": "counter", "weight": 2},
			],
			"skill_options": ["find_evidence", "accept_emotion", "cognitive_reframe"],
			"balanced_thought_options": [
				{"id": "b1", "text": "我现在会怕被拒绝，但在真正开口前，我并不知道结果会怎样。", "weight": 3},
				{"id": "b2", "text": "主动邀请本身就需要一点勇气，它不该被我自动翻译成‘自取其辱’。", "weight": 3},
				{"id": "b3", "text": "只要我主动一次被拒绝，就说明以后谁都不会想和我来往。", "weight": 1},
			],
			"feedback": _default_feedback("你在把对拒绝的预演和还没发生的现实区分开。"),
		},
	]

static func _default_feedback(reframe_feedback: String) -> Dictionary:
	return {
		"situation": "先把情境放在眼前，不急着立刻下结论。",
		"automatic_thought": "你正在识别脑中最先冒出来的想法。",
		"emotion": "给情绪命名，会帮助你更稳定地观察它。",
		"distortion": "这是一个可以继续检视的偏差角度。",
		"evidence": "把支持证据和反证都摆出来，能让视角更完整。",
		"reframe": reframe_feedback,
		"rerate": "情绪强度只要有一点变化，就说明新的理解正在形成。",
	}
