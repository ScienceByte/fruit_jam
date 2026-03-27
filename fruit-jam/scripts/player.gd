extends CharacterBody3D

@onready var head: Node3D = $head

var curr_speed = 0

@export var walking_speed = 5.0
const sprinting_speed = 25.0
const crouch_speed = 3.0
const jump_velocity = 4.5

const mouse_sens  = 0.2

# something like walking on ice. 
var lerp_speed = 15.0

var direction  = Vector3.ZERO

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
func _physics_process(delta: float) -> void:
	
	

		
		
	# input action 
	
	
	if Input.is_action_pressed("crouch"):
		curr_speed = crouch_speed
	else:
		if Input.is_action_pressed("sprint"):
			curr_speed = sprinting_speed
		else:
			curr_speed = walking_speed
	
	
	
	
	
	# Add the gravity.
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerp_speed)
	if direction:
		velocity.x = direction.x * curr_speed
		velocity.z = direction.z * curr_speed
	else:
		velocity.x = move_toward(velocity.x, 0, curr_speed)
		velocity.z = move_toward(velocity.z, 0, curr_speed)

	move_and_slide()
