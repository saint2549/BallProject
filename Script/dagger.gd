extends Area2D

@export var normal_damage: int = 5     # ⚔️ ความเสียหายปกติ
@export var empowered_damage: int = 15 # 💥 ความเสียหายตอนเปิดสกิล
@export var team: String = "P1"

var is_empowered: bool = false # สถานะเปิดใช้สกิล

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# 🛑 ไม่ทำงานถ้าชนกับเจ้าของ (P1) หรือทีมเดียวกัน
	if body == get_parent() or ("team" in body and body.team == self.team):
		return

	# 🧱 1. ชนกำแพง
	if body is StaticBody2D or body is TileMap:
		return

	# ⚔️ 2. ชนตัวละครฝั่งตรงข้าม
	if body is CharacterBody2D:
		# 🔄 สลับทิศการหมุนกริช
		var p1_owner = get_parent()
		if p1_owner and p1_owner.has_method("toggle_spin_direction"):
			p1_owner.toggle_spin_direction()

		# คำนวณทิศทางเด้งสะท้อน
		var bounce_dir = (body.global_position - global_position).normalized()
		if bounce_dir == Vector2.ZERO:
			bounce_dir = Vector2.UP
			
		if "move_direction" in body:
			body.move_direction = body.move_direction.bounce(bounce_dir)
		
		body.global_position += bounce_dir * 5.0

		# 💥 ทำความเสียหาย (เลือกระหว่างปกติ หรือ Empowered)
		if body.has_method("take_damage"):
			# เช็กก่อนว่าศัตรูตายไปแล้วหรือยัง ป้องกันการชนซ้ำ
			if "hp" in body and body.hp <= 0:
				return

			var current_damage = empowered_damage if is_empowered else normal_damage
			body.take_damage(current_damage)
				
			# 🧟‍♂️ ถ้าฆ่าศัตรูตาย ให้เสกสมุนสีม่วง
			if "hp" in body and body.hp <= 0:
				# 🔒 ปิดการชนของศัตรูตัวนี้ทันที เพื่อไม่ให้กริชชนซ้ำในเฟรมถัดไป
				if body.has_node("CollisionShape2D"):
					body.get_node("CollisionShape2D").set_deferred("disabled", true)
				
				MinionConverter.spawn_revived_minion(body, self.team)
