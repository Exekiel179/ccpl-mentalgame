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

static func get_flashcards() -> Array[Dictionary]:
	return [
		{
			"id": "restructure_basics",
			"title": "什么是认知重构？",
			"summary": "它的意思很简单：别急着相信脑子里冒出来的第一句话。",
			"detail": "认知重构不是逼自己立刻乐观，也不是假装没事。它更像是先停一下，看看自己刚刚在想什么，再问一句：这个想法一定是真的吗？有没有别的看法也说得通？",
			"layer": "基础认知卡",
			"tags": ["认知重构", "基础"],
			"scenario": "通用"
		},
		{
			"id": "fact_vs_thought",
			"title": "事实和想法要分开",
			"summary": "先看发生了什么，再看你怎么理解它。",
			"detail": "比如“我考试不及格了”是事实，因为成绩可以查到；“我完蛋了”是想法，因为这是你对这件事的解释。很多时候，真正让人难受的，不只是事情本身，而是我们脑中那句特别重的话。",
			"layer": "基础认知卡",
			"tags": ["事实 vs 想法", "核心技能"],
			"example_text": "我考试不及格了 / 我完蛋了",
			"scenario": "学业压力"
		},
		{
			"id": "catastrophizing",
			"title": "灾难化思维",
			"summary": "一出问题，脑子就自动往最坏的方向冲。",
			"detail": "比如一次失误之后，心里立刻冒出“全完了”“以后都没希望了”。这种想法来得很快，也很吓人，但它不一定是真的。你可以试着问自己：现在最可能发生的结果，真的有这么糟吗？",
			"layer": "基础认知卡",
			"tags": ["认知扭曲", "灾难化"],
			"distortion": "灾难化思维",
			"scenario": "学业压力"
		},
		{
			"id": "overgeneralization",
			"title": "过度泛化",
			"summary": "一次不顺，不代表以后都这样。",
			"detail": "比如被忽略过一次，就觉得“以后都没人会在乎我”。这类想法的问题在于，它把一个瞬间放大成了全部。把话改成“这一次让我很难受”，通常会更真实，也没那么压人。",
			"layer": "基础认知卡",
			"tags": ["认知扭曲", "过度泛化"],
			"distortion": "过度泛化",
			"scenario": "社交压力"
		},
		{
			"id": "mind_reading",
			"title": "读心术",
			"summary": "你在猜别人怎么想，但猜测不等于事实。",
			"detail": "像“他们一定讨厌我”“爸妈肯定对我很失望”这种念头，很多时候只是我们太紧张，于是自动把空白补成了最伤人的答案。更温和一点的说法是：我担心他们会这么想，但我现在其实还不知道。",
			"layer": "基础认知卡",
			"tags": ["认知扭曲", "读心术"],
			"distortion": "读心术",
			"scenario": "家庭矛盾"
		},
		{
			"id": "labeling",
			"title": "别急着给自己下结论",
			"summary": "做错一件事，不等于你整个人都糟糕。",
			"detail": "“我这次失败了”和“我是个失败的人”差很多。前一句是在说经历，后一句是在给自己贴标签。标签一贴上，人就很容易觉得没救了，所以更值得练习的是：把问题说清楚，而不是把自己说死。",
			"layer": "基础认知卡",
			"tags": ["认知扭曲", "标签化"],
			"distortion": "标签化",
			"scenario": "通用"
		},
		{
			"id": "balanced_self_talk",
			"title": "更平衡的自我对话",
			"summary": "不是硬夸自己，而是把话说得更真实一点。",
			"detail": "当你特别难受时，最有帮助的往往不是“我一定可以”，而是“我现在真的很慌，但我可以先把下一步做好”。这种说法不会否认痛苦，也更容易让人慢慢找回行动感。",
			"layer": "情绪安抚卡",
			"tags": ["自我对话", "调节"],
			"scenario": "通用"
		},
		{
			"id": "academic_pressure_question",
			"title": "学业压力大时，先问这一句",
			"summary": "我现在看到的是事实，还是我脑补出来的未来？",
			"detail": "成绩、作业、老师的反馈，这些都可能是真的压力来源。但“我以后肯定不行了”通常是大脑提前把最坏剧本演完了。先把已经发生的，和还没发生的分开，心里会轻一点。",
			"layer": "行动建议卡",
			"tags": ["学业压力", "自我提问"],
			"scenario": "学业压力"
		},
		{
			"id": "family_pressure_question",
			"title": "家庭冲突时，先别急着补剧情",
			"summary": "先看对方做了什么，再看你脑中加了什么。",
			"detail": "比如“妈妈今天没理我”是你看到的事；“她是不是不爱我了”是你心里补出来的解释。人在受伤的时候，很容易把解释越想越重。慢一点，把两者分开，会比较不容易被情绪卷走。",
			"layer": "行动建议卡",
			"tags": ["家庭矛盾", "自我提问"],
			"scenario": "家庭矛盾"
		},
		{
			"id": "social_pressure_question",
			"title": "社交压力里，别太快替别人下结论",
			"summary": "没被回复，真的不一定是在否定你。",
			"detail": "社交里最折磨人的地方，常常是信息不完整。对方晚回了一点、语气淡了一点，我们的大脑就开始自动填空，而且常常填的是最刺痛自己的版本。提醒自己一句“我现在知道得还不够多”，会有帮助。",
			"layer": "行动建议卡",
			"tags": ["社交压力", "自我提问"],
			"scenario": "社交压力"
		},
		{
			"id": "emotion_first",
			"title": "先照顾情绪，再处理问题",
			"summary": "人很难在情绪快淹没自己的时候想得特别清楚。",
			"detail": "如果你现在已经很难受了，不一定要马上把事情想明白。先让自己慢一点，喝口水、坐下来、呼吸几次，等情绪松一点，再回头看问题，通常会更容易。",
			"layer": "情绪安抚卡",
			"tags": ["情绪调节", "照顾自己"],
			"scenario": "通用"
		},
		{
			"id": "small_step",
			"title": "先做很小的一步也很好",
			"summary": "有时候，不是你不行，而是你一下想做太多了。",
			"detail": "当事情压得你喘不过气时，把目标缩小一点会更有帮助。不是“我今天要把一切都解决”，而是“我先做第一步”。小步并不丢脸，它常常是重新动起来的开始。",
			"layer": "行动建议卡",
			"tags": ["行动", "减压"],
			"scenario": "通用"
		},
		{
			"id": "self_compassion",
			"title": "对自己温柔一点，不是纵容",
			"summary": "你已经够辛苦了，不需要再用狠话逼自己。",
			"detail": "很多人以为只有骂自己、逼自己，才会进步。但事实上，过重的自责只会让人更累、更怕失败。温柔一点不是放弃，而是给自己留一点继续走下去的力气。",
			"layer": "情绪安抚卡",
			"tags": ["自我关怀", "陪伴"],
			"scenario": "通用"
		},
		{
			"id": "pause_before_believe",
			"title": "想法出现了，不代表必须相信它",
			"summary": "脑子里冒出来的话，只是一个念头，不一定是真相。",
			"detail": "有些想法来得特别快，像自动弹窗一样，比如“我又搞砸了”“没人会理解我”。你可以先把它当成一句出现过的话，而不是立刻当成结论。光是这点距离，就已经很有帮助。",
			"layer": "基础认知卡",
			"tags": ["认知重构", "练习"],
			"scenario": "通用"
		},
		{
			"id": "body_signal",
			"title": "身体紧了，心里的话也会变重",
			"summary": "累、饿、紧张的时候，大脑更容易往坏处想。",
			"detail": "如果你发现自己特别容易胡思乱想，也可以顺手检查一下：我是不是太累了？是不是太饿了？是不是已经撑太久了？有时候，先让身体缓一缓，心里的声音也会柔和一点。",
			"layer": "情绪安抚卡",
			"tags": ["身心连接", "觉察"],
			"scenario": "通用"
		},
		{
			"id": "not_all_or_nothing",
			"title": "不是只有“全好”或“全坏”",
			"summary": "很多事情其实都在中间，不必只剩两个极端。",
			"detail": "像“要么成功，要么失败”“要么被喜欢，要么被讨厌”这种想法，会让人特别累。现实通常没这么绝对。给自己多留一点“还可以再看”的空间，会轻松很多。",
			"layer": "基础认知卡",
			"tags": ["认知扭曲", "非黑即白"],
			"scenario": "通用"
		},
		{
			"id": "compare_gently",
			"title": "别总拿最脆弱的自己，去比别人最亮的时候",
			"summary": "比较很自然，但它常常不公平。",
			"detail": "你看到的，往往只是别人表现出来的样子；而你感受到的，却是自己最真实、最累的那一面。这样的比较，很容易越比越委屈。提醒自己：我看到的并不是全部。",
			"layer": "情绪安抚卡",
			"tags": ["比较", "自我关怀"],
			"scenario": "社交压力"
		},
		{
			"id": "rest_is_allowed",
			"title": "累了就休息，不代表你在偷懒",
			"summary": "休息不是退步，是让自己能继续走下去。",
			"detail": "如果你已经很累了，还一直逼自己硬撑，最后只会更难动起来。适当休息不是没用，也不是输给了懒惰。它更像是在告诉自己：我值得被照顾。",
			"layer": "情绪安抚卡",
			"tags": ["休息", "照顾自己"],
			"scenario": "通用"
		},
		{
			"id": "ask_for_help",
			"title": "开口求助，不等于你很弱",
			"summary": "有时候，愿意说“我需要一点帮助”，其实很勇敢。",
			"detail": "很多人撑得太久，是因为怕麻烦别人、怕显得自己不够好。可人本来就不是只靠自己一个人活着的。愿意求助，不是丢脸，而是在认真照顾自己。",
			"layer": "行动建议卡",
			"tags": ["支持", "勇气"],
			"scenario": "通用"
		},
		{
			"id": "academic_grade_not_identity",
			"title": "成绩会波动，但你不只是一张分数单",
			"summary": "成绩重要，但它不是你全部的价值。",
			"detail": "考得不好当然会难受，这很正常。可一个分数更多是在描述某一次表现，不是在定义你整个人。你可以在意成绩，但不用把它变成对自己的最终判决。",
			"layer": "行动建议卡",
			"tags": ["学业压力", "价值感"],
			"scenario": "学业压力"
		},
		{
			"id": "academic_progress",
			"title": "进步有时很慢，但慢不等于没在前进",
			"summary": "看不到立刻变化，不代表努力没有意义。",
			"detail": "很多学习上的成长，不会一下子让你感受到。它更像一点点堆起来的。今天懂一点，明天稳一点，后天再多一点。慢慢来，并不丢人。",
			"layer": "行动建议卡",
			"tags": ["学业压力", "成长"],
			"scenario": "学业压力"
		},
		{
			"id": "academic_teacher_feedback",
			"title": "被批评了，也不代表你被否定了",
			"summary": "老师的反馈，更多是在说这件事，不一定是在否定你这个人。",
			"detail": "被指出问题的时候，心里会难受很正常。但可以试着提醒自己：对方是在说这次作业、这次表现，不一定是在说“你不行”。把反馈和自我价值分开，会轻松一点。",
			"layer": "行动建议卡",
			"tags": ["学业压力", "反馈"],
			"scenario": "学业压力"
		},
		{
			"id": "family_emotion_not_all_yours",
			"title": "家里的情绪，不一定都要你来扛",
			"summary": "你会受影响，但不代表一切都该由你负责。",
			"detail": "家里有冲突时，很多人会下意识觉得“是不是因为我”“是不是我要把一切弄好”。可家庭里的情绪和问题，通常很复杂，不是一个人就能承担完的。你可以关心，但不必把全部都背在自己身上。",
			"layer": "行动建议卡",
			"tags": ["家庭矛盾", "边界"],
			"scenario": "家庭矛盾"
		},
		{
			"id": "family_love_expression",
			"title": "爱有时表达得笨，不代表它不存在",
			"summary": "有些家人不会好好表达，但这和“不在乎你”不是一回事。",
			"detail": "当然，不是所有受伤都能被一句“他们也是爱你的”轻轻带过。但有时候，对方的冷、急、不会说话，确实更多是他们自己的方式问题，而不一定是你不值得被爱。",
			"layer": "行动建议卡",
			"tags": ["家庭矛盾", "关系"],
			"scenario": "家庭矛盾"
		},
		{
			"id": "family_boundary",
			"title": "有边界感，不等于你不懂事",
			"summary": "保护自己，也是一种成熟。",
			"detail": "如果一段对话总让你受伤，稍微退开一点、晚一点回应、先照顾好自己，并不等于你冷漠。边界不是推开爱，而是在提醒彼此：我也需要被尊重。",
			"layer": "行动建议卡",
			"tags": ["家庭矛盾", "边界"],
			"scenario": "家庭矛盾"
		},
		{
			"id": "social_silence",
			"title": "沉默有很多种意思，不一定是在拒绝你",
			"summary": "对方没说话，未必是因为你不好。",
			"detail": "社交里最让人难受的，常常是那些没有答案的时刻。可沉默可能是忙、累、没想好怎么回，也可能真的只是没看到。别急着把它翻译成“我不值得被在乎”。",
			"layer": "行动建议卡",
			"tags": ["社交压力", "关系"],
			"scenario": "社交压力"
		},
		{
			"id": "social_not_everyone",
			"title": "不是所有人都要喜欢你，你也依然值得被喜欢",
			"summary": "被谁喜欢，从来都不是一个人的全部价值。",
			"detail": "有人和你合得来，也会有人和你不那么合得来，这很正常。关系本来就有匹配度，不是你只要足够好，就一定能得到所有人的喜欢。",
			"layer": "行动建议卡",
			"tags": ["社交压力", "价值感"],
			"scenario": "社交压力"
		},
		{
			"id": "social_one_moment",
			"title": "一次尴尬，不会定义你这个人",
			"summary": "有点别扭、有点失误，真的很常见。",
			"detail": "你可能会反复回想自己说错的一句话，觉得别人一定记得很清楚。可大多数人其实没有一直盯着你。就算真的有点尴尬，那也只是一个瞬间，不是你的全部。",
			"layer": "行动建议卡",
			"tags": ["社交压力", "放松"],
			"scenario": "社交压力"
		},
		{
			"id": "allow_mixed_feelings",
			"title": "你可以一边难过，一边慢慢变好",
			"summary": "情绪不需要立刻消失，成长也还是会发生。",
			"detail": "很多人会因为“我怎么还这么难受”而更自责。其实，难过并不代表你没有进步。你可以带着一点委屈、一点害怕，还是继续往前走。",
			"layer": "情绪安抚卡",
			"tags": ["情绪", "陪伴"],
			"scenario": "通用"
		},
		{
			"id": "today_is_enough",
			"title": "今天能撑到这里，已经很不容易了",
			"summary": "有些日子里，能把今天过完就已经值得被肯定。",
			"detail": "不是每天都要很厉害，也不是每天都要高效发光。有时候，你只是很累，但还是把这一天走到了这里。这已经说明你真的很努力了。",
			"layer": "情绪安抚卡",
			"tags": ["陪伴", "肯定"],
			"scenario": "通用"
		},
		{
			"id": "breathe_and_return",
			"title": "当脑子很乱时，先回到呼吸里",
			"summary": "不用马上解决一切，先把自己接住。",
			"detail": "如果你现在脑子特别吵、特别急，先不用逼自己马上想清楚。试试看，把注意力放到一次吸气、一次呼气上。哪怕只有几十秒，也是在对自己说：我还在这里，我可以慢一点。",
			"layer": "情绪安抚卡",
			"tags": ["呼吸", "安稳自己"],
			"scenario": "通用"
		},
		{
			"id": "future_not_written",
			"title": "未来还没写完，不要太早替自己宣判",
			"summary": "眼前这一页很难，不代表后面都没有转机。",
			"detail": "当人很低落的时候，很容易把“现在很难”听成“以后也不会好了”。可未来不是一次心情就能决定的。哪怕今天只多留一点空间给明天，也已经很好。",
			"layer": "情绪安抚卡",
			"tags": ["希望", "认知重构"],
			"scenario": "通用"
		},
		{
			"id": "bullying_not_your_fault",
			"title": "被霸凌，不是你的错",
			"summary": "先把责任放回伤害人的那一边，而不是全压在自己身上。",
			"detail": "霸凌之所以让人痛，不只是因为发生了什么，还因为人很容易开始怀疑自己。但无论别人怎么取笑、孤立、威胁或传播谣言，做错事的都不是你。先记住这一点，才更有力气去求助和保护自己。",
			"layer": "危机支持卡",
			"tags": ["校园欺凌", "自我保护"],
			"scenario": "社交压力"
		},
		{
			"id": "bullying_keep_evidence",
			"title": "遇到霸凌，先留证据",
			"summary": "截图、录音、保留聊天记录，能帮你更清楚地说明发生了什么。",
			"detail": "如果有人在群里辱骂你、传播隐私、发威胁信息，先别急着一个人扛。把聊天记录、截图、时间、地点、目击者先记下来。证据不是为了“闹大”，而是为了让可信赖的大人和学校能更快看清情况、帮你处理。",
			"layer": "危机支持卡",
			"tags": ["校园欺凌", "证据"],
			"scenario": "社交压力"
		},
		{
			"id": "bullying_find_adult",
			"title": "被欺负时，尽快告诉可信赖的大人",
			"summary": "老师、班主任、家长、心理老师，都可以是你不用一个人扛的对象。",
			"detail": "霸凌最让人难受的一点，是它常常让人觉得“说了也没用”。但越是持续发生、越是让你害怕，越要尽快告诉可信赖的大人。你不需要把话说得很完整，只要先说“我最近被人一直针对，我有点害怕，想请你帮我”。这已经很重要。",
			"layer": "危机支持卡",
			"tags": ["校园欺凌", "求助"],
			"scenario": "社交压力"
		},
		{
			"id": "bullying_public_space",
			"title": "优先待在更安全、更公开的地方",
			"summary": "先减少自己单独面对危险的机会。",
			"detail": "如果你知道某些走廊、厕所、楼梯口、放学路上容易出事，可以优先选择更明亮、更有人在的地方，尽量和同学、朋友、老师一起走。先让自己更安全，不是懦弱，而是在保护自己。",
			"layer": "危机支持卡",
			"tags": ["校园欺凌", "安全"],
			"scenario": "社交压力"
		},
		{
			"id": "bullying_do_not_meet_alone",
			"title": "别一个人去赴“谈谈”的约",
			"summary": "如果你已经感觉不对劲，就别让自己独自处在更危险的场景里。",
			"detail": "有人说“出来聊聊”“放学见”，如果这让你觉得害怕，不需要硬着头皮去。你可以直接找老师、保安、家长或可信赖的大人说明情况。安全比面子重要得多。",
			"layer": "危机支持卡",
			"tags": ["校园欺凌", "边界"],
			"scenario": "社交压力"
		},
		{
			"id": "bullying_block_online_harm",
			"title": "网络骚扰也算伤害",
			"summary": "拉黑、举报、保留记录，都不是小题大做。",
			"detail": "如果有人在网上持续辱骂你、发恶意内容、传播照片或隐私，这不是“开玩笑”，而是明确的伤害。先截图保存，再用平台的拉黑、举报功能，同时把情况告诉可信赖的大人。你没有义务继续忍着看这些内容。",
			"layer": "危机支持卡",
			"tags": ["校园欺凌", "网络安全"],
			"scenario": "社交压力"
		},
		{
			"id": "bullying_friend_support",
			"title": "如果朋友被霸凌，你可以陪他去求助",
			"summary": "有时候，一个陪伴的人，会让开口变得容易很多。",
			"detail": "如果你的朋友正在被欺负，而他不敢说，你可以做的很重要：陪他去找老师、心理老师、家长，帮他一起整理发生了什么。你不需要一个人解决问题，但你可以成为那个让他没那么孤单的人。",
			"layer": "危机支持卡",
			"tags": ["校园欺凌", "支持朋友"],
			"scenario": "社交压力"
		},
		{
			"id": "suicide_thoughts_need_help",
			"title": "如果你开始想“不如不要活了”，这不是小事",
			"summary": "这说明你现在已经很痛了，值得立刻得到帮助。",
			"detail": "当一个人开始反复想到“不如消失”“不想活了”，最重要的不是逼自己立刻想开，而是马上让自己别一个人扛。请尽快联系可信赖的大人、家长、老师、心理老师，或者当地的危机热线与紧急服务。你现在需要的是支持，不是继续硬撑。",
			"layer": "危机支持卡",
			"tags": ["自杀危机", "立即求助"],
			"scenario": "通用"
		},
		{
			"id": "suicide_not_alone",
			"title": "有自伤或自杀冲动时，先别独处",
			"summary": "先把自己放到有人在、能被照顾到的地方。",
			"detail": "如果你现在已经很想伤害自己，请优先去找一个可信赖的大人、朋友、家人，或者去老师办公室、值班室、保安室、医院等有人能照应的地方。先让自己不单独待着，比什么都重要。",
			"layer": "危机支持卡",
			"tags": ["自杀危机", "安全"],
			"scenario": "通用"
		},
		{
			"id": "suicide_remove_means",
			"title": "先把危险东西挪远一点",
			"summary": "减少冲动能立刻接触到危险物品的机会。",
			"detail": "如果你有强烈的自伤或自杀冲动，先尽量让自己远离刀片、药物、绳子或其他可能伤害自己的东西，并请身边可信赖的人帮你保管。不是因为你“控制不住自己很可怕”，而是因为你值得被多保护一点。",
			"layer": "危机支持卡",
			"tags": ["自杀危机", "安全计划"],
			"scenario": "通用"
		},
		{
			"id": "suicide_tell_exact_words",
			"title": "求助时，可以把最真实的话直接说出来",
			"summary": "越具体，别人越容易知道现在需要立刻帮你。",
			"detail": "如果你已经想到要伤害自己，不需要先把话修饰得“没那么严重”。你可以直接说：“我现在有点担心自己会做傻事，能不能先陪着我，帮我联系大人或医生？”这不是吓人，这是在认真保护自己。",
			"layer": "危机支持卡",
			"tags": ["自杀危机", "沟通"],
			"scenario": "通用"
		},
		{
			"id": "suicide_friend_confide",
			"title": "朋友说想自杀时，不要一个人保守秘密",
			"summary": "先陪伴，再尽快告诉能真正提供帮助的大人。",
			"detail": "如果朋友跟你说“我不想活了”，先认真对待，不要当成玩笑。陪着他，不要让他独处，并尽快告诉家长、老师、心理老师、校方或其他能立刻介入的大人。保密在这种时候不是保护，安全才是。",
			"layer": "危机支持卡",
			"tags": ["自杀危机", "支持朋友"],
			"scenario": "通用"
		},
		{
			"id": "helpline_local_resources",
			"title": "记不住号码也没关系，先找当地危机援助",
			"summary": "当下最重要的是立刻连上人，而不是背下所有信息。",
			"detail": "如果你正在危险里，优先联系当地紧急服务、医院急诊、学校心理中心、心理援助热线，或让身边可信赖的大人帮你联系。求助不一定要一次就做得很标准，先把信息传出去，就是很关键的一步。",
			"layer": "危机支持卡",
			"tags": ["热线", "紧急援助"],
			"scenario": "通用"
		},
		{
			"id": "helpline_write_down",
			"title": "把求助方式提前写下来，会更安心",
			"summary": "难受的时候，人很容易一下子想不起该找谁。",
			"detail": "你可以提前在手机备忘录里写下几个名字和联系方式：家长、老师、班主任、心理老师、亲近的亲友、附近医院、当地心理援助热线。等真的难受起来时，就不用一边崩溃一边想“我到底该找谁”。",
			"layer": "危机支持卡",
			"tags": ["热线", "安全计划"],
			"scenario": "通用"
		},
		{
			"id": "help_seek_campus_counselor",
			"title": "学校里的心理老师，也可以是求助对象",
			"summary": "不一定要等到“特别严重”才去找。",
			"detail": "很多人会觉得“只有快崩溃了才能找心理老师”。其实不是。只要你已经持续难受、睡不好、怕上学、常常哭、总想逃开，就已经值得去找学校里的心理老师、辅导员或班主任聊一聊。早点求助，往往更有帮助。",
			"layer": "行动建议卡",
			"tags": ["求助", "学校资源"],
			"scenario": "通用"
		},
		{
			"id": "help_seek_medical_support",
			"title": "当情绪已经影响到睡眠吃饭时，可以考虑就医",
			"summary": "求助医生不是夸张，而是在认真照顾自己。",
			"detail": "如果你已经持续失眠、吃不下、胸口总发紧、常常惊恐、几乎没法学习生活，除了找老师或家人，也可以请他们陪你去医院精神心理科或身心科看看。看医生不代表你“有问题”，而是你现在确实需要专业支持。",
			"layer": "危机支持卡",
			"tags": ["就医", "专业支持"],
			"scenario": "通用"
		},
		{
			"id": "talk_to_parents_start_simple",
			"title": "和家长谈难受的事，可以先从一句简单的话开始",
			"summary": "不用一上来就把所有事都讲完整。",
			"detail": "如果你很怕开口，可以先说：“我最近状态不太好，想找你认真聊十分钟。”很多时候，最难的是开头，不是全部内容。先把门打开，后面的话可以慢慢说。",
			"layer": "沟通支持卡",
			"tags": ["家长沟通", "开口"],
			"scenario": "家庭矛盾"
		},
		{
			"id": "talk_to_parents_use_feelings",
			"title": "比起指责，先说感受更容易被听见",
			"summary": "“我感到……”常常比“你总是……”更容易让对话继续。",
			"detail": "你可以试着把“你根本不懂我”换成“我最近真的很委屈，也很怕你误会我”。这不是委屈自己，而是在让对方更容易听见你真正想表达的内容。",
			"layer": "沟通支持卡",
			"tags": ["家长沟通", "表达感受"],
			"scenario": "家庭矛盾"
		},
		{
			"id": "talk_to_parents_one_topic",
			"title": "一次只谈一个问题，会比较不容易吵起来",
			"summary": "话题太多时，彼此都更容易乱掉。",
			"detail": "如果你想谈学习压力、手机、交友、作息、控制感，最好不要一次全部堆上去。先挑最重要的一件说，例如“我希望你先听我讲完最近的学习压力”。这样对方也更容易跟得上。",
			"layer": "沟通支持卡",
			"tags": ["家长沟通", "技巧"],
			"scenario": "家庭矛盾"
		},
		{
			"id": "talk_to_parents_choose_timing",
			"title": "选一个比较平静的时机谈，会好很多",
			"summary": "人在刚生气、赶时间、很累的时候，通常比较难好好听。",
			"detail": "如果对方正在忙、很烦、刚吵完架，硬谈很容易让你更受伤。你可以先问：“今晚吃完饭后，能不能有十分钟好好聊一下？”给彼此一点准备空间，沟通通常会顺一点。",
			"layer": "沟通支持卡",
			"tags": ["家长沟通", "时机"],
			"scenario": "家庭矛盾"
		},
		{
			"id": "talk_to_parents_specific_request",
			"title": "比起“理解我”，更具体的请求更容易做到",
			"summary": "你可以直接说你现在最需要什么帮助。",
			"detail": "例如“这周先别在饭桌上追问我成绩”“如果我情绪上来了，希望你先陪我坐一会儿”“下次开家长会前，能不能先告诉我你担心什么”。具体的请求，往往比抽象地说“你要理解我”更容易被接住。",
			"layer": "沟通支持卡",
			"tags": ["家长沟通", "请求帮助"],
			"scenario": "家庭矛盾"
		},
		{
			"id": "talk_to_parents_write_first",
			"title": "如果面对面太难，可以先写下来",
			"summary": "纸条、消息、备忘录，都可以成为开口的桥。",
			"detail": "有时候一到面对面，就会突然哭、卡住、说不清楚。那你可以先写：我最近发生了什么、我最难受的是什么、我希望你怎么帮我。写下来不是逃避，而是在帮自己把话稳稳地说出来。",
			"layer": "沟通支持卡",
			"tags": ["家长沟通", "表达"],
			"scenario": "家庭矛盾"
		},
		{
			"id": "talk_to_parents_need_listener",
			"title": "可以先说明：我现在更需要被听，不是立刻被教育",
			"summary": "有时候先被听见，人才更有力气听建议。",
			"detail": "你可以试着提前说：“我知道你可能会担心我，但我现在最想先把事情讲完，希望你先听我说几分钟，再一起想办法。”这能帮对方知道，你不是拒绝帮助，而是需要一个更能承接你的方式。",
			"layer": "沟通支持卡",
			"tags": ["家长沟通", "被倾听"],
			"scenario": "家庭矛盾"
		},
		{
			"id": "common_sleep_and_mood",
			"title": "睡得太少时，脑子真的会更难受",
			"summary": "情绪低落时，不是只有“想太多”，有时身体也在撑不住。",
			"detail": "如果你最近一直熬夜、睡不稳、起不来，情绪往往也会变得更沉、更急、更容易崩。不是说“只要睡好就没事”，而是睡眠本来就会影响心情。先想办法让身体稍微缓一点，常常会有帮助。",
			"layer": "常识支持卡",
			"tags": ["睡眠", "情绪"],
			"scenario": "通用"
		},
		{
			"id": "common_eat_and_stress",
			"title": "饿着的时候，人的情绪也更容易变重",
			"summary": "先吃一点东西，不是小事。",
			"detail": "当你紧张、委屈、头晕、心里发飘的时候，也可以顺手问问自己：我是不是已经太久没吃东西了？先补点水、吃点能量、让身体稳一点，心里的慌有时也会跟着缓下来。",
			"layer": "常识支持卡",
			"tags": ["饮食", "稳定自己"],
			"scenario": "通用"
		},
		{
			"id": "common_pause_before_reply",
			"title": "很生气的时候，先别急着回消息",
			"summary": "给自己几分钟，常常能少很多后悔。",
			"detail": "当你又气又委屈时，马上打字、马上回嘴，常常会让事情更糟。你可以先把手机放下，深呼吸几次，或者先把想说的话记在备忘录里。缓一缓，不是认输，而是在保护关系和自己。",
			"layer": "常识支持卡",
			"tags": ["冲突", "暂停"],
			"scenario": "通用"
		},
		{
			"id": "common_help_one_person",
			"title": "先找一个可信的人就够了",
			"summary": "不用一下子对很多人解释。",
			"detail": "很多人会卡在“我要怎么把一切都说清楚”。其实你可以先只找一个最信任的人：一个家长、一个老师、一个朋友、一个亲戚。先让一个人知道，很多事就不会只剩你自己面对。",
			"layer": "常识支持卡",
			"tags": ["求助", "第一步"],
			"scenario": "通用"
		},
		{
			"id": "common_feelings_need_names",
			"title": "把情绪说出名字，会比较不容易乱成一团",
			"summary": "“难受”有时候其实包含了很多种感觉。",
			"detail": "你可以试着问自己：我现在更像是委屈、害怕、羞耻、愤怒，还是很空？不是为了分析得很专业，而是当一种感觉被说出来时，人会比较不容易被它整个吞掉。",
			"layer": "基础认知卡",
			"tags": ["情绪识别", "觉察"],
			"scenario": "通用"
		},
		{
			"id": "common_body_grounding",
			"title": "先碰一碰真实的东西，也能帮自己回神",
			"summary": "脚踩地、握杯子、摸桌角，都是让自己慢慢回来的方法。",
			"detail": "当你脑子很飘、心跳很快、整个人像要散掉时，可以先注意手里的杯子、脚下的地、椅子的触感，慢慢告诉自己：我现在在这里。不是所有难受都能立刻解决，但先把自己接回来，会有帮助。",
			"layer": "情绪安抚卡",
			"tags": ["安定技巧", "地面化"],
			"scenario": "通用"
		},
		{
			"id": "academic_exam_panic",
			"title": "考试前很慌时，先缩小到下一题",
			"summary": "不是先想整场考试，而是先把眼前这一小步做完。",
			"detail": "一慌起来，人很容易一下想到“我要是考砸了怎么办”。这时候最有帮助的往往不是拼命压住焦虑，而是把注意力拉回当下：先做这一题，先看这一页，先写这一行。一步一步来，比和整场考试硬碰硬更有效。",
			"layer": "行动建议卡",
			"tags": ["学业压力", "考试焦虑"],
			"scenario": "学业压力"
		},
		{
			"id": "academic_compare_scores",
			"title": "别人考得好，不等于你就没有价值",
			"summary": "比较会很刺痛，但分数不是人的全部。",
			"detail": "看到别人轻轻松松就考得很好，心里酸、慌、委屈都很正常。但别人的成绩，只是在说明对方这一次的表现，不是在证明你不够好。你可以羡慕，也可以难过，但不用顺手把自己判得一文不值。",
			"layer": "情绪安抚卡",
			"tags": ["学业压力", "比较"],
			"scenario": "学业压力"
		},
		{
			"id": "academic_task_breakdown",
			"title": "作业太多时，先列最小清单",
			"summary": "不是要一下子全做完，而是先决定第一步做什么。",
			"detail": "当任务一大堆时，人常常会直接卡住。你可以先把事情列出来，再圈出最小的一件：读两页、写一道题、整理一科资料。任务被拆小后，大脑没那么容易被吓住。",
			"layer": "行动建议卡",
			"tags": ["学业压力", "任务拆分"],
			"scenario": "学业压力"
		},
		{
			"id": "academic_ask_teacher_help",
			"title": "听不懂时去问，不代表你差",
			"summary": "很多卡住，并不是因为你不行，而是你正在学。",
			"detail": "有时候最难的不是题，而是承认“我不会”。但学习本来就包含不会、卡住、再去问。你可以不必等到完全听不懂了才去求助，早点问，反而更能减轻压力。",
			"layer": "行动建议卡",
			"tags": ["学业压力", "求助"],
			"scenario": "学业压力"
		},
		{
			"id": "academic_parent_expectation",
			"title": "别把“家长的期待”全翻译成“我不够好”",
			"summary": "压力是真的，但它不等于你的全部价值。",
			"detail": "有些家长一着急，说出来的话会很重，让人很容易听成“你让我失望”。你可以承认自己很有压力，同时提醒自己：别人期待高，不等于我就只剩成绩这一件事。",
			"layer": "基础认知卡",
			"tags": ["学业压力", "期待"],
			"scenario": "学业压力"
		},
		{
			"id": "family_not_everything_now",
			"title": "家里一吵，不代表所有关系都完了",
			"summary": "冲突很痛，但它通常只是一个阶段，不是全部结论。",
			"detail": "当家里气氛很差时，人很容易觉得“是不是以后都只能这样了”。这种感觉很真实，但不一定就是事实。冲突说明现在有问题要处理，不等于一切已经被彻底判死。",
			"layer": "基础认知卡",
			"tags": ["家庭矛盾", "认知重构"],
			"scenario": "家庭矛盾"
		},
		{
			"id": "family_leave_before_escalate",
			"title": "对话越来越糟时，可以先暂停离开一下",
			"summary": "先把火降一点，比硬撑着继续吵更有用。",
			"detail": "如果你发现彼此声音越来越大、开始翻旧账、已经快控制不住情绪，可以先说：“我现在有点乱，我们先停十分钟，晚一点再说。”暂停不是逃避，而是在避免彼此说出更伤人的话。",
			"layer": "沟通支持卡",
			"tags": ["家庭矛盾", "暂停"],
			"scenario": "家庭矛盾"
		},
		{
			"id": "family_need_other_adult",
			"title": "如果和家长总谈不动，可以找别的大人一起帮忙",
			"summary": "不一定所有沟通都只能靠你一个人扛。",
			"detail": "如果你和家长一谈就吵、说什么都被误会，可以考虑找班主任、亲戚、心理老师、辅导员做中间人。多一个稳一点的大人在场，有时会让彼此更能听进去。",
			"layer": "沟通支持卡",
			"tags": ["家庭矛盾", "第三方支持"],
			"scenario": "家庭矛盾"
		},
		{
			"id": "family_need_safety",
			"title": "如果家里已经让你感到人身不安全，要优先求助",
			"summary": "先保证安全，再谈沟通。",
			"detail": "如果家里出现威胁、严重暴力、控制你无法离开、让你非常害怕的情况，重点就不再是“我该怎么说服他们”，而是先联系可信赖的大人、亲友、老师、相关援助机构或紧急服务，让自己到更安全的地方。",
			"layer": "危机支持卡",
			"tags": ["家庭矛盾", "安全"],
			"scenario": "家庭矛盾"
		},
		{
			"id": "social_reply_delay",
			"title": "别人回复慢，很多时候和你没那么有关",
			"summary": "有些沉默只是忙、累、没看到，不一定是针对你。",
			"detail": "社交里最让人心慌的，就是消息发出去之后的空白。但空白不等于答案。你可以提醒自己：在没有更多信息前，我先别急着用最伤人的版本解释这一切。",
			"layer": "基础认知卡",
			"tags": ["社交压力", "读心术"],
			"scenario": "社交压力"
		},
		{
			"id": "social_set_small_goal",
			"title": "社交害怕时，目标小一点会轻松很多",
			"summary": "不一定非要马上“变得会聊天”。",
			"detail": "如果你很怕社交，可以先给自己定一个很小的目标：今天先回一句消息、先和一个人打招呼、先在群里说一次话。不是逼自己一下子变外向，而是慢慢把“完全不敢”变成“可以多一点点”。",
			"layer": "行动建议卡",
			"tags": ["社交压力", "小目标"],
			"scenario": "社交压力"
		},
		{
			"id": "social_need_true_people",
			"title": "比起迎合所有人，更重要的是找到能让你放松的人",
			"summary": "关系不是越多越好，而是有几段能让你安心就很好。",
			"detail": "如果你总在想“我要怎么让所有人都喜欢我”，你会特别累。其实更重要的，往往是慢慢找到几段不用一直紧绷、可以真实一点的关系。不是人越多越值钱，而是你在关系里能不能安心。",
			"layer": "情绪安抚卡",
			"tags": ["社交压力", "关系质量"],
			"scenario": "社交压力"
		},
		{
			"id": "social_after_embarrassment",
			"title": "社死之后，给自己一天也没关系",
			"summary": "尴尬的感觉会很强，但通常不会永远这么强。",
			"detail": "如果你今天真的觉得特别丢脸，可以先允许自己缓一天，少看回放、少脑补一点。很多尴尬在当下像天塌了，但过一段时间回头看，它常常只是一个很刺的瞬间，不是整个人生。",
			"layer": "情绪安抚卡",
			"tags": ["社交压力", "尴尬"],
			"scenario": "社交压力"
		},
		{
			"id": "common_support_plan",
			"title": "可以提前给自己写一张“难受时怎么办”小卡",
			"summary": "当脑子很乱时，现成的步骤会比临时想更有用。",
			"detail": "你可以提前写下：第一步联系谁、第二步去哪里、第三步怎么让自己先安全一点、第四步能做什么让身体缓下来。等真的崩的时候，不用完全靠当下的力气去撑。",
			"layer": "常识支持卡",
			"tags": ["安全计划", "求助"],
			"scenario": "通用"
		},
		{
			"id": "common_no_need_to_deserve_help",
			"title": "你不用先“够严重”，才配得到帮助",
			"summary": "难受本身就已经是值得被照顾的理由。",
			"detail": "很多人会一直拖，因为觉得“我还没糟到那个地步”。可求助不是考试，没有统一及格线。只要你已经持续不好受、开始影响生活、或者只是很想有人帮一下，你就已经可以求助了。",
			"layer": "情绪安抚卡",
			"tags": ["求助", "值得被帮助"],
			"scenario": "通用"
		},
		{
			"id": "common_break_big_feeling",
			"title": "很大的痛苦，也可以先拆成这一小时怎么过",
			"summary": "先把时间缩小一点，常常比较活得下去。",
			"detail": "当你觉得“我根本撑不到以后”时，先别逼自己解决一辈子的事。你可以先问：那这一小时，我怎么更安全一点？下一顿饭怎么吃？今晚怎么让自己有人陪？把时间缩小，常常会更有路。",
			"layer": "危机支持卡",
			"tags": ["危机应对", "缩小范围"],
			"scenario": "通用"
		},
		{
			"id": "common_reach_out_template",
			"title": "不会求助时，可以直接套一句模板",
			"summary": "有时候不是不想开口，是不知道怎么开口。",
			"detail": "你可以直接发：‘我最近状态不太对，想找你聊聊。你现在方便听我说几分钟吗？’如果情况更急，也可以发：‘我现在有点担心自己，能不能先陪陪我，帮我联系大人或专业帮助？’一句够用的话，比把所有话想完整更重要。",
			"layer": "沟通支持卡",
			"tags": ["求助", "沟通模板"],
			"scenario": "通用"
		},
		{
			"id": "common_call_emergency_when_immediate",
			"title": "如果危险已经很近，先联系紧急帮助",
			"summary": "当下的安全永远比“我是不是太夸张了”更重要。",
			"detail": "如果你或身边的人已经有很强的自伤、自杀、暴力危险，或者已经处在非常不安全的情境里，优先联系当地紧急服务、医院急诊、学校值班老师或身边能立刻赶来的人。先让危险停下来，比之后怎么解释都更重要。",
			"layer": "危机支持卡",
			"tags": ["紧急援助", "立即处理"],
			"scenario": "通用"
		},
		{
			"id": "common_aftercare_small_steps",
			"title": "很难的一天过后，先做一点点善后就很好",
			"summary": "喝水、洗脸、换衣服、告诉一个人你还在难受，都是在照顾自己。",
			"detail": "有些日子会特别耗人，甚至光撑过去就已经很难了。等风浪稍微过去一点，你不用立刻恢复“正常”。先做一点小善后：喝点水、坐下来、吃点东西、洗把脸、给信任的人发句消息。小小的照顾，也是在帮自己慢慢回来。",
			"layer": "情绪安抚卡",
			"tags": ["恢复", "照顾自己"],
			"scenario": "通用"
		}
	]

static func get_random_flashcards(count: int = 3, exclude_ids: Array[String] = []) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	var excluded := {}
	for card_id in exclude_ids:
		excluded[card_id] = true

	for card in get_flashcards():
		var card_dict := card as Dictionary
		var card_id := str(card_dict.get("id", ""))
		if excluded.has(card_id):
			continue
		cards.append(card_dict.duplicate(true))

	if cards.size() < count:
		for card in get_flashcards():
			var card_dict := card as Dictionary
			var card_id := str(card_dict.get("id", ""))
			if excluded.has(card_id):
				cards.append(card_dict.duplicate(true))

	cards.shuffle()
	var result: Array[Dictionary] = []
	for i in mini(count, cards.size()):
		result.append(cards[i] as Dictionary)
	return result

static func get_matching_flashcards(count: int = 5, exclude_ids: Array[String] = []) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	var excluded := {}
	for card_id in exclude_ids:
		excluded[card_id] = true

	for card in get_flashcards():
		var card_dict := card as Dictionary
		var card_id := str(card_dict.get("id", ""))
		if excluded.has(card_id):
			continue
		if str(card_dict.get("title", "")).is_empty():
			continue
		if str(card_dict.get("detail", "")).is_empty():
			continue
		cards.append(card_dict.duplicate(true))

	if cards.size() < count:
		for card in get_flashcards():
			var card_dict := card as Dictionary
			var card_id := str(card_dict.get("id", ""))
			if excluded.has(card_id):
				continue
			if str(card_dict.get("title", "")).is_empty():
				continue
			if str(card_dict.get("detail", "")).is_empty():
				continue
			cards.append(card_dict.duplicate(true))

	cards.shuffle()
	var result: Array[Dictionary] = []
	for i in mini(count, cards.size()):
		result.append(cards[i] as Dictionary)
	return result

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
