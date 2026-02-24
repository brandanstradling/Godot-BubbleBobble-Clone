extends Area2D

@export var horiz_speed: float = 240.0
@export var up_speed: float = 80.0
@export var base_blown_time: float = 0.35
@export var max_blown_time: float = 1.5
@export var lifetime: float = 4.2

var dir: int = 1
var t: float = 0.0
var blown_time: float = 0.0
var trapped_enemy: Node = null
var trapped_enemy_type: int = -1
var _popping: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_pop: AudioStreamPlayer2D = $SFXPop

signal popped(points: int, pop_position: Vector2, enemy_type: int)

func _ready() -> void:
	add_to_group("bubbles")
	body_entered.connect(_on_body_entered)
	blown_time = base_blown_time
	sprite.play("grow")

func _process(delta: float) -> void:
	if _popping:
		return

	t += delta

	if trapped_enemy != null and is_instance_valid(trapped_enemy):
		trapped_enemy.global_position = global_position

	if t < blown_time:
		global_position.x += dir * horiz_speed * delta
	else:
		global_position.y -= up_speed * delta

	if t > 0.3 and trapped_enemy == null and sprite.animation != "idle":
		sprite.play("idle")

	if t >= lifetime or global_position.y < -40.0:
		pop()

func _on_body_entered(body: Node) -> void:
	if _popping:
		return

	if body.is_in_group("player") and trapped_enemy != null:
		var levels := get_tree().get_nodes_in_group("level")
		if not levels.is_empty() and levels[0].has_method("_pop_bubble"):
			levels[0]._pop_bubble(self)
		else:
			pop()
		return

	if trapped_enemy == null and body.is_in_group("enemies") and body.has_method("trap"):
		body.trap(self)
		trapped_enemy = body
		trapped_enemy_type = (body as Enemy).enemy_type if body is Enemy else Enemy.EnemyType.NORMAL
		sprite.play("trap_aggressive" if trapped_enemy_type == Enemy.EnemyType.AGGRESSIVE else "trap_normal")

func extend_blow(extra_time: float) -> void:
	blown_time = min(blown_time + extra_time, max_blown_time)

func pop() -> void:
	if _popping:
		return
	_popping = true
	set_process(false)

	var pts := 0
	if trapped_enemy != null and is_instance_valid(trapped_enemy):
		if trapped_enemy.has_method("get_points"):
			pts = trapped_enemy.get_points()
		trapped_enemy.queue_free()
		trapped_enemy = null

	emit_signal("popped", pts, global_position, trapped_enemy_type)

	sprite.play("pop")
	if sfx_pop:
		sfx_pop.play()

	sprite.animation_finished.connect(queue_free, CONNECT_ONE_SHOT)
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(self): queue_free())

func hit_by_bolt() -> void:
	pop()
