extends Area2D

@export var speed: float = 280.0

var dir: int = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	global_position.x += dir * speed * delta
	if sprite:
		sprite.flip_h = dir > 0
	if global_position.x < 0.0 or global_position.x > 800.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is TileMap or body is StaticBody2D:
		queue_free()
		return

	if body.is_in_group("player") and body.has_method("take_hit"):
		body.take_hit(dir)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("bubbles") and area.has_method("hit_by_bolt"):
		area.hit_by_bolt()
		queue_free()
