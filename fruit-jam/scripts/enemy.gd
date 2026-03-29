extends CharacterBody3D

@onready var navAg = $NavigationAgent3D
@export var movement_speed = 10
@onready var dTime = $deathTimer 

var back_off_time = 0
var back_off

@export var max_health: int = 40
var health: int = max_health
signal health_changed(new_health: int, max_health: int)

@onready var player = get_node("../player")

var follow = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		var player_position = get_node("../player").position
		navAg.set_target_position(player_position)

func _physics_process(delta: float) -> void:
	#print($RigidBody3D/CollisionShape3D.global_rotation.z)
	if abs($RigidBody3D/CollisionShape3D.global_rotation.z) > 1.4:
		fall()

	
	if follow:
		var player_position = player.position
		var distance_from_player = position - player_position
		distance_from_player = abs(distance_from_player)

		if (back_off_time <= 0) and (pow(distance_from_player.x, 2) + pow(distance_from_player.z, 2) + pow(distance_from_player.y, 2) < 1.5):
			back_off = true
			back_off_time = 100
			player_position.x += -player.global_transform.basis.z.x * randi_range(6, 8)
			player_position.z += -player.global_transform.basis.z.z * randi_range(6, 8)
			navAg.set_target_position(player_position)
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
		if abs(destination - position) > Vector3(0.1, 0.1, 0.1):
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
	$RigidBody3D/CollisionShape3D.rotation_degrees.x = 0
	$RigidBody3D/CollisionShape3D.rotation_degrees.y = 0
	$RigidBody3D/CollisionShape3D.rotation_degrees.z = 0
	$RigidBody3D/CollisionShape3D.scale.z = 0.3
	$RigidBody3D/CollisionShape3D/Sprite3D.texture = load("res://assets/npcs/cracked.png")
