extends CharacterBody2D

@export var character_name: String = "zombie"
@export var team: String = "P1"
signal hp_changed(new_hp: int)

@export var speed: int = 300  # ความเร็วของมินเนี่ยน (ปรับได้ตามชอบ)
@export var hp: int = 20       # เลือดมินเนี่ยน

var damage_cooldown: float = 0.0
var move_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	# สุ่มทิศทางการเคลื่อนที่ตอนเริ่มเกิด
	var random_x = randf_range(-1.0, 1.0)
	var random_y = randf_range(-1.0, 1.0)
	move_direction = Vector2(random_x, random_y).normalized()

func _physics_process(delta: float) -> void:
	if damage_cooldown > 0:
		damage_cooldown -= delta

	velocity = move_direction * speed
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var collider = collision.get_collider()
		var normal = collision.get_normal()
		
		# เด้งกลับเมื่อชนสิ่งกีดขวางหรือยูนิตอื่น
		move_direction = move_direction.bounce(normal)
		global_position += normal * 3.0
		
		# ชนศัตรูคนละทีมแล้วทำความเสียหายใส่กัน
		if is_instance_valid(collider) and collider.has_method("take_damage"):
			if !("team" in collider) or collider.team != self.team:
				collider.take_damage(10)
				take_damage(10)

func take_damage(amount: int) -> void:
	if damage_cooldown > 0:
		return

	if hp > 0:
		hp = clampi(hp - amount, 0, 20)
		hp_changed.emit(hp) # ส่ง Signal อัปเดต HP ใน UI
		
		damage_cooldown = 0.2
		if hp <= 0:
			queue_free() # เมื่อตายให้ลบตัวเองออกจาก Scene ทันที
