extends CharacterBody3D

enum State {
	IDLE,
	ASCEND,
	HOVER_MOVE,
	HOVER_WAIT,
	STOMP,
	RECOVER
}

static var active_warning_sources: int = 0

var warning_label: Label
@onready var player: Node3D = get_tree().get_first_node_in_group("player")
@onready var attack_area: Area3D = $MeshInstance3D/AttackArea
@onready var damaged: AudioStreamPlayer3D = $damaged

@onready var warning_zone_root: Node3D = $MeshInstance3D2
@onready var warning_area: Area3D = $MeshInstance3D2/WarningArea

@export var stomp_trigger_range = 20.0
@export var hover_height = 10.0
@export var ascend_speed = 10.0
@export var hover_move_speed = 12.0
@export var stomp_fall_speed = 30.0
@export var hover_time = 2.5
@export var recovery_time = 1.7
@export var damage_amount = 20
@export var landing_snap_distance: float = 0.35
@export var initial_attack_delay: float = 0.0

var state: State = State.IDLE
var state_timer = 0.0

var stomp_target: Vector3 = Vector3.ZERO
var hover_target: Vector3 = Vector3.ZERO
var start_y = 0.0
var target_hover_y = 0.0

var damaged_bodies_this_stomp: Array[Node] = []
var attack_delay_timer: float = 0.0
var is_warning_source_active := false

var health: int = 50

func _ready() -> void:
	attack_area.monitoring = false
	warning_zone_root.visible = false
	resolve_warning_label()
	refresh_warning_label_visibility()
	attack_delay_timer = maxf(initial_attack_delay, 0.0)

	if not attack_area.area_entered.is_connected(_on_attack_area_area_entered):
		attack_area.area_entered.connect(_on_attack_area_area_entered)
	if not warning_area.area_entered.is_connected(_on_warning_area_area_entered):
		warning_area.area_entered.connect(_on_warning_area_area_entered)
	if not warning_area.area_exited.is_connected(_on_warning_area_area_exited):
		warning_area.area_exited.connect(_on_warning_area_area_exited)
	if not warning_area.body_entered.is_connected(_on_warning_area_body_entered):
		warning_area.body_entered.connect(_on_warning_area_body_entered)
	if not warning_area.body_exited.is_connected(_on_warning_area_body_exited):
		warning_area.body_exited.connect(_on_warning_area_body_exited)

	print("Milk enemy ready")
	print("Player found: ", player)


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			handle_idle(delta)
		State.ASCEND:
			handle_ascend(delta)
		State.HOVER_MOVE:
			handle_hover_move(delta)
		State.HOVER_WAIT:
			handle_hover_wait(delta)
		State.STOMP:
			handle_stomp(delta)
		State.RECOVER:
			handle_recover(delta)
	move_and_slide()


func handle_idle(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0

	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	if not is_on_floor():
		velocity.y += get_gravity().y
	else:
		velocity.y = 0.0

	if attack_delay_timer > 0.0:
		attack_delay_timer = maxf(attack_delay_timer - delta, 0.0)
		return

	var dist = global_position.distance_to(player.global_position)
	
	
	
	if dist <= stomp_trigger_range and is_on_floor():
		start_stomp_sequence()


func start_stomp_sequence() -> void:
	state = State.ASCEND
	start_y = global_position.y
	target_hover_y = start_y + hover_height
	damaged_bodies_this_stomp.clear()

	attack_area.monitoring = false
	warning_zone_root.visible = false
	deactivate_warning_source()

	velocity.x = 0.0
	velocity.z = 0.0
	velocity.y = ascend_speed


func handle_ascend(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	velocity.y = ascend_speed

	if global_position.y >= target_hover_y:
		global_position.y = target_hover_y

		stomp_target = player.global_position
		stomp_target.y = 0.05

		hover_target = Vector3(stomp_target.x, target_hover_y, stomp_target.z)

		warning_zone_root.global_position = stomp_target
		warning_zone_root.visible = true

		state = State.HOVER_MOVE
		velocity = Vector3.ZERO


func handle_hover_move(delta: float) -> void:
	var to_target = hover_target - global_position
	var horizontal = Vector3(to_target.x, 0.0, to_target.z)

	global_position.y = target_hover_y
	update_warning_zone_under_enemy()

	if horizontal.length() <= landing_snap_distance:
		global_position.x = hover_target.x
		global_position.z = hover_target.z
		
		update_warning_zone_under_enemy()

		state = State.HOVER_WAIT
		state_timer = hover_time
		velocity = Vector3.ZERO
		return

	horizontal = horizontal.normalized()
	velocity.x = horizontal.x * hover_move_speed
	velocity.z = horizontal.z * hover_move_speed
	velocity.y = 0.0

	look_at(Vector3(stomp_target.x, global_position.y, stomp_target.z), Vector3.UP)


func handle_hover_wait(delta: float) -> void:
	global_position.y = target_hover_y
	velocity = Vector3.ZERO
	update_warning_zone_under_enemy()
	state_timer -= delta

	if state_timer <= 0.0:
		state = State.STOMP
		attack_area.monitoring = true
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y = -stomp_fall_speed


func handle_stomp(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	velocity.y = -stomp_fall_speed

	if is_on_floor():
		attack_area.monitoring = false
		warning_zone_root.visible = false
		deactivate_warning_source()
		velocity = Vector3.ZERO

		state = State.RECOVER
		state_timer = recovery_time


func handle_recover(delta: float) -> void:
	velocity = Vector3.ZERO
	state_timer -= delta

	if state_timer <= 0.0:
		state = State.IDLE



func take_damage(damage_taken: int) -> void:
	print("Enemy took damage: ", damage_taken)
	health -= damage_taken
	if health <= 0:
		queue_free()
	damaged.play()


func _on_attack_area_area_entered(area: Area3D) -> void:
	var target = area.get_parent()
	if damaged_bodies_this_stomp.has(target):
		return

	print("Attack area touched hurtbox: ", area.name, " parent: ", target.name)

	if target == player or target.is_in_group("player"):
		if target.has_method("take_damage"):
			target.take_damage(damage_amount)
			damaged_bodies_this_stomp.append(target)


func update_warning_zone_under_enemy() -> void:
	warning_zone_root.global_position = Vector3(
		global_position.x,
		0.05,
		global_position.z
	)


func _set_warning_label_for_target(target: Node) -> void:
	if target == null:
		return
	if target == player or target.is_in_group("player"):
		activate_warning_source()


func _clear_warning_label_for_target(target: Node) -> void:
	if target == null:
		return
	if target == player or target.is_in_group("player"):
		deactivate_warning_source()


func resolve_warning_label() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player == null:
		warning_label = null
		return

	warning_label = player.get_node_or_null("CanvasLayer/WarningLabel") as Label


func set_warning_label_visible(is_visible: bool) -> void:
	if warning_label == null:
		resolve_warning_label()
	if warning_label != null:
		warning_label.visible = is_visible


func refresh_warning_label_visibility() -> void:
	set_warning_label_visible(active_warning_sources > 0)


func activate_warning_source() -> void:
	if is_warning_source_active:
		refresh_warning_label_visibility()
		return

	is_warning_source_active = true
	active_warning_sources += 1
	refresh_warning_label_visibility()


func deactivate_warning_source() -> void:
	if not is_warning_source_active:
		refresh_warning_label_visibility()
		return

	is_warning_source_active = false
	active_warning_sources = maxi(active_warning_sources - 1, 0)
	refresh_warning_label_visibility()


func _on_warning_area_area_entered(area: Area3D) -> void:
	_set_warning_label_for_target(area.get_parent())


func _on_warning_area_area_exited(area: Area3D) -> void:
	_clear_warning_label_for_target(area.get_parent())


func _on_warning_area_body_entered(body: Node3D) -> void:
	_set_warning_label_for_target(body)


func _on_warning_area_body_exited(body: Node3D) -> void:
	_clear_warning_label_for_target(body)


func set_spawn_attack_delay(delay_seconds: float) -> void:
	initial_attack_delay = maxf(delay_seconds, 0.0)
	attack_delay_timer = initial_attack_delay


func _exit_tree() -> void:
	deactivate_warning_source()
