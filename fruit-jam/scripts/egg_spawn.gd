extends Area3D

@onready var player: Node3D = get_tree().get_first_node_in_group("player")

@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var milk_enemy_scene: PackedScene = preload("res://scenes/milk_enemy.tscn")
@export var total_spawn_limit: int = 8
@export var spawn_interval: float = 0.8
@export var spawn_radius_min: float = 0.5
@export var spawn_radius_max: float = 1.8
@export var spawn_height_offset: float = 0.3
@export var milk_spawn_count: int = 2
@export var milk_spawn_radius: float = 4.0
@export var milk_spawn_height_offset: float = 0.3
@export var milk_attack_stagger_seconds: float = 1.2


var spawned_count := 0
var defeated_count := 0
var milk_wave_spawned := false
var spawn_timer: Timer
var defeated_egg_ids: Dictionary = {}


func _ready() -> void:
	randomize()

	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func spawn_enemy_around_fridge() -> void:
	if enemy_scene == null:
		return
	if spawned_count >= total_spawn_limit:
		stop_spawning()
		return

	var enemy := enemy_scene.instantiate()
	if not (enemy is Node3D):
		return

	var angle := randf_range(0.0, TAU)
	var radius := randf_range(spawn_radius_min, spawn_radius_max)
	var spawn_offset := Vector3(cos(angle) * radius, spawn_height_offset, sin(angle) * radius)

	(enemy as Node3D).global_position = global_position + spawn_offset
	get_tree().current_scene.add_child(enemy)
	connect_egg_death_tracking(enemy)

	spawned_count += 1
	if spawned_count >= total_spawn_limit:
		stop_spawning()


func connect_egg_death_tracking(enemy: Node) -> void:
	if enemy == null:
		return
	if enemy.has_signal("health_changed"):
		enemy.health_changed.connect(_on_egg_health_changed.bind(enemy))


func start_spawning() -> void:
	if spawned_count >= total_spawn_limit:
		return
	if spawn_timer.is_stopped():
		spawn_timer.start()
		spawn_enemy_around_fridge()


func stop_spawning() -> void:
	if not spawn_timer.is_stopped():
		spawn_timer.stop()


func _on_spawn_timer_timeout() -> void:
	spawn_enemy_around_fridge()


func _on_egg_health_changed(new_health: int, _max_health: int, enemy: Node) -> void:
	if new_health > 0:
		return

	var enemy_id := enemy.get_instance_id()
	if defeated_egg_ids.has(enemy_id):
		return

	defeated_egg_ids[enemy_id] = true
	defeated_count += 1
	if defeated_count >= total_spawn_limit and not milk_wave_spawned:
		spawn_milk_wave()


func spawn_milk_wave() -> void:
	if milk_enemy_scene == null:
		return
	milk_wave_spawned = true

	var count := maxi(milk_spawn_count, 0)
	if count == 0:
		return

	for i in range(count):
		var milk_enemy := milk_enemy_scene.instantiate()
		if not (milk_enemy is Node3D):
			continue

		var angle := TAU * float(i) / float(count)
		var offset := Vector3(cos(angle) * milk_spawn_radius, milk_spawn_height_offset, sin(angle) * milk_spawn_radius)
		(milk_enemy as Node3D).global_position = global_position + offset
		get_tree().current_scene.add_child(milk_enemy)

		if milk_enemy.has_method("set_spawn_attack_delay"):
			milk_enemy.call("set_spawn_attack_delay", milk_attack_stagger_seconds * float(i))


func _on_body_entered(body: Node3D) -> void:
	if body != null and body.is_in_group("player"):
		start_spawning()


func _on_area_entered(area: Area3D) -> void:
	var target := area.get_parent()
	if target != null and target.is_in_group("player"):
		start_spawning()
