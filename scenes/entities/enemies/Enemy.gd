class_name Enemy
extends CharacterBody2D

enum EnemyType { NORMAL, AGGRESSIVE }

@export var enemy_type: EnemyType = EnemyType.NORMAL
@export var base_speed: float = 70.0
@export var aggressive_speed_multiplier: float = 1.8
@export var points: int = 100
@export var bolt_scene: PackedScene
@export var fire_interval_min: float = 1.5
@export var fire_interval_max: float = 3.0
@export var aggressive_fire_multiplier: float = 0.6

var speed: float
var gravity: float
var dir: int = -1
var trapped: bool = false
var dir_change_timer: float = 0.0
var fire_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_shoot: AudioStreamPlayer2D = $SFXShoot

func _ready() -> void:
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	add_to_group("enemies")

	speed = base_speed
	if enemy_type == EnemyType.AGGRESSIVE:
		speed *= aggressive_speed_multiplier
		fire_interval_min *= aggressive_fire_multiplier
		fire_interval_max *= aggressive_fire_multiplier

	fire_timer = randf_range(fire_interval_min, fire_interval_max)
	dir_change_timer = randf_range(1.0, 4.0)

	sprite.play("move_normal" if enemy_type == EnemyType.NORMAL else "move_aggresive")
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	$HitBox.body_entered.connect(_on_HitBox_body_entered)

func _physics_process(delta: float) -> void:
	if trapped:
		velocity = Vector2.ZERO
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = dir * speed
	move_and_slide()

	if is_on_wall():
		dir *= -1
		scale.x = -scale.x
		dir_change_timer = randf_range(1.0, 4.0)

	dir_change_timer -= delta
	if dir_change_timer <= 0.0:
		dir *= -1
		scale.x = -scale.x
		dir_change_timer = randf_range(2.0, 4.0)

	fire_timer -= delta
	if fire_timer <= 0.0:
		_fire()
		fire_timer = randf_range(fire_interval_min, fire_interval_max)

func _fire() -> void:
	if bolt_scene == null:
		return

	sprite.play("attack_normal" if enemy_type == EnemyType.NORMAL else "attack_aggressive")

	var bolt := bolt_scene.instantiate()
	bolt.global_position = global_position + Vector2(dir * 20.0, -10.0)
	bolt.dir = dir
	get_tree().current_scene.add_child(bolt)

	if sfx_shoot:
		sfx_shoot.play()

func _on_sprite_animation_finished() -> void:
	if sprite.animation in ["attack_normal", "attack_aggressive"]:
		sprite.play("move_normal" if enemy_type == EnemyType.NORMAL else "move_aggresive")

func trap(_bubble: Node) -> void:
	trapped = true
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	visible = false
	if has_node("HitBox"):
		$HitBox.monitoring = false
		$HitBox.monitorable = false

func get_points() -> int:
	return points

func _on_HitBox_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_hit"):
		body.take_hit(dir)
