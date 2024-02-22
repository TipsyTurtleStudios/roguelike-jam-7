class_name Player
extends CharacterBody2D

# Adjustables
@export var controller : player_controller
@export_group("Physics")
@export var gravity = 1580
@export var max_fall_velocity = 700

@export_group("Speed")
@export var speed = 300.0
@export var acceleration = 0.1
@export var decceleration = 0.2
@export var dash_time = 0.1
@export var dash_speed = 700

@export_group("Jump")
@export var jump_force = -500.0
@export var jump_early_release = 0.2
@export var early_jump_allowance = 0.1
@export var coyote_time_allowance = 0.15
@export var max_jumps_enabled = 2
@export var apex_float_modifier = 0.4
@export var apex_threshold = 100

# Internal Variables
## Presets
var is_left = false
const char_snap_length = 32.0
const char_slope_angle = deg_to_rad(46)

## Internal Nodes
var animation_node : AnimationPlayer
var farm_boy_node : Node2D
var jump_allowance_node : Timer
var coyote_node : Timer
var dash_node : Timer
var controller_node : Node
var dust_burst : GPUParticles2D

var wall_jump_ready = false

## Enums
enum PlayerStates {Idle, Walk, Jumping, Falling, Landed}

## Input Variables
var input_dict = {
	"left": false,
	"right": false,
	"jump": false,
	"dash": false,
	"release_control": false,
	"fly": false
}
var previous_input = {}

## Process Vars
var player_state : PlayerStates
var previous_player_state : PlayerStates
var direction = 0
var character_velocity : Vector2
var was_on_floor : bool
var cur_jump_count = 0
var player_alive = true

func _ready():
	var new_jump_timer := Timer.new()
	new_jump_timer.name = "jump_allowance"
	add_child(new_jump_timer)
	
	var new_coyote_timer := Timer.new()
	new_coyote_timer.name = "coyote_allowance"
	add_child(new_coyote_timer)
	
	var new_dash_timer := Timer.new()
	new_dash_timer.name = "dash_time"
	add_child(new_dash_timer)
	
	
	animation_node = get_node("AnimationPlayer")#get_node("animations")
	farm_boy_node = get_node("FarmBoy")
	jump_allowance_node = get_node("jump_allowance")
	coyote_node = get_node("coyote_allowance")
	dash_node = get_node("dash_time")
	controller_node = get_node("controller_container")
	#dust_burst = get_node("DustTrail/DustBurst")
	
	set_timers()
	
	was_on_floor = is_on_floor()
	sync_input_dicts()
	floor_max_angle = char_slope_angle
	floor_snap_length = char_snap_length
	set_controller(human_controller.new(self))

func set_timers():
	jump_allowance_node.wait_time = early_jump_allowance
	jump_allowance_node.one_shot = true
	coyote_node.wait_time = coyote_time_allowance
	coyote_node.one_shot = true
	dash_node.wait_time = dash_time
	dash_node.one_shot = true

func set_controller(input_controller: player_controller) -> void:
	#Remove Previous Controllers
	for child in controller_node.get_children():
		child.queue_free()
		
	controller = input_controller
	controller_node.add_child(controller)

func update_animation():
	if is_left:
		farm_boy_node.set_scale(Vector2(1,1))
		#animation_node.flip_h = true
	else:
		farm_boy_node.set_scale(Vector2(-1,1))
		#animation_node.flip_h = false
	
	if player_state == PlayerStates.Walk:
		animation_node.play("Walk")
		
		
	if player_state == PlayerStates.Idle:
		animation_node.play("Idle")
		
	if player_state == PlayerStates.Jumping:
		animation_node.play("Jump")
		
	if player_state == PlayerStates.Falling:
		animation_node.play("Falling")
	

func sync_input_dicts() -> void:
	for key_input in input_dict.keys():
		previous_input[key_input] = input_dict[key_input]

func is_pressed(input_check: String) -> bool:
	return input_dict[input_check] == true
	
func is_just_pressed(input_check: String) -> bool:
	if input_dict[input_check]:
		if previous_input[input_check] == false:
			return true
	return false
	
func is_just_released(input_check: String) -> bool:
	if !input_dict[input_check]:
		if previous_input[input_check]:
			return true
	return false

func character_jump(increase_jump_count : int, early_release : bool = false) -> float:
	var calc_jump_force = jump_force
	if early_release:
		calc_jump_force *= jump_early_release
	else:
		pass
	
	cur_jump_count += increase_jump_count
	return calc_jump_force
	
func wall_jump_coyote_trigger():
	wall_jump_ready = true

func get_character_input():
	character_velocity.x = velocity.x
	character_velocity.y = velocity.y
	
	if is_pressed("fly"):
		character_velocity.y = jump_force
	
	# Handle Jump.
	if is_just_released("jump") && velocity.y < 0  && cur_jump_count < (max_jumps_enabled):
		character_velocity.y = character_jump(0,true)
		
	if is_just_pressed("jump"):
		if not coyote_node.is_stopped():
			character_velocity.y = character_jump(1)
			coyote_node.stop()
		else:
			jump_allowance_node.start()
		
	if is_on_floor() && not jump_allowance_node.is_stopped():
		character_velocity.y = character_jump(1)
		jump_allowance_node.stop()
	
	# Direction Input
	if (is_pressed("left")):
		direction = -1
	elif (is_pressed("right")):
		direction = 1
	else:
		direction = 0
		
	if direction != 0:
		is_left = (direction == -1)
	
	#Apply Accelerations
	#Both Dodging and wall jumps are set character X speeds while they are in control

	var tile_acceleration_modifier = 1.0 
	#get_tile_mod(1, 1, 0.3, true)
	var speed_modifier = 1.0
	#get_tile_mod(2, 1.0, 0.2, true)
	
	if dash_node.is_stopped():
		var adjust_rate = acceleration * tile_acceleration_modifier
		if direction != clamp(velocity.x,-1,1):
			adjust_rate = decceleration * tile_acceleration_modifier
			
		var _velocity = velocity.x
		character_velocity.x = lerp(_velocity, direction * speed * speed_modifier,adjust_rate)
	
	#Handle Dash
	if is_just_pressed("dash"):
		character_velocity.y = 0
		var dash_velocity = dash_speed
		if is_left:
			dash_velocity = dash_velocity * -1
		character_velocity.x = dash_velocity
		dash_node.start()
		#dust_burst.rotation = (direction * -1)
		#dust_burst.restart()
		#dust_burst.emitting = true

func get_tile_mod(tile_id : int, default : Variant, mod_value : Variant, TileBelow : bool = false) -> Variant:
	var TileBelowPos : Vector2 = Vector2(position.x, position.y)
	if TileBelow:
		TileBelowPos = Vector2(position.x, position.y + 20)
		
	var tile_found = World.get_custom_data(TileBelowPos)
	var result = default
	if tile_id == tile_found:
		result = mod_value
	
	return result


func update_player_state():
	if is_on_floor():
		cur_jump_count = 0
		if !was_on_floor:
			player_state = PlayerStates.Landed
		elif direction != 0:
			player_state = PlayerStates.Walk
		elif direction == 0:
			player_state = PlayerStates.Idle
	else:
		if velocity.y < 0:
			player_state = PlayerStates.Jumping
		else:
			player_state = PlayerStates.Falling
			
	#if player_state != previous_player_state:
	#	print("State Changed = "+str(player_state))
	
func final_update():
	previous_player_state = player_state
	was_on_floor = is_on_floor()
	sync_input_dicts()

func update_player_physics(delta):
	if not is_on_floor() and dash_node.is_stopped():
		var gravity_modifier = 1
		
		if velocity.y < apex_threshold && velocity.y > -(apex_threshold):
			gravity_modifier = apex_float_modifier
		character_velocity.y += gravity * gravity_modifier * delta
	
	if character_velocity.y > 0:
		character_velocity.y = clamp(character_velocity.y,0,max_fall_velocity)
	
	velocity.y = character_velocity.y
	velocity.x = character_velocity.x

func _test_only_code() -> void:
	if is_pressed("release_control"):
		input_dict["release_control"] = false
		set_controller(human_controller.new(self))

func player_final(delta : float) -> void:
	pass
	
func _physics_process(delta):
	get_character_input()
	update_player_physics(delta)
	update_player_state()
	update_animation()
	move_and_slide()
	player_final(delta)
	
	# Coyote Time Check
	if was_on_floor && not is_on_floor() && velocity.y == 0:
		coyote_node.start()
	
	_test_only_code()
	
	final_update()

func _on_area_2d_body_entered(body):
	if body.is_in_group("collectable"):
		body.Collect()
