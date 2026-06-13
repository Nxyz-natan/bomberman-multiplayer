extends Area2D

@onready var sprite = $Sprite2D

var timer = 3.0
var exploded = false
var pulsing = true

func _ready():
	add_to_group("bombs")
	await get_tree().process_frame
	start_pulse()

func start_pulse():
	if not pulsing:
		return
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_callback(start_pulse)

func _process(delta):
	if exploded:
		return
	timer -= delta
	if timer <= 0:
		explode()

func explode():
	exploded = true
	pulsing = false
	sprite.scale = Vector2(1.0, 1.0)
	
	var explosion_scene = preload("res://scenes/explosion.tscn")
	var explosion = explosion_scene.instantiate()
	explosion.position = position
	get_parent().add_child(explosion)
	
	queue_free()
	

	
