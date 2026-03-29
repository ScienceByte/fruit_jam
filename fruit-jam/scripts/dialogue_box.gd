extends Control

@onready var dialogue_text: Label = $DialogueText

var sequence: Array = []
var current_index: int = 0
var is_active: bool = false

func _ready() -> void:
	visible = false
	print("DialogueBox path: ", get_path())

func play_sequence(lines: Array) -> void:
	sequence = lines
	current_index = 0
	is_active = true
	visible = true
	show_current_line()

func show_current_line() -> void:
	if current_index >= sequence.size():
		end_conversation()
		return
	var line: Dictionary = sequence[current_index]
	dialogue_text.text = "[%s]: %s" % [line.get("speaker", ""), line.get("text", "")]

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed("Interact") or \
	   (event is InputEventKey and event.pressed and event.keycode == KEY_F):
		advance()

func advance() -> void:
	var line: Dictionary = sequence[current_index]
	if line.has("action"):
		DialogueManager.emit_signal("action_triggered", line["action"])
	current_index += 1
	show_current_line()

func end_conversation() -> void:
	is_active = false
	visible = false
	sequence = []
	DialogueManager.emit_signal("dialogue_finished")
