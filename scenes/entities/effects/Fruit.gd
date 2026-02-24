extends CharacterBody2D

enum FruitType { APPLE, RASPBERRY, LEMON, EXTRA_HEALTH, EXTRA_LIFE }

@export var fruit_type: FruitType = FruitType.APPLE
@export var lifetime: float = 10.0
@export var from_strong_enemy: bool = false

var gravity: float
var t: float = 0.0
var _collected: bool = false
var _despawning: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	add_to_group("fruits")
	if has_node("HitBox"):
		$HitBox.body_entered.connect(_on_body_entered)
	call_deferred("_init_type")

func _init_type() -> void:
	_choose_type()
	_play_anim_for_type()

func _physics_process(delta: float) -> void:
	if _collected:
		return

	t += delta

	if t >= lifetime - 2.0:
		visible = int(t * 8) % 2 == 0

	if t >= lifetime:
		_do_pop()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

	for body in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(body.global_position) < 28.0:
			_on_body_entered(body)
			return

func _on_body_entered(body: Node) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true

	var levels := get_tree().get_nodes_in_group("level")
	if levels.is_empty():
		_do_pop()
		return
	var level := levels[0]

	match fruit_type:
		FruitType.EXTRA_HEALTH:
			if "health" in body and "max_health" in body:
				body.health = min(body.max_health, body.health + 1)
			if level.has_method("add_score"):
				level.add_score(0)
		FruitType.EXTRA_LIFE:
			if "lives" in body:
				body.lives += 1
			if level.has_method("add_score"):
				level.add_score(0)
		_:
			if level.has_method("add_score"):
				level.add_score(_score_for_type() * 100)

	_do_pop()

func _choose_type() -> void:
	if from_strong_enemy:
		var pool: Array[FruitType] = []
		for i in range(10):
			pool.append_array([FruitType.APPLE, FruitType.RASPBERRY, FruitType.LEMON])
		for i in range(9):
			pool.append(FruitType.EXTRA_HEALTH)
		pool.append(FruitType.EXTRA_LIFE)
		fruit_type = pool[randi() % pool.size()]
	else:
		var pool: Array[FruitType] = [FruitType.APPLE, FruitType.RASPBERRY, FruitType.LEMON]
		fruit_type = pool[randi() % pool.size()]

func _play_anim_for_type() -> void:
	match fruit_type:
		FruitType.APPLE:        sprite.play("apple")
		FruitType.RASPBERRY:    sprite.play("raspberry")
		FruitType.LEMON:        sprite.play("lemon")
		FruitType.EXTRA_HEALTH: sprite.play("extra_health")
		FruitType.EXTRA_LIFE:   sprite.play("extra_life")

func _score_for_type() -> int:
	match fruit_type:
		FruitType.APPLE:     return 1
		FruitType.RASPBERRY: return 2
		FruitType.LEMON:     return 3
		_:                   return 0

func _do_pop() -> void:
	if _despawning:
		return
	_despawning = true
	_collected = true
	visible = true
	set_physics_process(false)

	sprite.play("pop")
	sprite.animation_finished.connect(queue_free, CONNECT_ONE_SHOT)
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(self): queue_free())
