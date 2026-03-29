extends Node3D

@export_file("*.tscn") var end_cutscene_scene_path: String = "res://scenes/ending.tscn"
@export var enemy_group_name: StringName = &"enemy"
@export var no_enemy_clear_delay: float = 1.0
@export var use_test_timer: bool = true
@export var test_timer_seconds: float = 300

var has_seen_any_enemy := false
var win_triggered := false
var no_enemy_elapsed := 0.0
var test_elapsed := 0.0

func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if win_triggered:
		return
		
	if use_test_timer:
		test_elapsed += delta
		if test_elapsed >= test_timer_seconds:
			go_to_end_cutscene()

	var enemy_count := get_tree().get_nodes_in_group(enemy_group_name).size()
	if enemy_count > 0:
		has_seen_any_enemy = true
		no_enemy_elapsed = 0.0
		return

	if not has_seen_any_enemy:
		return

	no_enemy_elapsed += delta
	if no_enemy_elapsed >= no_enemy_clear_delay:
		go_to_end_cutscene()


func go_to_end_cutscene() -> void:
	if win_triggered:
		return
	win_triggered = true

	if ResourceLoader.exists(end_cutscene_scene_path):
		get_tree().change_scene_to_file(end_cutscene_scene_path)
		return

	push_warning("End cutscene scene not found at: " + end_cutscene_scene_path)
