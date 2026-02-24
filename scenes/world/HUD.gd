extends CanvasLayer

@onready var level_label: Label = $Level
@onready var score_label: Label = $Score
@onready var player_container: HBoxContainer = $Player
@onready var life_template: TextureRect = $Player/Lives
@onready var heart_template: TextureRect = $Player/Health

func _ready() -> void:
	life_template.visible = false
	heart_template.visible = false

func set_values(level: int, score: int, lives: int, health: int) -> void:
	if level_label:
		level_label.text = "LEVEL " + str(level)

	if score_label:
		score_label.text = str(score)

	for child in player_container.get_children():
		if child != life_template and child != heart_template:
			child.free()

	for i in range(max(lives, 0)):
		var icon := life_template.duplicate()
		icon.visible = true
		player_container.add_child(icon)

	for i in range(max(health, 0)):
		var icon := heart_template.duplicate()
		icon.visible = true
		player_container.add_child(icon)
