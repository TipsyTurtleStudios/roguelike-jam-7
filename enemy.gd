extends CharacterBody2D


@export var speed = 14
const GRAVITY = 500
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75
var direction = Vector2()
var target_velocity = Vector2()
@onready var player = get_tree().get_first_node_in_group("player_character")

func on_ready():
	pass

func _physics_process(delta):
	print(player.position)
	#target_velocity.x += 1 #right
	target_velocity.x -= 1 #left
	if target_velocity.x == 1:
		$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.flip_h = true


	$AnimatedSprite2D.play("walk")
	
	if not is_on_floor():
		target_velocity.y += GRAVITY
	
	velocity = target_velocity
	print(velocity)
	move_and_slide()
