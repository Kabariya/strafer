# Strafing mechanics for Godot 4.0
# Copyright (c) 2022 ic3bug
# MIT License
class_name Player
extends CharacterBody3D

const GRAVITY : float = 32.0
const MAX_SPEED : float = 20.0
const MAX_ACCEL : float = 150.0
const JUMP_FORCE : float = 12.0
const FRICTION : float = 0.86
# Increase air drag by tiny amounts 
# To make strafing faster
const AIR_DRAG : float = 0.98
# Amount of directional control
const CONTROL : float = 15.0

var hvel : Vector3
var dir : Vector3
var height : float
var crouch : float
var slide : float

func _ready():
	Game.player = self

func _physics_process(delta : float) -> void:
	handle_bounds()
	handle_movement(delta)
	handle_crouch(delta)
	handle_rush()

func handle_bounds() -> void:
	if global_transform.origin.y <= -100.0:
		global_transform.origin = Vector3.ONE

func handle_movement(delta : float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Jumping
	if Input.is_action_pressed("move_jump") and is_on_floor() and crouch < 0.1:
		velocity.y = JUMP_FORCE
		$Huh.play()

	# Input direction
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Movement direction
	dir = lerp(dir, (transform.basis * Vector3(input.x, 0, input.y)).normalized(), delta * CONTROL)

	# Friction and air drag for horizontal velocity
	hvel = velocity
	hvel.y = 0.0
	var decel = FRICTION if is_on_floor() else AIR_DRAG
	hvel *= decel
	
	# Zero out horizontal velocity if speed is too small
	if hvel.length() < MAX_SPEED * 0.01:
		hvel = Vector3.ZERO
	
	# Acceleration
	# Here lies the strafing mechanic (bug)
	# Projection of the horizontal velocity to the direction
	var speed = hvel.dot(dir)
	# Whenever the amount of acceleration to add is clamped by the maximum acceleration constant
	# Player can make the speed faster by bringing the direction closer to horizontal velocity angle
	# More info here: https://youtu.be/v3zT3Z5apaM?t=165
	var max_speed = MAX_SPEED if crouch < 0.1 else MAX_SPEED * 0.25
	var accel : float = clamp(max_speed - speed, 0.0, MAX_ACCEL * delta)
	hvel += dir * accel
	
	# Apply horizontal velocity to final velocity
	velocity.x = hvel.x
	velocity.z = hvel.z
	
	# Godot's move and slide function
	move_and_slide()

# Crouch walking
func handle_crouch(delta : float) -> void:
	# Crouch
	crouch = float(Input.is_action_pressed("move_crouch")) * 0.5
	if (height < 1.0 and $Ceiling.is_colliding()) or slide > 0.1:
		crouch = 0.5
	height = lerp(height, clamp(1.0 - crouch, 0.5, 1.0), delta * 10.0)
	# Height
	$Ground.shape.length = height + 0.5
	$Collision.shape.height = height
	$Head.global_transform.origin = global_transform.origin + Vector3.UP * height * 0.5
	$Ceiling.global_transform.origin = $Head.global_transform.origin

# Apply velocity
func push(force : float, direction : Vector3):
	velocity = direction * force

# Wind rush
func handle_rush() -> void:
	var speed_clamped = remap(pow(velocity.length(), 2), 0.0, MAX_SPEED * 250.0, 0.0, 1.0)
	$Rush.volume_db = linear_to_db(speed_clamped)
