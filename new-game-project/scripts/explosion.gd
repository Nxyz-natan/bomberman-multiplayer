extends Node2D

@onready var anim = $AnimatedSprite2D

func _ready():
	anim.play("Explosion")
	anim.animation_finished.connect(_on_animation_finished)
	check_for_player()

func check_for_player():
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if position.distance_to(player.position) <= 80:
			player.die()
	
	var ais = get_tree().get_nodes_in_group("ai")
	for ai in ais:
		if position.distance_to(ai.position) <= 80:
			ai.die()

func _on_animation_finished():
	queue_free()
	
