extends Node3D

@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var rigidbody = $RigidBody3D

func _physics_process(delta: float) -> void:
	rigidbody.linear_velocity.y += rigidbody.get_gravity().y * delta
