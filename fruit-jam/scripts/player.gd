extends CharacterBody3D

@onready var head: Node3D = $head
@onready var anim_player: AnimationPlayer = $AnimationPlayer

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
@export var dash_cooldown = 3000
@export var dash_duration = 0.099

var is_dashing = false
var dash_timer : float = 0
var dash_direction = Vector3.ZERO
var dash_start_velocity = Vector3(velocity.x, 0.0, velocity.z)
var last_dash_time : int = -1000

#air resistence
var air_resistence : Vector3 = Vector3(-9.8,0,-9.8)


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
	var input_direction : Vector3 = Vector3.ZERO
	
	input_direction.y = -$head.global_transform.basis.z.y / 5
	
	if Input.is_key_pressed(KEY_W):
		input_direction -= global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		input_direction -= global_transform.basis.x
	if Input.is_key_pressed(KEY_S):
		input_direction += global_transform.basis.z
		input_direction.y = $head.global_transform.basis.z.y / 8
	if Input.is_key_pressed(KEY_D):
		input_direction += global_transform.basis.x
	if input_direction == Vector3.ZERO:
		input_direction = -global_transform.basis.z
	dash_direction = input_direction.normalized()
	
	
	dash_start_velocity = Vector3(velocity.x, velocity.y, velocity.z)

func _physics_process(delta: float) -> void:
	var now : int = Time.get_ticks_msec()
	print("(",global_transform.basis.z.x, "," ,-$head.global_transform.basis.z.y, "," ,global_transform.basis.z.z, ")")
	if (now - last_dash_time) >= dash_cooldown:
		print("Dash ready")
	# input action
	if Input.is_action_pressed("crouch"):
		curr_speed = crouch_speed
	elif Input.is_action_pressed("sprint"):
		curr_speed = sprinting_speed
	else:
		curr_speed = walking_speed

	# gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
		velocity.x += air_resistence.x * delta
		velocity.z += air_resistence.z * delta

	# If player presses space, jump 
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = jump_velocity
	
	if Input.is_key_pressed(KEY_E):
	# if player presses jump during dash, save it for when dash ends
	
		if ((now - last_dash_time) >= dash_cooldown) and not is_dashing:
			start_dash()
			last_dash_time = now

	if is_dashing:
		var added_velocity : Vector3 = Vector3.ZERO
		added_velocity = added_velocity.lerp(dash_start_velocity, delta * dash_duration)
		velocity.x = added_velocity.x + dash_direction.x * dash_speed
		velocity.y = added_velocity.y * 10 + dash_direction.y * dash_speed
		velocity.z = added_velocity.z + dash_direction.z * dash_speed
		move_and_slide()
		dash_timer -= delta
		if dash_timer < 0:
			is_dashing = false
			dash_timer = 0

	else:
		# normal movement
		var input_dir := Input.get_vector("left", "right", "forward", "backward")
		var wish_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		direction = direction.lerp(wish_dir, delta * lerp_speed)
		
		if direction != Vector3.ZERO:
			velocity.x = direction.x * curr_speed
			velocity.z = direction.z * curr_speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, curr_speed)
			velocity.z = move_toward(velocity.z, 0.0, curr_speed)	
		move_and_slide()
	
func _process(delta):
	if Input.is_action_just_pressed("attack"):
		anim_player.play("Attack")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name  == "Attack":
		anim_player.play("WeaponIdle")
