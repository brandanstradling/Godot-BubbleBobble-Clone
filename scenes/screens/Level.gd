extends Node2D

enum LayoutId { LAYOUT1, LAYOUT2, LAYOUT3 }
enum ColorId { BLUE, RED, GREEN, BROWN }

@export var enemy_scene: PackedScene
@export var bubble_scene: PackedScene
@export var fruit_scene: PackedScene
@export var fruit_spawn_interval_min: float = 5.0
@export var fruit_spawn_interval_max: float = 12.0

@export var backgrounds_root_path: NodePath
@export var layouts_root_path: NodePath
@export var player_path: NodePath
@export var hud_path: NodePath

var level: int = 1
var current_layout: int = LayoutId.LAYOUT1
var current_color: int = ColorId.BLUE
var score: int = 0

var active_enemy_count: int = 0
var _spawn_id: int = 0
var _level_ending: bool = false
var _fruit_spawn_timer: float = 0.0

@onready var player = get_node(player_path)
@onready var hud = get_node(hud_path)
@onready var backgrounds_root: Node = get_node(backgrounds_root_path)
@onready var layouts_root: Node = get_node(layouts_root_path)

signal game_over

func _ready() -> void:
	add_to_group("level")

	if player:
		player.bubble_scene = bubble_scene
		player.died.connect(_on_player_died)
		player.respawned.connect(_update_hud)
		player.health_changed.connect(_update_hud)

	if hud:
		hud.visible = true

	_fruit_spawn_timer = randf_range(fruit_spawn_interval_min, fruit_spawn_interval_max)
	_set_level_visuals(current_layout, current_color)
	_spawn_enemies_for_layout(current_layout)
	_update_hud()

func _process(delta: float) -> void:
	_wrap_fallers()
	_tick_fruit_timer(delta)

func reset_for_game() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	for b in get_tree().get_nodes_in_group("bubbles"):
		b.queue_free()
	for f in get_tree().get_nodes_in_group("fruits"):
		f.queue_free()

	level = 1
	current_layout = LayoutId.LAYOUT1
	current_color = ColorId.BLUE
	score = 0
	_level_ending = false
	_fruit_spawn_timer = randf_range(fruit_spawn_interval_min, fruit_spawn_interval_max)

	_set_level_visuals(current_layout, current_color)
	_spawn_enemies_for_layout(current_layout)

	if player:
		player.global_position = Vector2(400, 190)
		player.lives = player.max_lives
		player.health = player.max_health
		player.invuln_time = 0.0
		player.velocity = Vector2.ZERO
		player._dying = false
		player.set_physics_process(true)

	_update_hud()

func _on_player_died() -> void:
	game_over.emit()

# -------- Wrapping --------
func _wrap_fallers() -> void:
	var screen_height := 480.0

	if player and not player._dying and player.global_position.y > screen_height + 16.0:
		player.global_position.y = -16.0

	for e in get_tree().get_nodes_in_group("enemies"):
		if e.global_position.y > screen_height + 16.0:
			e.global_position.y = -16.0

# -------- Visuals --------
func _set_level_visuals(layout_id: int, color_id: int) -> void:
	for bg in backgrounds_root.get_children():
		bg.visible = false

	var color_name := _color_name(color_id)
	var bg_node := backgrounds_root.get_node_or_null(color_name)
	if bg_node:
		bg_node.visible = true

	for layout_node in layouts_root.get_children():
		for tm in layout_node.get_children():
			tm.visible = false
			tm.set_collision_enabled(false)

	var layout_node := layouts_root.get_node_or_null(_layout_name(layout_id))
	if layout_node:
		var tilemap_node := layout_node.get_node_or_null(color_name)
		if tilemap_node:
			tilemap_node.visible = true
			tilemap_node.set_collision_enabled(true)

func _color_name(id: int) -> String:
	match id:
		ColorId.BLUE:  return "Blue"
		ColorId.RED:   return "Red"
		ColorId.GREEN: return "Green"
		ColorId.BROWN: return "Brown"
		_:             return "Blue"

func _layout_name(id: int) -> String:
	match id:
		LayoutId.LAYOUT1: return "Layout1"
		LayoutId.LAYOUT2: return "Layout2"
		LayoutId.LAYOUT3: return "Layout3"
		_:                return "Layout1"

# -------- Enemies --------
func _spawn_enemy(pos: Vector2, enemy_type: int, initial_dir: int = 1) -> void:
	if enemy_scene == null:
		return
	var e = enemy_scene.instantiate()
	e.global_position = Vector2(pos.x, -40.0)
	e.enemy_type = enemy_type
	add_child(e)
	e.dir = initial_dir
	e.scale.x = -float(initial_dir)
	active_enemy_count += 1
	e.tree_exited.connect(_on_enemy_removed)

func _spawn_enemies_for_layout(_layout_id: int) -> void:
	if enemy_scene == null:
		return

	for e in get_tree().get_nodes_in_group("enemies"):
		if e.tree_exited.is_connected(_on_enemy_removed):
			e.tree_exited.disconnect(_on_enemy_removed)
		e.queue_free()

	active_enemy_count = 0
	_spawn_id += 1
	var my_id := _spawn_id

	_spawn_enemy(Vector2(350, -10), Enemy.EnemyType.NORMAL, 1)
	await get_tree().create_timer(1.5).timeout
	if _spawn_id != my_id: return
	_spawn_enemy(Vector2(450, -10), Enemy.EnemyType.NORMAL, -1)
	await get_tree().create_timer(2.5).timeout
	if _spawn_id != my_id: return
	_spawn_enemy(Vector2(450, -10), Enemy.EnemyType.AGGRESSIVE, 1)
	await get_tree().create_timer(4.5).timeout
	if _spawn_id != my_id: return
	_spawn_enemy(Vector2(350, -10), Enemy.EnemyType.NORMAL, -1)
	await get_tree().create_timer(3.5).timeout
	if _spawn_id != my_id: return
	_spawn_enemy(Vector2(450, -10), Enemy.EnemyType.AGGRESSIVE, -1)

func _on_enemy_removed() -> void:
	active_enemy_count -= 1
	_update_hud()
	if active_enemy_count <= 0 and not _level_ending:
		_level_ending = true
		await get_tree().create_timer(2.0).timeout
		_next_level()

# -------- Bubbles / Score / Fruit --------
func _pop_bubble(bubble: Node) -> void:
	if not is_instance_valid(bubble):
		return
	if bubble.has_signal("popped") and not bubble.popped.is_connected(_on_bubble_popped):
		bubble.popped.connect(_on_bubble_popped, CONNECT_ONE_SHOT)
	bubble.pop()

func _on_bubble_popped(points: int, pop_position: Vector2, enemy_type: int) -> void:
	score += points
	_update_hud()

	if fruit_scene and points > 0:
		var fruit = fruit_scene.instantiate()
		fruit.global_position = pop_position
		fruit.from_strong_enemy = (enemy_type == Enemy.EnemyType.AGGRESSIVE) or (randi() % 4 == 0)
		add_child(fruit)

func add_score(amount: int) -> void:
	score += amount
	_update_hud()

func _tick_fruit_timer(delta: float) -> void:
	if fruit_scene == null:
		return
	_fruit_spawn_timer -= delta
	if _fruit_spawn_timer <= 0.0:
		_spawn_random_fruit()
		_fruit_spawn_timer = randf_range(fruit_spawn_interval_min, fruit_spawn_interval_max)

func _spawn_random_fruit() -> void:
	if fruit_scene == null:
		return
	var fruit = fruit_scene.instantiate()
	fruit.global_position = Vector2(randf_range(80.0, 720.0), -10.0)
	fruit.from_strong_enemy = false
	add_child(fruit)

# -------- Level Progression --------
func _next_level() -> void:
	_level_ending = false
	level += 1

	current_layout = (current_layout + 1) % (LayoutId.LAYOUT3 + 1)
	current_color = (current_color + 1) % (ColorId.BROWN + 1)

	_set_level_visuals(current_layout, current_color)
	_spawn_enemies_for_layout(current_layout)

	if player:
		match current_layout:
			LayoutId.LAYOUT1: player.global_position = Vector2(400, 190)
			LayoutId.LAYOUT2: player.global_position = Vector2(400, 90)
			LayoutId.LAYOUT3: player.global_position = Vector2(400, 190)

	_update_hud()

# -------- HUD --------
func _update_hud() -> void:
	if hud and player and hud.has_method("set_values"):
		hud.set_values(level, score, player.lives, player.health)
