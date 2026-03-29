extends CharacterBody3D

enum State {
	IDLE,
	TIPOVER,
	REVING,
	ROLLING,
	GETUP
}

@onready var player: Node3D = get_tree().get_first_node_in_group("player")
@onready var anim_player: AnimationPlayer = $AnimationPlayer

@onready var hitbox: Area3D = $"Pivot/can-open2/Area3D"
@onready var attack_box: Area3D = $"Pivot/can-open2/Area3D2"
@onready var can_open_2: MeshInstance3D = $"Pivot/can-open2"

@onready var standing_collision: CollisionShape3D = $StandingCollision
@onready var rolling_collision: CollisionShape3D = $RollingCollision

@export var roll_speed: float = 13.0
@export var roll_distance: float = 20.0
@export var attack_range: float = 20.0
@export var rev_duration: float = 2.0
@export var damage_amount: int = 10
@export var attack_box_forward_offset: float = 0.45
@export var animation_blend_time: float = 1.0
@export var getup_blend_time: float = 0.8
@export var floor_snap_distance: float = 0.6
@export var player_launch_horizontal_speed: float = 28.0
@export var player_launch_vertical_speed: float = 14.0
@export var launch_away_from_roll_direction: bool = true

var health: int = 40
var state: int = State.IDLE

var target: Vector3 = Vector3.ZERO
var start: Vector3 = Vector3.ZERO
var roll_direction: Vector3 = Vector3.ZERO
var state_timer: float = 0.0

var damaged_bodies_this_roll: Array[Node] = []

var rev_started := false
var rolling_started := false
var tipover_started := false
var getup_started := false
var hitbox_rest_position: Vector3 = Vector3.ZERO
var attack_box_rest_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	hitbox.monitoring = false
	attack_box.monitoring = false
	floor_snap_length = floor_snap_distance
	set_collision_mode(false) # start standing
	hitbox_rest_position = hitbox.position
	attack_box_rest_position = attack_box.position

	if not anim_player.animation_finished.is_connected(_on_animation_player_animation_finished):
		anim_player.animation_finished.connect(_on_animation_player_animation_finished)

	if not attack_box.area_entered.is_connected(_on_attack_box_area_entered):
		attack_box.area_entered.connect(_on_attack_box_area_entered)
	if not attack_box.body_entered.is_connected(_on_attack_box_body_entered):
		attack_box.body_entered.connect(_on_attack_box_body_entered)


func set_collision_mode(is_rolling_mode: bool) -> void:
	standing_collision.set_deferred("disabled", is_rolling_mode)
	rolling_collision.set_deferred("disabled", not is_rolling_mode)


func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	match state:
		State.IDLE:
			handle_idle(delta)
		State.TIPOVER:
			handle_tipover(delta)
		State.REVING:
			handle_reving(delta)
		State.ROLLING:
			handle_rolling(delta)
		State.GETUP:
			handle_getup(delta)

	move_and_slide()
	sync_damage_areas()

	if state == State.ROLLING or state == State.TIPOVER:
		apply_roll_damage_from_overlaps()

	if state == State.ROLLING:
		if is_on_wall():
			enter_getup()
			return

		var flat_travel := get_tracking_position() - start
		flat_travel.y = 0.0
		if flat_travel.length() >= roll_distance:
			enter_getup()
			return


func handle_idle(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0

	if player == null:
		return

	var dist := get_tracking_position().distance_to(player.global_position)
	if dist <= attack_range:
		start_attack()


func start_attack() -> void:
	if player == null:
		return

	state = State.TIPOVER
	rev_started = false
	rolling_started = false
	tipover_started = false
	getup_started = false
	state_timer = 0.0

	hitbox.monitoring = false
	attack_box.monitoring = false
	damaged_bodies_this_roll.clear()
	set_collision_mode(false)

func handle_reving(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0

	if player == null:
		return

	var look_target := player.global_position
	look_target.y = get_tracking_position().y
	look_at(look_target, Vector3.UP)

	if not rev_started:
		rev_started = true
		state_timer = rev_duration
		anim_player.play("Reving", animation_blend_time)

	state_timer -= delta
	if state_timer <= 0.0:
		begin_roll()


func begin_roll() -> void:
	if player == null:
		return

	target = player.global_position
	target.y = get_tracking_position().y
	start = get_tracking_position()

	var to_target := target - start
	if to_target.length_squared() > 0.0001:
		roll_direction = to_target.normalized()
	else:
		roll_direction = -global_transform.basis.z.normalized()

	state = State.ROLLING
	rolling_started = false
	damaged_bodies_this_roll.clear()

	hitbox.monitoring = true
	attack_box.monitoring = true
	set_collision_mode(true) # rolling collision on
	sync_damage_areas()


func handle_rolling(delta: float) -> void:
	if not rolling_started:
		rolling_started = true
		anim_player.play("Rolling", animation_blend_time)

	velocity.x = roll_direction.x * roll_speed
	velocity.z = roll_direction.z * roll_speed

	var face_dir := Vector3(roll_direction.x, 0.0, roll_direction.z)
	if face_dir.length_squared() > 0.0001:
		look_at(global_position + face_dir, Vector3.UP)


func enter_getup() -> void:
	if state == State.GETUP:
		return

	state = State.GETUP
	getup_started = false

	hitbox.monitoring = false
	attack_box.monitoring = false
	damaged_bodies_this_roll.clear()


func handle_tipover(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0

	if not tipover_started:
		tipover_started = true
		set_collision_mode(true)
		anim_player.play("TipOver", animation_blend_time)


func handle_getup(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0

	if not getup_started:
		getup_started = true
		anim_player.play("GetUp", getup_blend_time)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "TipOver" and state == State.TIPOVER:
		state = State.REVING
		rev_started = false

	elif anim_name == "GetUp" and state == State.GETUP:
		set_collision_mode(false) # back to standing shape
		face_player()
		state = State.IDLE
		rev_started = false
		rolling_started = false
		tipover_started = false
		getup_started = false


func _on_attack_box_area_entered(area: Area3D) -> void:
	_apply_roll_damage(area)


func _on_attack_box_body_entered(body: Node3D) -> void:
	_apply_roll_damage(body)


func _apply_roll_damage(hit_node: Node) -> void:
	if state != State.ROLLING and state != State.TIPOVER:
		return

	var target := _resolve_damage_target(hit_node)
	if target == null:
		return

	if damaged_bodies_this_roll.has(target):
		return

	if target == player or target.is_in_group("player"):
		if state == State.ROLLING and target.has_method("take_damage"):
			print("Can enemy dealt ", damage_amount, " damage to ", target.name)
			target.take_damage(damage_amount)

		_apply_launch_to_target(target)
		damaged_bodies_this_roll.append(target)


func apply_roll_damage_from_overlaps() -> void:
	for area in attack_box.get_overlapping_areas():
		_apply_roll_damage(area)

	for body in attack_box.get_overlapping_bodies():
		_apply_roll_damage(body)


func _resolve_damage_target(hit_node: Node) -> Node:
	var current := hit_node

	while current != null:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()

	return null


func _apply_launch_to_target(target: Node) -> void:
	if not target.has_method("apply_knockback"):
		return

	var launch_dir := Vector3(roll_direction.x, 0.0, roll_direction.z)
	var using_roll_direction := launch_dir.length_squared() > 0.0001

	if not using_roll_direction and target is Node3D:
		launch_dir = (target as Node3D).global_position - get_tracking_position()
		launch_dir.y = 0.0

	if launch_dir.length_squared() <= 0.0001:
		launch_dir = -global_transform.basis.z
		launch_dir.y = 0.0

	if launch_dir.length_squared() <= 0.0001:
		return

	launch_dir = launch_dir.normalized()
	if using_roll_direction and launch_away_from_roll_direction:
		launch_dir = -launch_dir

	var launch_velocity := launch_dir * player_launch_horizontal_speed
	launch_velocity.y = player_launch_vertical_speed
	target.apply_knockback(launch_velocity)


func face_player() -> void:
	if player == null:
		return

	var look_target := player.global_position
	look_target.y = get_tracking_position().y
	look_at(look_target, Vector3.UP)


func get_tracking_position() -> Vector3:
	if not rolling_collision.disabled:
		return rolling_collision.global_position

	if not standing_collision.disabled:
		return standing_collision.global_position

	return global_position


func sync_damage_areas() -> void:
	if state == State.ROLLING:
		var hit_center := get_tracking_position()
		var attack_dir := Vector3(roll_direction.x, 0.0, roll_direction.z)
		if player != null:
			var to_player := player.global_position - hit_center
			if to_player.length_squared() > 0.0001:
				attack_dir = to_player.normalized()

		hitbox.global_position = hit_center
		attack_box.global_position = hit_center + attack_dir * attack_box_forward_offset
		return

	hitbox.position = hitbox_rest_position
	attack_box.position = attack_box_rest_position


func take_damage(damage_taken: int) -> void:
	print("Can enemy took ", damage_taken, " damage")
	health -= damage_taken
	if health <= 0:
		queue_free()
