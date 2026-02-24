extends Node2D

@export var level_scene: PackedScene

@onready var level_root: Node = $LevelRoot
@onready var menu_overlay: Control = $Menu
@onready var gameover_overlay: Control = $GameOver

var level_instance: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_game()
	_show_menu(true)
	_show_gameover(false)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("start") and menu_overlay.visible:
		_show_menu(false)
		if level_instance and level_instance.has_method("reset_for_game"):
			level_instance.reset_for_game()

	if Input.is_action_just_pressed("restart") and gameover_overlay.visible:
		_restart_game()

func _start_game() -> void:
	if level_instance:
		level_instance.queue_free()
		level_instance = null

	if level_scene:
		level_instance = level_scene.instantiate()
		level_root.add_child(level_instance)
		if level_instance.has_signal("game_over"):
			level_instance.game_over.connect(_on_game_over)

func _restart_game() -> void:
	get_tree().paused = false
	_show_gameover(false)
	_start_game()

func _on_game_over() -> void:
	get_tree().paused = true
	_show_gameover(true)

func _show_menu(show: bool) -> void:
	menu_overlay.visible = show

func _show_gameover(show: bool) -> void:
	gameover_overlay.visible = show
