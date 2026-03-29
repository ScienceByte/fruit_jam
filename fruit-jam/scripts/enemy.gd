extends CharacterBody3D

@onready var navAg = $NavigationAgent3D
var movement_speed = 10
@onready var dTime = $deathTimer 

var back_off_time = 0
var back_off

@export var max_health: int = 40
var health: int = max_health
signal health_changed(new_health: int, max_health: int)

@onready var player = get_node("../../player")

var follow = true

@onready var area = $Area3D

func _physics_process(delta: float) -> void:
	if abs($RigidBody3D/CollisionShape3D.global_rotation.z) > 1.4:
		fall()	
	
	if follow:
		var player_position = player.position
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

		if (abs(destination.y - position.y) > 0.5) or (abs(destination.z - position.z) > 0.5):
			movement_speed = 10
			velocity = direction * movement_speed
			move_and_slide()
	#print(health)



func take_damage(amount: int) -> void:
	health = clamp(health - amount, 0, max_health)
	print(health , " enemy")
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
