extends Node
var dialogue_data: Dictionary = {}
signal dialogue_finished
signal action_triggered(action_name: String)
func _ready() -> void:
	print("DialogueBox connected")
	load_dialogue()
	
var dialogue_box_node = null

func load_dialogue() -> void:
	var file_path = "res://scripts/dialogue_data.json"
	if not FileAccess.file_exists(file_path):
		printerr("Dialogue file missing!")
		return
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		dialogue_data = json.data
		print("Dialogue loaded successfully.")
		print("Keys found: ", dialogue_data.keys())
	else:
		printerr("JSON Parse Error at line ", json.get_error_line(), ": ", json.get_error_message())

func start_conversation(dialogue_id: String) -> void:
	if not dialogue_data.has(dialogue_id):
		printerr("Dialogue ID not found: ", dialogue_id)
		return
	var dialogue_box = get_tree().root.find_child("DialogueBox", true, false)
	if dialogue_box == null:
		printerr("DialogueBox not found!")
		return
	dialogue_box.play_sequence(dialogue_data[dialogue_id])
