extends CharacterBody2D

@export var speed: float = 220.0
@export var jump_velocity: float = -460.0
@export var max_lives: int = 3
@export var max_health: int = 3
@export var bubble_scene: PackedScene
@export var fire_cooldown: float = 0.25
@export var max_bubbles: int = 5

var gravity: float
var facing: int = 1
var lives: int
var health: int
var invuln_time: float = 0.0
var fire_time: float = 0.0
var blow_anim_time: float = 0.0
var hurt_anim_time: float = 0.0
var current_bubble: Node = null
var _dying: bool = false

signal health_changed
signal died
signal respawned

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_jump: AudioStreamPlayer2D = $SFXJump
@onready var sfx_fire: AudioStreamPlayer2D = $SFXFire
@onready var sfx_hurt: AudioStreamPlayer2D = $SFXHurt

func _ready() -> void:
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	lives = max_lives
	health = max_health
	add_to_group("player")

func _physics_process(delta: float) -> void:
	invuln_time = max(invuln_time - delta, 0.0)
	fire_time = max(fire_time - delta, 0.0)
	blow_anim_time = max(blow_anim_time - delta, 0.0)
	hurt_anim_time = max(hurt_anim_time - delta, 0.0)

	if not is_on_floor() or _dying:
		velocity.y += gravity * delta

	var input_dir := 0.0

	if not _dying and health > 0 and lives > 0:
		input_dir = Input.get_axis("move_left", "move_right")

		if input_dir != 0.0:
			facing = sign(input_dir)
			velocity.x = input_dir * speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed)

		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity
			if sfx_jump:
				sfx_jump.play()

		var bubble_count := get_tree().get_nodes_in_group("bubbles").size()
		if Input.is_action_just_pressed("fire") \
				and fire_time <= 0.0 \
				and bubble_scene \
				and bubble_count < max_bubbles:
			_fire_bubble()
			fire_time = fire_cooldown
			blow_anim_time = fire_cooldown
			if sfx_fire:
				sfx_fire.play()

		if Input.is_action_pressed("fire") and current_bubble and current_bubble.is_inside_tree():
			if current_bubble.has_method("extend_blow"):
				current_bubble.extend_blow(0.05)
		else:
			current_bubble = null
	else:
		velocity.x = 0.0

	move_and_slide()

	if _dying and global_position.y > 520.0:
		_dying = false
		lives -= 1
		health_changed.emit()
		if lives > 0:
			_respawn()
		else:
			set_physics_process(false)
			died.emit()

	_update_animation(input_dir)

func take_hit(from_dir: int) -> void:
	if invuln_time > 0.0 or lives <= 0:
		return
	health -= 1
	invuln_time = 1.0
	hurt_anim_time = 0.4
	velocity = Vector2(220.0 * -from_dir, -260.0)
	health_changed.emit()

	if health <= 0:
		_dying = true
		velocity = Vector2(0.0, 200.0)
		$CollisionShape2D.set_deferred("disabled", true)

	if sfx_hurt:
		sfx_hurt.play()

func _fire_bubble() -> void:
	if bubble_scene == null:
		return
	var b := bubble_scene.instantiate()
	b.global_position = global_position + Vector2(18.0 * facing, -10.0)
	b.dir = facing
	get_tree().current_scene.add_child(b)
	current_bubble = b

func _respawn() -> void:
	global_position = Vector2(400.0, 100.0)
	velocity = Vector2.ZERO
	health = max_health
	invuln_time = 0.8
	_dying = false
	$CollisionShape2D.set_deferred("disabled", false)
	respawned.emit()

func _update_animation(input_dir: float) -> void:
	sprite.flip_h = facing > 0

	if _dying or lives <= 0:
		sprite.play("die")
		return

	if hurt_anim_time > 0.0:
		sprite.play("hit")
		return

	if blow_anim_time > 0.0:
		sprite.play("blow")
		return

	if abs(input_dir) > 0.0:
		sprite.play("run")
	else:
		sprite.play("idle")
