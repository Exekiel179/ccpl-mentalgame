## KnowledgeScreen — explains cognitive restructuring before gameplay.
extends Control

var _page_index: int = 0 # page counter

@onready var title_label: Label    = %TitleLabel
@onready var body_label: Label     = %BodyLabel
@onready var btn_next: Button      = %BtnNext
@onready var btn_back: Button      = %BtnBack
@onready var btn_start: Button     = %BtnStart
@onready var page_indicator: Label = %PageIndicator

func _get_pages() -> Array:
	return [
		{
			"title": "什么是认知重构？",
			"body": "认知重构是一种心理技术，帮助我们识别和挑战不合理的思维模式，从而改变情绪和行为反应。"
		},
		{
			"title": "事实 vs 想法",
			"body": "事实是可以客观验证的信息，例如：我考试不及格。\n想法是我们对事实的解读与评判，例如：我完蛋了。\n\n区分两者是认知重构的第一步。"
		},
		{
			"title": "为什么有效？",
			"body": "当我们将想法误当事实时，情绪会被放大。\n通过识别想法的本质，我们可以主动选择更平衡的解读方式，从而降低焦虑和抑郁。"
		},
		{
			"title": "游戏玩法",
			"body": "句子从屏幕飞过，你有几秒钟判断它是事实还是想法。\n\nF 键 = 事实    J 键 = 想法\n\n判断错误或超时会扣除心理健康值。归零则游戏结束。\n\n准备好了吗？"
		},
	]

func _ready() -> void:
	btn_next.pressed.connect(_next_page)
	btn_back.pressed.connect(_prev_page)
	btn_start.pressed.connect(func(): GameManager.start_game(GameManager.current_scenario))
	_refresh()

func _next_page() -> void:
	_page_index = mini(_page_index + 1, _get_pages().size() - 1)
	_refresh()

func _prev_page() -> void:
	_page_index = maxi(_page_index - 1, 0)
	_refresh()

func _refresh() -> void:
	var pages := _get_pages()
	var page: Dictionary = pages[_page_index]
	title_label.text = page["title"]
	body_label.text  = page["body"]
	page_indicator.text = "%d / %d" % [_page_index + 1, pages.size()]
	btn_back.disabled = _page_index == 0
	btn_next.visible  = _page_index < pages.size() - 1
	btn_start.visible = _page_index == pages.size() - 1
