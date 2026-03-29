extends CharacterBody3D

@onready var navAg = $NavigationAgent3D
var movement_speed = 10
@onready var dTime = $deathTimer 
@onready var damaged: AudioStreamPlayer3D = $damaged
@onready var death: AudioStreamPlayer3D = $death

var back_off_time = 0
var back_off

@export var ledge_check_forward_distance: float = 0.9
@export var ledge_check_down_distance: float = 2.5
@export var ledge_check_up_offset: float = 0.5
@export var lower_player_height_threshold: float = 0.7

@export var max_health: int = 40
var health: int = max_health
signal health_changed(new_health: int, max_health: int)

@onready var player: Node3D = get_tree().get_first_node_in_group("player")

var follow = true

@onready var area = $Area3D

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")

	if abs($RigidBody3D/CollisionShape3D.global_rotation.z) > 1.4:
		death.play()
		fall()	
	
	if follow:
		if player == null:
			velocity = Vector3.ZERO
			move_and_slide()
			return

		var player_position = player.global_position
		var distance_from_player : Vector3
		distance_from_player.x = abs(position.x - player_position.x)
		distance_from_player.y = abs(position.y - player_position.y)
		distance_from_player.z = abs(position.z - player_position.z)
		
		if (back_off_time <= 0) and (pow(distance_from_player.z, 2) + pow(distance_from_player.y, 2) < 1.5):
			back_off = true
			back_off_time = 100
			player_position.x += -player.global_transform.basis.z.x * randi_range(6, 8)
			player_position.z += -player.global_transform.basis.z.z * randi_range(6, 8)
			navAg.set_target_position(player_position)
			if (pow(distance_from_player.z, 2) + pow(distance_from_player.y, 2)) < 1.25:
				player.take_damage(10)
			

		if not back_off:
			navAg.set_target_position(player_position)
		else:
			if back_off_time <= 0:
				back_off = false
			back_off_time -= 1
			
		var destination = navAg.get_next_path_position()
		var local_destination = destination - global_position
		var direction = local_destination.normalized()
		var is_chasing_player :bool = not back_off

		if should_avoid_ledge_drop(player_position, is_chasing_player) and not has_floor_ahead(direction):
			velocity = Vector3.ZERO
			move_and_slide()
			return

		if (abs(destination.y - position.y) > 0.5) or (abs(destination.z - position.z) > 0.5):
			movement_speed = 10
			velocity = direction * movement_speed
			move_and_slide()
	#print(health)


func should_avoid_ledge_drop(player_position: Vector3, is_chasing_player: bool) -> bool:
	if not is_chasing_player:
		return true

	# While directly chasing, allow dropping only if the player is clearly lower.
	var player_is_lower := player_position.y < global_position.y - lower_player_height_threshold
	return not player_is_lower


func has_floor_ahead(direction: Vector3) -> bool:
	var horizontal := Vector3(direction.x, 0.0, direction.z)
	if horizontal.length_squared() <= 0.0001:
		return true

	horizontal = horizontal.normalized()
	var ray_from := global_position + horizontal * ledge_check_forward_distance + Vector3.UP * ledge_check_up_offset
	var ray_to := ray_from + Vector3.DOWN * ledge_check_down_distance

	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.exclude = [self]
	query.collision_mask = collision_mask

	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty()



func take_damage(amount: int) -> void:
	health = clamp(health - amount, 0, max_health)
	print(health , " enemy")
	damaged.play()
	health_changed.emit(health, max_health)
	if health <= 30:
		$RigidBody3D/CollisionShape3D/Sprite3D.texture = load("res://assets/npcs/eggHit1.png")
	if health <= 20:
		$RigidBody3D/CollisionShape3D/Sprite3D.texture = load("res://assets/npcs/eggHit2.png")
	if health <= 10:
		$RigidBody3D/CollisionShape3D/Sprite3D.texture = load("res://assets/npcs/eggHit3.png")
	if health <= 0:
		fall()
		
		
func fall() -> void:
	follow = false
	$RigidBody3D/CollisionShape3D/Sprite3D.billboard = false
	$RigidBody3D/CollisionShape3D.rotation_degrees.x = 90
	$RigidBody3D/CollisionShape3D.rotation_degrees.y = 0
	$RigidBody3D/CollisionShape3D.rotation_degrees.z = 0
	$RigidBody3D/CollisionShape3D.scale.z = 0.3
	$RigidBody3D/CollisionShape3D/Sprite3D.texture = load("res://assets/npcs/cracked.png")


func _on_area_3d_area_entered(area: Area3D) -> void:
	var target = area.get_parent()
	
	if target.is_in_group("player"):
		take_damage(10)
