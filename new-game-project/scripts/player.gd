extends CharacterBody2D

@onready var anim = $AnimatedSprite2D

const TILE_SIZE = 80
var is_moving = false
var last_direction = Vector2.DOWN
var bomb_cooldown = 0.0
var bomb_interval = 3.0

func _ready():
	add_to_group("player")

func _physics_process(delta):
	if is_moving:
		return
	
	bomb_cooldown -= delta
	
	if Input.is_action_just_pressed("ui_accept"):
		if bomb_cooldown <= 0:
			place_bomb()
			bomb_cooldown = bomb_interval
	
	var input_direction = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		input_direction = Vector2.RIGHT
		last_direction = Vector2.RIGHT
		anim.play("walk_right")
	elif Input.is_action_pressed("ui_left"):
		input_direction = Vector2.LEFT
		last_direction = Vector2.LEFT
		anim.play("walk_left")
	elif Input.is_action_pressed("ui_down"):
		input_direction = Vector2.DOWN
		last_direction = Vector2.DOWN
		anim.play("walk_down")
	elif Input.is_action_pressed("ui_up"):
		input_direction = Vector2.UP
		last_direction = Vector2.UP
		anim.play("walk_up")
	else:
		if last_direction == Vector2.RIGHT:
			anim.play("idle_right")
		elif last_direction == Vector2.LEFT:
			anim.play("idle_left")
		elif last_direction == Vector2.DOWN:
			anim.play("idle_down")
		else:
			anim.play("idle_up")
		return

	var target = position + input_direction * TILE_SIZE
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(position, target, collision_mask)
	var collision = space_state.intersect_ray(query)
	
	if collision:
		return
	
	is_moving = true
	var tween = create_tween()
	tween.tween_property(self, "position", target, 0.15)
	tween.tween_callback(func(): is_moving = false)

func place_bomb():
	var bomb_scene = preload("res://scenes/bomb.tscn")
	var bomb = bomb_scene.instantiate()
	bomb.position = position
	get_parent().add_child(bomb)

func die():
	anim.play("death")
	set_physics_process(false)
	await get_tree().create_timer(1.5).timeout
	position = Vector2(200, 120)
	anim.play("idle_down")
	is_moving = false
	set_physics_process(true)
