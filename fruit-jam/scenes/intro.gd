extends Node3D

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("intro")   # Start your intro animation

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "intro":
		get_tree().change_scene_to_file("res://scenes/main.tscn")
