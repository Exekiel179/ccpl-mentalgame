## ScenarioDatabase — all built-in sentences grouped by scenario.
## Access via ScenarioDatabase.get_sentences(scenario_name).
class_name ScenarioDatabase
extends RefCounted

static func get_all_scenarios() -> Array[String]:
	return ["学业压力", "家庭矛盾", "社交压力"]

static func get_sentences(scenario: String) -> Array[Dictionary]:
	match scenario:
		"学业压力":
			return _academic()
		"家庭矛盾":
			return _family()
		"社交压力":
			return _social()
	return _academic()

static func _academic() -> Array[Dictionary]:
	return [
		{"text": "我考试不及格了", "category": "fact",    "explanation": "这是可验证的事实：你有一个具体的考试成绩。"},
		{"text": "我完蛋了",       "category": "thought", "explanation": "这是一种解读，不及格不等于人生终结。", "distortion": "灾难化思维"},
		{"text": "我天生就不聪明", "category": "thought", "explanation": "这是对自己的评判，不是客观事实。", "distortion": "标签化"},
		{"text": "老师批评了我",   "category": "fact",    "explanation": "老师确实说了某些话，这是可观察到的事件。"},
		{"text": "没人喜欢我",     "category": "thought", "explanation": "这是一种过度泛化的想法，缺乏证据支持。", "distortion": "过度泛化"},
		{"text": "这门课很难",     "category": "thought", "explanation": "难易是主观感受，不同人体验不同。", "distortion": "主观判断"},
		{"text": "我今天迟到了",   "category": "fact",    "explanation": "迟到是可记录的客观事件。"},
		{"text": "我永远学不会",   "category": "thought", "explanation": "\"永远\"是绝对化思维，属于认知扭曲。", "distortion": "绝对化思维"},
		{"text": "我交了作业",     "category": "fact",    "explanation": "交作业是可确认的行为。"},
		{"text": "大家都在嘲笑我", "category": "thought", "explanation": "这是一种心理投射，并非他人真实意图。", "distortion": "心理投射"},
	]

static func _family() -> Array[Dictionary]:
	return [
		{"text": "父母吵架了",       "category": "fact",    "explanation": "父母之间发生了争吵，这是观察到的事件。"},
		{"text": "都是我的错",       "category": "thought", "explanation": "把家庭问题归咎于自己是一种认知偏差。", "distortion": "自责归因"},
		{"text": "妈妈今天没理我",   "category": "fact",    "explanation": "妈妈的行为是可观察的，但原因需要确认。"},
		{"text": "爸爸不爱我",       "category": "thought", "explanation": "一次行为不能代表整体感情，这是解读。", "distortion": "以偏概全"},
		{"text": "我让家里人失望了", "category": "thought", "explanation": "这是对他人情感的主观推断。", "distortion": "读心术"},
		{"text": "家里经济有困难",   "category": "fact",    "explanation": "经济状况可以通过具体数据验证。"},
		{"text": "我是家里的负担",   "category": "thought", "explanation": "这是一种自我标签，不是客观评估。", "distortion": "标签化"},
		{"text": "父母没来参加活动", "category": "fact",    "explanation": "缺席是可观察的客观事件。"},
		{"text": "我永远达不到期望", "category": "thought", "explanation": "\"永远\"是绝对化，无法被事实证明。", "distortion": "绝对化思维"},
		{"text": "家里规定了门禁",   "category": "fact",    "explanation": "门禁时间是具体可验证的规定。"},
	]

static func _social() -> Array[Dictionary]:
	return [
		{"text": "朋友没回我消息",     "category": "fact",    "explanation": "消息未回复是可观察的事实。"},
		{"text": "他们不想和我玩",     "category": "thought", "explanation": "这是对他人意图的推测，可能有其他原因。", "distortion": "读心术"},
		{"text": "我在聚会上说错话了", "category": "fact",    "explanation": "说了某句话是客观发生的事件。"},
		{"text": "大家都讨厌我",       "category": "thought", "explanation": "这是过度泛化，无法被证实。", "distortion": "过度泛化"},
		{"text": "我被排除在群聊外",   "category": "fact",    "explanation": "不在群聊里是可验证的客观状态。"},
		{"text": "我很奇怪",           "category": "thought", "explanation": "\"奇怪\"是主观评价，不是事实描述。", "distortion": "标签化"},
		{"text": "同学没邀请我参加活动","category": "fact",   "explanation": "未被邀请是可确认的客观情况。"},
		{"text": "没人理解我",         "category": "thought", "explanation": "这是主观感受，不能等同于客观现实。", "distortion": "过度泛化"},
		{"text": "我今天和朋友见面了", "category": "fact",    "explanation": "见面是发生过的客观事件。"},
		{"text": "我肯定给他留下了坏印象","category": "thought","explanation": "这是对他人想法的推断，缺乏直接证据。", "distortion": "读心术"},
	]
