extends ProgressBar

@export var team: String = "P1"
@export var max_ult_charge: float = 100.0
@export var fill_per_second: float = 10.0

var current_charge: float = 0.0
var is_paused: bool = false
var is_ready_emitted: bool = false # 🟢 ป้องกันการยิง Signal ซ้ำซ้อน

signal ult_ready(team_name: String)

func _ready() -> void:
	max_value = max_ult_charge
	value = 0.0

func _process(delta: float) -> void:
	if is_paused:
		return
		
	if current_charge < max_ult_charge:
		add_charge(fill_per_second * delta)

func add_charge(amount: float) -> void:
	if current_charge >= max_ult_charge or is_paused:
		return
		
	current_charge = clampf(current_charge + amount, 0.0, max_ult_charge)
	value = current_charge
	
	if current_charge >= max_ult_charge and not is_ready_emitted:
		is_ready_emitted = true
		print("🔋 เกจ Ult ของ ", team, " เต็มแล้ว! กำลังส่ง Signal...")
		ult_ready.emit(team)

func consume_ult() -> void:
	current_charge = 0.0
	value = 0.0
	is_ready_emitted = false

func set_paused(paused: bool) -> void:
	is_paused = paused
