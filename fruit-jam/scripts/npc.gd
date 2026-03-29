extends CharacterBody3D

@export var npc_name: String = "Neighbor"
@export var dialogue_id: String = "neighbor_start"
@export var wander_radius: float = 3.0
@export var walk_speed: float = 1.5

enum State { IDLE, WANDER, TALKING }
var current_state: State = State.IDLE

var start_position: Vector3
var wander_target: Vector3
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var interaction_area: Area3D = $Area3D
var player_node: Node3D = null

func _ready() -> void:
	start_position = global_position
	pick_new_wander_target()
	
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)
	
	$StateTimer.timeout.connect(_on_timer_timeout)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	match current_state:
		State.WANDER:
			var direction = (wander_target - global_position).normalized()
			direction.y = 0
			velocity.x = direction.x * walk_speed
			velocity.z = direction.z * walk_speed
			
			if velocity.length() > 0.1:
				var look_pos = global_position - velocity
				look_pos.y = global_position.y
				look_at(look_pos, Vector3.UP)
			
			if global_position.distance_to(wander_target) < 0.5:
				current_state = State.IDLE
				velocity = Vector3.ZERO
				
		State.TALKING:
			velocity = Vector3.ZERO
			if player_node:
				var look_pos = player_node.global_position
				look_pos.y = global_position.y
				look_at(look_pos, Vector3.UP)
				
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, walk_speed)
			velocity.z = move_toward(velocity.z, 0, walk_speed)

	move_and_slide()

func pick_new_wander_target() -> void:
	var random_x = randf_range(-wander_radius, wander_radius)
	var random_z = randf_range(-wander_radius, wander_radius)
	wander_target = start_position + Vector3(random_x, 0, random_z)

func _on_timer_timeout() -> void:
	if current_state != State.TALKING:
		if current_state == State.IDLE:
			pick_new_wander_target()
			current_state = State.WANDER
		else:
			current_state = State.IDLE

# NPC LOGIC
func _on_player_entered(body: Node3D) -> void:
	if body.name == "player":
		player_node = body

func _on_player_exited(body: Node3D) -> void:
	if body.name == "player":
		player_node = null

func _unhandled_input(event: InputEvent) -> void:
	if player_node != null and event.is_action_pressed("Interact"):
		current_state = State.TALKING
		DialogueManager.start_conversation(dialogue_id)
