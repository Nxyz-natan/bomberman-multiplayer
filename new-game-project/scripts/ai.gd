extends CharacterBody2D

@onready var anim = $AnimatedSprite2D

const TILE_SIZE = 80
var is_moving = false
var last_direction = Vector2.DOWN
var move_timer = 0.0
var move_interval = 0.2
var bomb_timer = 0.0
var bomb_interval = 3.0
var player = null

func _ready():
	add_to_group("ai")
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if is_moving:
		return
	
	bomb_timer += delta
	if bomb_timer >= bomb_interval:
		bomb_timer = 0.0
		place_bomb()
	
	move_timer += delta
	if move_timer < move_interval:
		return
	move_timer = 0.0
	
	if player == null:
		return
	
	var stuck_timer = 0.0

# add this inside _physics_process after move_timer block
	stuck_timer += delta
	if stuck_timer > 1.5:
		stuck_timer = 0.0
		var random_dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		random_dirs.shuffle()
		for dir in random_dirs:
			if try_move(dir):
				return
	# if close enough to player just stop and let bombs do the work
	var dist = position.distance_to(player.position)
	if dist <= TILE_SIZE:
		return
	
	var diff = player.position - position
	var primary = Vector2.ZERO
	var secondary = Vector2.ZERO
	
	if abs(diff.x) > abs(diff.y):
		primary = Vector2.RIGHT if diff.x > 0 else Vector2.LEFT
		secondary = Vector2.DOWN if diff.y > 0 else Vector2.UP
	else:
		primary = Vector2.DOWN if diff.y > 0 else Vector2.UP
		secondary = Vector2.RIGHT if diff.x > 0 else Vector2.LEFT
	
	var moved = try_move(primary)
	if not moved:
		moved = try_move(secondary)
	if not moved:
		try_move(-primary)

func try_move(input_direction: Vector2) -> bool:
	var target = position + input_direction * TILE_SIZE
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(position, target, collision_mask)
	query.exclude = []
	var bombs = get_tree().get_nodes_in_group("bombs")
	for bomb in bombs:
		query.exclude.append(bomb.get_rid())
	
	var collision = space_state.intersect_ray(query)
	
	if collision:
		return false
	
	if input_direction == Vector2.RIGHT:
		anim.play("walk_right")
	elif input_direction == Vector2.LEFT:
		anim.play("walk_left")
	elif input_direction == Vector2.DOWN:
		anim.play("walk_down")
	else:
		anim.play("walk_up")
	
	is_moving = true
	var tween = create_tween()
	tween.tween_property(self, "position", target, 0.15)
	tween.tween_callback(func(): is_moving = false)
	return true

func place_bomb():
	var bomb_scene = preload("res://scenes/bomb_ai.tscn")
	var positions = [position, position + Vector2(TILE_SIZE, 0), position + Vector2(0, TILE_SIZE)]
	for pos in positions:
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = pos
		query.collision_mask = collision_mask
		var colliders = space_state.intersect_point(query)
		if colliders.is_empty():
			var bomb = bomb_scene.instantiate()
			bomb.position = pos
			get_parent().add_child(bomb)

func is_bomb_nearby(check_position: Vector2) -> bool:
	var bombs = get_tree().get_nodes_in_group("bombs")
	for bomb in bombs:
		if bomb.position.distance_to(check_position) <= TILE_SIZE * 2:
			return true
	return false

func die():
	anim.play("death")
	set_physics_process(false)
	await get_tree().create_timer(1.5).timeout
	position = Vector2(924, 286)
	anim.play("idle_down")
	is_moving = false
	set_physics_process(true)
