extends CharacterBody2D

@export var character_name: String = "Faan"
@export var team: String = "P1"
signal hp_changed(new_hp: int)

@export var speed: int = 400
@export var hp: int = 100

# 🌟 โหนด AnimatedSprite2D ของ Tablet
@onready var tablet: AnimatedSprite2D = $Tablet

# 🌟 โหลด Scene ของ P3_1 (Zombie)
@export var minion_scene: PackedScene = preload("res://Scene/p_3_1.tscn")

var skilltimer: float = 0.0
var skillcharge: int = 0

var damage_cooldown: float = 0.0
var move_direction: Vector2 = Vector2.ZERO

# 🛑 ตัวแปรสำหรับควบคุมการปิดสกิล
var is_silenced: bool = false
var is_ult_active: bool = false

func _ready() -> void:
	var random_x = randf_range(-1.0, 1.0)
	var random_y = randf_range(-1.0, 1.0)
	move_direction = Vector2(random_x, random_y).normalized()

func _physics_process(delta: float) -> void:
	# 🛑 สกิลจะไม่ทำงานและไม่นับเวลา ถ้าติด Silence หรืออยู่ในช่วงใช้ Ult
	if not is_silenced and not is_ult_active:
		skilltimer += delta
		if skilltimer >= 1.0:
			skilltimer -= 1.0
			skillcharge += 1
			
			# เช็กว่าครบ 5 วินาทีหรือยัง?
			if skillcharge >= 5:
				skillcharge = 0
				Skill(3) # 🟢 เสก 3 ตัว + เร่งความเร็ว Animation 2 วินาที
			else:
				Skill(1) # 🟢 เสก 1 ตัวปกติ (Animation ความเร็วเดิม)

	if damage_cooldown > 0:
		damage_cooldown -= delta

	velocity = move_direction * speed
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var collider = collision.get_collider()
		var normal = collision.get_normal()
		
		move_direction = move_direction.bounce(normal)
		global_position += normal * 3.0
		
		if is_instance_valid(collider) and collider.has_method("take_damage"):
			if !("team" in collider) or collider.team != self.team:
				collider.take_damage(10)
				take_damage(10)

# 🟢 ฟังก์ชันสกิลเสก Zombie
func Skill(count: int) -> void:
	if not minion_scene:
		return
		
	# ⚡ ถ้าเสก 3 ตัว (ครบ 5 วินาที) ให้เร่งความเร็ว Tablet 2 วินาที
	if count == 3 and is_instance_valid(tablet):
		boost_tablet_speed()

	var main_scene = get_tree().current_scene
	
	for i in range(count):
		var minion = minion_scene.instantiate()
		minion.team = self.team
		
		var offset = Vector2(randf_range(-120, 120), randf_range(-120, 120))
		minion.global_position = self.global_position + offset
		
		main_scene.add_child(minion)
		
		if main_scene.has_method("register_unit_hp_ui"):
			main_scene.register_unit_hp_ui(minion)

# ⚡ ฟังก์ชันเร่งความเร็ว Animation ของ Tablet ชั่วคราว 2 วินาที
func boost_tablet_speed() -> void:
	tablet.speed_scale = 2.5 # ปรับความเร็วตามต้องการ (2.5 เท่า)
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(tablet):
		tablet.speed_scale = 1.0 # คืนค่าความเร็วปกติ
		
func take_damage(amount: int) -> void:
	if damage_cooldown > 0:
		return

	if hp > 0:
		hp = clampi(hp - amount, 0, 100)
		hp_changed.emit(hp)
		
		damage_cooldown = 0.2
		if hp <= 0:
			visible = false
