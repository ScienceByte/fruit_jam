extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var label_3d: Label3D = $Label3D
@onready var area_3d: Area3D = $Area3D
var interact_popup: Label = null
var player_body: Node3D = null
var player_hurtbox: Area3D = null


#### text duration
@export var interaction_text_duration: float = 2.5
@export var dialogue_id: String = ""
var interaction_started: bool = false
var interaction_timer: float = 0.0


func _ready() -> void:
	# uncomment this and add text at the bottom of the script
	# label.text = default_text
	label_3d.visible = false




	area_3d.collision_mask = area_3d.collision_mask | 2
	_resolve_player_nodes()

	if not area_3d.body_entered.is_connected(_on_area_3d_body_entered):
		area_3d.body_entered.connect(_on_area_3d_body_entered)
	if not area_3d.body_exited.is_connected(_on_area_3d_body_exited):
		area_3d.body_exited.connect(_on_area_3d_body_exited)
	if not area_3d.area_entered.is_connected(_on_area_3d_area_entered):
		area_3d.area_entered.connect(_on_area_3d_area_entered)
	if not area_3d.area_exited.is_connected(_on_area_3d_area_exited):
		area_3d.area_exited.connect(_on_area_3d_area_exited)

	_refresh_interact_popup_visibility()
	call_deferred("_refresh_interact_popup_visibility")



func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
#	if direction:
#		velocity.x = direction.x * SPEED
#		velocity.z = direction.z * SPEED
#	else:
#		velocity.x = move_toward(velocity.x, 0, SPEED)
#		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	if interaction_timer > 0.0:
		interaction_timer = max(interaction_timer - delta, 0.0)
		if interaction_timer <= 0.0:
			interaction_started = false
	_refresh_interact_popup_visibility()


func _input(event: InputEvent) -> void:
	if _is_interact_event(event) and _is_player_inside_area():
		interaction_started = true
		interaction_timer = interaction_text_duration
		_refresh_interact_popup_visibility()
		if dialogue_id != "":
			DialogueManager.start_conversation(dialogue_id)


func _is_interact_event(event: InputEvent) -> bool:
	if event.is_action_pressed("Interact"):
		return true

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F:
			return true

	return false


func _on_area_3d_body_entered(_body: Node3D) -> void:
	_refresh_interact_popup_visibility()


func _on_area_3d_body_exited(_body: Node3D) -> void:
	_refresh_interact_popup_visibility()

func _on_area_3d_area_entered(_area: Area3D) -> void:
	_refresh_interact_popup_visibility()


func _on_area_3d_area_exited(_area: Area3D) -> void:
	_refresh_interact_popup_visibility()


func _refresh_interact_popup_visibility() -> void:
	if player_body == null or not is_instance_valid(player_body):
		_resolve_player_nodes()

	var in_range := _is_player_inside_area()
	if not in_range and interaction_timer <= 0.0:
		interaction_started = false

	if interact_popup == null:
		interact_popup = _find_interact_popup()

	var showing_interaction_text := interaction_started and interaction_timer > 0.0
	label_3d.visible = showing_interaction_text

	if interact_popup != null:
		interact_popup.visible = in_range and not showing_interaction_text


func _resolve_player_nodes() -> void:
	var candidate := get_tree().get_first_node_in_group("player")
	if candidate is Node3D:
		player_body = candidate as Node3D
		var hurtbox := player_body.get_node_or_null("Area3D")
		if hurtbox is Area3D:
			player_hurtbox = hurtbox as Area3D
		else:
			player_hurtbox = null


func _find_interact_popup() -> Label:
	var player_node := get_tree().get_first_node_in_group("player")
	if player_node == null:
		return null

	var popup := player_node.get_node_or_null("CanvasLayer/Interact-popup")
	if popup is Label:
		return popup as Label

	return null


func _is_player_inside_area() -> bool:
	if player_hurtbox != null and is_instance_valid(player_hurtbox) and area_3d.overlaps_area(player_hurtbox):
		return true

	if player_body != null and is_instance_valid(player_body) and area_3d.overlaps_body(player_body):
		return true

	for body in area_3d.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true

	return false


#### add text here
#func show_file_text(path: String) -> void:
#	if FileAccess.file_exists(path): #### add you text file here
#		label.text = FileAccess.get_file_as_string(path)
