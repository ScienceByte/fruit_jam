extends Node

var dialogue_data: Dictionary = {}

func _ready() -> void:
	load_dialogue()

func load_dialogue() -> void:
	var file_path = "res://dialogue_data.json"
	if not FileAccess.file_exists(file_path):
		printerr("Dialogue file missing!")
		return
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	
	if error == OK:
		dialogue_data = json.data
		print("Dialogue loaded successfully.")
	else:
		printerr("JSON Parse Error at line ", json.get_error_line(), ": ", json.get_error_message())

func start_conversation(dialogue_id: String) -> void:
	if not dialogue_data.has(dialogue_id):
		printerr("Dialogue ID not found: ", dialogue_id)
		return
		
	var conversation_sequence = dialogue_data[dialogue_id]
	
	#get_node("/root/Main/UI_Canvas/DialogueBox").play_sequence(conversation_sequence)
	
	print("Starting dialogue: ", dialogue_id)
	print(conversation_sequence)
