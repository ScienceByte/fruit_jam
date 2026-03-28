extends CharacterBody3D

@onready var head: Node3D = $head

var curr_speed = 5.0

@export var walking_speed = 5.0
const sprinting_speed = 25.0
const crouch_speed = 3.0
const jump_velocity = 4.5

const mouse_sens  = 0.2

# something like walking on ice.
var lerp_speed = 15.0

var direction = Vector3.ZERO

# dash settings
@export var dash_speed = 24
@export var dash_duration = 0.18
@export var dash_cooldown_ms = 3000
@export var double_tap_window_ms = 250

var is_dashing = false
var dash_timer = 0.0
var dash_direction = Vector3.ZERO
var dash_start_velocity = Vector3(velocity.x, 0.0, velocity.z)

var last_dash_time = -1000

# first tap tracking for jump/dash
var pending_jump = false
var pending_jump_time = -10

# new: stores a jump pressed during dash
var buffered_jump_after_dash = false


var last_dash_end_time = -1000
@export var post_dash_jump_window_ms = 150



func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event):
	##### escape button releases mouse ######
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	########################################

	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func start_dash():
	is_dashing = true
	dash_timer = dash_duration

	dash_direction = -head.global_transform.basis.z
	dash_direction.y = 0.0
	dash_direction = dash_direction.normalized()
	
	dash_start_velocity = Vector3(velocity.x, 0.0, velocity.z)

func _physics_process(delta: float) -> void:
	var now = Time.get_ticks_msec()

	# input action
	if Input.is_action_pressed("crouch"):
		curr_speed = crouch_speed
	elif Input.is_action_pressed("sprint"):
		curr_speed = sprinting_speed
	else:
		curr_speed = walking_speed

	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# press space
	if Input.is_action_just_pressed("ui_accept"):
	# if player presses jump during dash, save it for when dash ends
		if is_dashing:
			buffered_jump_after_dash = true
		else:
			# if dash just ended, allow jump instantly
			if is_on_floor() and now - last_dash_end_time <= post_dash_jump_window_ms:
				pending_jump = false
				velocity.y = jump_velocity
			else:
				var tapped_twice = pending_jump and now - pending_jump_time <= double_tap_window_ms
				var dash_ready = now - last_dash_time >= dash_cooldown_ms

				if tapped_twice and dash_ready:
					pending_jump = false
					start_dash()
					last_dash_time = now
				else:
					pending_jump = true
					pending_jump_time = now

	# if enough time passed and there was no second tap, do the jump
	if pending_jump and now - pending_jump_time > double_tap_window_ms:
		pending_jump = false
		if is_on_floor():
			velocity.y = jump_velocity

	# dash movement takes priority
	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_start_velocity.x + dash_direction.x * dash_speed
		velocity.z = dash_start_velocity.z + dash_direction.z * dash_speed
		move_and_slide()

		if dash_timer <= 0.0:
			is_dashing = false
			last_dash_end_time = now

	# do buffered jump immediately after dash ends
		if buffered_jump_after_dash and is_on_floor():
			buffered_jump_after_dash = false
			velocity.y = jump_velocity
		else:
			buffered_jump_after_dash = false

			# do buffered jump immediately after dash ends
			if buffered_jump_after_dash and is_on_floor():
				buffered_jump_after_dash = false
				velocity.y = jump_velocity
			else:
				buffered_jump_after_dash = false

		return

	# normal movement
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var wish_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.lerp(wish_dir, delta * lerp_speed)

	if direction != Vector3.ZERO:
		velocity.x = direction.x * curr_speed
		velocity.z = direction.z * curr_speed
	else:
		velocity.x = move_toward(velocity.x, 0, curr_speed)
		velocity.z = move_toward(velocity.z, 0, curr_speed)

	move_and_slide()
