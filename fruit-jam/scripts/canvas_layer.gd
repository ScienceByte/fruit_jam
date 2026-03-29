extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/HealthBar
@onready var stamina_bar: ProgressBar = $Control/StaminaBar
@onready var warning_label: Label = $WarningLabel
@onready var player: Player = $".."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	warning_label.visible = false
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	
	if not player.health_changed.is_connected(_on_player_health_changed):
		player.health_changed.connect(_on_player_health_changed)
	stamina_bar.min_value = 0
	stamina_bar.max_value = player.dash_cooldown
	
	stamina_bar.value = player.dash_cooldown 

func _process(_delta: float) -> void:
	update_stamina_bar()

func _on_player_health_changed(new_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = new_health

func update_stamina_bar() -> void:
	var now := Time.get_ticks_msec()
	var elapsed_since_dash :int = now - player.last_dash_time

	# empty right after dash, then fills back up until ready
	stamina_bar.value = clamp(elapsed_since_dash, 0, player.dash_cooldown)
