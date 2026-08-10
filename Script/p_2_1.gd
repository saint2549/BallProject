extends CharacterBody2D

@export var character_name: String = "Paupau"
signal hp_changed(new_hp: int)
signal minion_freed

@export var speed: int = 600
@export var hp: int = 50
@export var team: String = "P2"
@export var skillcharge: float = 5.0
@export var skillduration: float = 5.0

var skilltimer: float = 0.0
var skillendtimer: float = 0.0
var is_skill_active: bool = false

var damage_cooldown: float = 0.0
var move_direction: Vector2 = Vector2.ZERO # 🌟 เพิ่มตัวแปรเก็บทิศทาง

func _ready() -> void:
	var random_x = randf_range(-1.0, 1.0)
	var random_y = randf_range(-1.0, 1.0)
	move_direction = Vector2(random_x, random_y).normalized() # เก็บเฉพาะทิศทาง

func _physics_process(delta: float) -> void:
	# ⏳ ระบบสลับตัวนับเวลา
	if not is_skill_active:
		skilltimer += delta
	else:
		skillendtimer += delta

	# 🚀 เช็กเงื่อนไขการใช้สกิล / หมดเวลาสกิล
	if skilltimer >= skillcharge:
		Skill()
		is_skill_active = true
		skilltimer = 0.0 # รีเซ็ตคูลดาวน์เป็น 0
		
	if skillendtimer >= skillduration:
		SkillEnd()
		is_skill_active = false
		skillendtimer = 0.0 # 🌟 แก้ไข: รีเซ็ตรักษาเวลาสกิลเป็น 0

	# 🛡️ Cooldown การรับความเสียหาย
	if damage_cooldown > 0:
		damage_cooldown -= delta

	# 🏃 คำนวณความเร็วตาม speed ปัจจุบัน (ช่วยให้ตอนใช้สกิลตัวละครจะวิ่งไวขึ้นจริง)
	velocity = move_direction * speed
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var collider = collision.get_collider()
		var normal = collision.get_normal()
		
		# สะท้อนทิศทางเมื่อชนกำแพง
		move_direction = move_direction.bounce(normal)
		global_position += normal * 3.0
		
		if collider.has_method("take_damage"):
			if "team" in collider and collider.team != self.team:
				collider.take_damage(10)
				take_damage(10)

func take_damage(amount: int) -> void:
	if damage_cooldown > 0:
		return 

	if hp > 0:
		hp -= amount
		hp = clampi(hp, 0, 50)
		hp_changed.emit(hp)
		damage_cooldown = 0.2
		
		if hp <= 0:
			minion_freed.emit()
			queue_free()

func Skill():
	speed = 2000

func SkillEnd():
	speed = 600
