extends CharacterBody3D

@onready var navAg = $NavigationAgent3D
@export var movement_speed = 5.14
@onready var dTime = $deathTimer 

var follow = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		var player_position = get_node("../player").position
		navAg.set_target_position(player_position)

func _physics_process(delta: float) -> void:
	#print($RigidBody3D/CollisionShape3D.global_rotation.z)
	if abs($RigidBody3D/CollisionShape3D.global_rotation.z) > 1.4:
		follow = false
		$RigidBody3D/CollisionShape3D/Sprite3D.billboard = false
		$RigidBody3D/CollisionShape3D.rotation_degrees.x = 0
		$RigidBody3D/CollisionShape3D.rotation_degrees.y = 0
		$RigidBody3D/CollisionShape3D.rotation_degrees.z = 0
		$RigidBody3D/CollisionShape3D.scale.z = 0.3

		
	if follow:
		var player_position = get_node("../player").position
		var distance_from_player = position - player_position
		distance_from_player = abs(distance_from_player)
		if (min(distance_from_player.x, distance_from_player.z) > 0.4):
			navAg.set_target_position(player_position)
		else:
			var rand_pos := Vector3.ZERO
			rand_pos.x = randf() * distance_from_player.x 
			rand_pos.z = randf() * distance_from_player.z 
			navAg.set_target_position(rand_pos)

		var destination = navAg.get_next_path_position()
		var local_destination = destination - global_position
		var direction = local_destination.normalized()
		velocity = direction * movement_speed
		move_and_slide()
		
