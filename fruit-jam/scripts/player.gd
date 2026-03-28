extends CharacterBody3D

@onready var head: Node3D = $head
@onready var weapon_hitbox: Area3D = $head/Camera3D/WeaponPivot/MeshInstance3D/WeaponHitbox
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var curr_speed = 5.0

@export var walking_speed = 5.0
const sprinting_speed = 25.0
const crouch_speed = 3.0
const jump_velocity = 4.5

const mouse_sens = 0.2

# something like walking on ice.
var lerp_speed = 15.0
var direction = Vector3.ZERO

# dash settings
@export var dash_speed = 24.0
@export var dash_duration = 0.18
@export var dash_cooldown_ms = 3000
@export var double_tap_window_ms= 250

var is_dashing = false
var dash_timer = 0.0
var dash_direction= Vector3.ZERO
var dash_start_velocity= Vector3.ZERO
var last_dash_time= -1000
var last_dash_end_time= -1000

# jump buffer after dash
var pending_jump = false
var pending_jump_time= -10
var buffered_jump_after_dash = false
@export var post_dash_jump_window_ms= 150

# attack settings
var last_attack_time= -1000000
@export var attack_cooldown_ms = 600
var is_attacking = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	weapon_hitbox.monitoring = false

	if not anim_player.animation_finished.is_connected(_on_animation_player_animation_finished):
		anim_player.animation_finished.connect(_on_animation_player_animation_finished)

	anim_player.play("WeaponIdle")


func _input(event):
	# escape releases mouse
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	# click to recapture mouse
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


func start_attack(now: int) -> void:
	last_attack_time = now
	is_attacking = true
	weapon_hitbox.monitoring = true
	anim_player.play("WeaponAttack")


func _physics_process(delta) -> void:
	var now: int = Time.get_ticks_msec()

	# attack input
	if Input.is_action_just_pressed("attack") and not is_attacking and now - last_attack_time >= attack_cooldown_ms:
		start_attack(now)

	# movement speed
	if Input.is_action_pressed("crouch"):
		curr_speed = crouch_speed
	elif Input.is_action_pressed("sprint"):
		curr_speed = sprinting_speed
	else:
		curr_speed = walking_speed

	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# jump / dash input
	if Input.is_action_just_pressed("ui_accept"):
		if is_dashing:
			buffered_jump_after_dash = true
		else:
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

	# single tap becomes jump if second tap never happens
	if pending_jump and now - pending_jump_time > double_tap_window_ms:
		pending_jump = false
		if is_on_floor():
			velocity.y = jump_velocity

	# dash movement
	if is_dashing:
		dash_timer -= delta
		velocity.x = dash_start_velocity.x + dash_direction.x * dash_speed
		velocity.z = dash_start_velocity.z + dash_direction.z * dash_speed

		move_and_slide()

		if dash_timer <= 0.0:
			is_dashing = false
			last_dash_end_time = now

			if buffered_jump_after_dash and is_on_floor():
				velocity.y = jump_velocity

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
		velocity.x = move_toward(velocity.x, 0.0, curr_speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, curr_speed * delta)

	move_and_slide()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "WeaponAttack":
		is_attacking = false
		weapon_hitbox.monitoring = false
		anim_player.play("WeaponIdle")
