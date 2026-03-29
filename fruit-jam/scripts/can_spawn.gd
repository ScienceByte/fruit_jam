extends Area3D

@onready var trigger_spawn: Area3D = $"."
@onready var spawn: Area3D = $Area3D
@onready var spawn_shape: CollisionShape3D = $Area3D/spawn

@export var can_enemy_scene: PackedScene = preload("res://scenes/can_enemy.tscn")
@export var total_spawn_count: int = 4
@export var spawn_interval: float = 0.6
@export var spawn_height_offset: float = 0.25

var has_triggered := false
var spawned_count := 0
var spawn_timer: Timer
var scene_default_enemy_scale: Vector3 = Vector3.ONE

func _ready() -> void:
	randomize()
	cache_scene_default_enemy_scale()

	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	if not trigger_spawn.body_entered.is_connected(_on_trigger_body_entered):
		trigger_spawn.body_entered.connect(_on_trigger_body_entered)
	if not trigger_spawn.area_entered.is_connected(_on_trigger_area_entered):
		trigger_spawn.area_entered.connect(_on_trigger_area_entered)


func start_spawn_wave() -> void:
	if has_triggered:
		return

	has_triggered = true
	spawn_timer.start()
	spawn_one_can_enemy()


func spawn_one_can_enemy() -> void:
	if can_enemy_scene == null:
		stop_spawning()
		return
	if spawned_count >= total_spawn_count:
		stop_spawning()
		return

	var can_enemy := can_enemy_scene.instantiate()
	if not (can_enemy is Node3D):
		return

	var enemy_3d := can_enemy as Node3D
	get_tree().current_scene.add_child(enemy_3d)
	enemy_3d.global_position = get_random_spawn_position()
	enemy_3d.scale = scene_default_enemy_scale

	spawned_count += 1
	if spawned_count >= total_spawn_count:
		stop_spawning()


func get_random_spawn_position() -> Vector3:
	if spawn_shape != null and spawn_shape.shape is BoxShape3D:
		var box := spawn_shape.shape as BoxShape3D
		var extents := box.size * 0.5
		var local_position := Vector3(
			randf_range(-extents.x, extents.x),
			spawn_height_offset,
			randf_range(-extents.z, extents.z)
		)
		return spawn_shape.global_transform * local_position

	return spawn.global_position + Vector3(0.0, spawn_height_offset, 0.0)


func stop_spawning() -> void:
	if spawn_timer != null and not spawn_timer.is_stopped():
		spawn_timer.stop()


func _on_spawn_timer_timeout() -> void:
	spawn_one_can_enemy()


func _on_trigger_body_entered(body: Node3D) -> void:
	if body != null and body.is_in_group("player"):
		start_spawn_wave()


func _on_trigger_area_entered(area: Area3D) -> void:
	var target := area.get_parent()
	if target != null and target.is_in_group("player"):
		start_spawn_wave()


func cache_scene_default_enemy_scale() -> void:
	if can_enemy_scene == null:
		scene_default_enemy_scale = Vector3.ONE
		return

	var probe := can_enemy_scene.instantiate()
	if probe is Node3D:
		scene_default_enemy_scale = (probe as Node3D).scale
