## SentenceData — one item the player must categorize.
class_name SentenceData
extends Resource

enum Category { FACT, THOUGHT }

@export var text: String = ""
@export var category: Category = Category.THOUGHT
@export var explanation: String = ""  # shown after answering
