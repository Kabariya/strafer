# Head look and bob with footsteps
# Copyright (c) 2022 ic3bug
# MIT License
extends Node3D

const MOUSE_SENS : float = 3.0
const CAM_BOB : float = 0.33
const STEP_SPEED : float = 25.0

var bob_enabled : bool = true
var t : float = 0.0
var cam_pos : Vector2

# Feet
var left_played : bool = false
var right_played : bool = false
var was_on_floor : bool = false

@onready var character : CharacterBody3D = get_parent()
@onready var feet = character.get_node("Feet")
@onready var feet_sounds = [
	preload("res://sounds/player/steps/concrete_01.ogg"),
	preload("res://sounds/player/steps/concrete_02.ogg"),
	preload("res://sounds/player/steps/concrete_03.ogg"),
	preload("res://sounds/player/steps/concrete_04.ogg"),
	preload("res://sounds/player/steps/concrete_05.ogg"),
	preload("res://sounds/player/steps/concrete_06.ogg")
]
@onready var land_sounds = [
	preload("res://sounds/player/steps/land_concrete_01.ogg"),
	preload("res://sounds/player/steps/land_concrete_02.ogg"),
	preload("res://sounds/player/steps/land_concrete_03.ogg"),
	preload("res://sounds/player/steps/land_concrete_04.ogg"),
	preload("res://sounds/player/steps/land_concrete_05.ogg")
]
@onready var jump_sounds = [
	preload("res://sounds/player/steps/jump_concrete_01.ogg"),
	preload("res://sounds/player/steps/jump_concrete_02.ogg"),
	preload("res://sounds/player/steps/jump_concrete_03.ogg")
]

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotation.x -= event.relative.y * MOUSE_SENS * 0.001
		rotation.x = clamp(rotation.x, -1.5, 1.5)
		
		character.rotation.y -= event.relative.x * MOUSE_SENS * 0.001
		character.rotation.y = wrapf(character.rotation.y, 0.0, TAU)

func _physics_process(delta):
	var is_on_floor = character.is_on_floor()
	var slide = character.slide
	var speed_clamped = remap(character.hvel.length(), 0.0, character.MAX_SPEED, 0.0, 1.0)
	var grounded = float(is_on_floor)
	t += delta * STEP_SPEED * speed_clamped * grounded
	var tcam_pos = Vector2(sin(t) * CAM_BOB, cos(t * 0.5) * CAM_BOB)
	if speed_clamped <= 0.1:
		t = 0.0
		tcam_pos = Vector2.ZERO
	cam_pos = lerp(cam_pos, tcam_pos, delta * 5.0)
	cam_pos = lerp(cam_pos, tcam_pos, delta * 5.0)
	$Camera.transform.origin.x = cam_pos.y * float(bob_enabled)
	$Camera.transform.origin.y = cam_pos.x * float(bob_enabled)
	if is_on_floor and slide < 0.1:
		if cam_pos.y >= 0.12 and !right_played:
			play_random_sound(speed_clamped)
			left_played = false
			right_played = true
		if cam_pos.y <= -0.12 and !left_played:
			play_random_sound(speed_clamped)
			left_played = true
			right_played = false
	if slide < 0.1:
		if was_on_floor and !is_on_floor:
			play_random_sound(speed_clamped, jump_sounds)
		if is_on_floor and !was_on_floor:
			play_random_sound(speed_clamped, land_sounds)
	was_on_floor = is_on_floor

func play_random_sound(speed : float, sounds : Array = feet_sounds) -> void:
	var current = sounds[0]
	feet.stream = current
	feet.play()
	feet.volume_db = linear_to_db(speed)
	sounds.shuffle()
	sounds.erase(current)
	sounds.push_back(current)
