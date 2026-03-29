extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/HealthBar
@onready var stamina_bar: ProgressBar = $Control/StaminaBar
@onready var player: Player = $".."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health_bar.max_value = player.max_health
	health_bar.value = player.health

	stamina_bar.min_value = 0
	stamina_bar.max_value = player.dash_cooldown_ms
	stamina_bar.value = player.dash_cooldown_ms  # full at start, meaning dash is ready

func _process(_delta: float) -> void:
	update_stamina_bar()

func update_stamina_bar() -> void:
	var now := Time.get_ticks_msec()
	var elapsed_since_dash :int = now - player.last_dash_time

	# empty right after dash, then fills back up until ready
	stamina_bar.value = clamp(elapsed_since_dash, 0, player.dash_cooldown_ms)
