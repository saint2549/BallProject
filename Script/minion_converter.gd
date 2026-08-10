class_name MinionConverter
extends Node

# 🧟‍♂️ ฟังก์ชันเสกตัวละครใหม่ขึ้นมาแทนที่ตัวที่เพิ่งตาย
static func spawn_revived_minion(dead_character: Node2D, new_team: String = "P1") -> void:
	if not is_instance_valid(dead_character):
		return

	# 🛑 ป้องกันการเสกซ้ำถ้าตัวนี้กำลังอยู่ในกระบวนการแปลงร่าง
	if dead_character.has_meta("is_converting"):
		return
	dead_character.set_meta("is_converting", true)

	# 1. ดึง Scene (.tscn) ของตัวละครที่เพิ่งตาย
	var scene_path = dead_character.scene_file_path
	if scene_path.is_empty():
		return
		
	var character_scene = load(scene_path) as PackedScene
	if not character_scene:
		return
		
	# 2. เสก (Instantiate) ตัวละครใหม่ขึ้นมา
	var new_minion = character_scene.instantiate() as Node2D
	
	# 🛑 2.1 บล็อกไม่ให้ร่างชุบชีวิตสั่งเสก Minion ของตัวเองซ้ำ
	if "is_revived" in new_minion:
		new_minion.is_revived = true
	if "has_spawned_minion" in new_minion:
		new_minion.has_spawned_minion = true
	
	# 3. ย้ายตำแหน่งไปตรงจุดที่ตัวเดิมเพิ่งตาย
	new_minion.global_position = dead_character.global_position
	
	# 4. เปลี่ยนทีม
	if "team" in new_minion:
		new_minion.team = new_team

	# 5. ตั้งชื่อเรียกสำหรับแสดงผลใน UI เป็น Shadow 🟢
	if "character_name" in new_minion:
		new_minion.character_name = "Shadow"

	# 6. ปรับ HP เหลือ 25 สำหรับ Minion ชุบชีวิต
	if "hp" in new_minion:
		new_minion.hp = int(new_minion.hp)

	# 7. ลดพลังโจมตีลงครึ่งหนึ่ง (1/2)
	if "damage" in new_minion:
		new_minion.damage = int(new_minion.damage)

	# 8. ย้อมสีรูปภาพให้เป็นสีม่วง
	var sprite = new_minion.get_node_or_null("Sprite2D")
	if not sprite:
		sprite = new_minion.get_node_or_null("AnimatedSprite2D")
		
	if sprite:
		sprite.modulate = Color(0.65, 0.25, 0.95)
	else:
		new_minion.modulate = Color(0.65, 0.25, 0.95)

	# 9. แปะตัวละครใหม่ลงใน Scene หลัก และลงทะเบียน HP UI 🟢
	var main_scene = dead_character.get_tree().current_scene
	if is_instance_valid(main_scene):
		main_scene.add_child(new_minion)
		
		# ส่งไปลงทะเบียน UI เพื่อให้โชว์ใน HFlowContainer ของทีมใหม่
		if main_scene.has_method("register_unit_hp_ui"):
			main_scene.register_unit_hp_ui(new_minion)

	# 10. ลบตัวละครเก่าทิ้ง
	dead_character.queue_free()
	
	print("🧟‍♂️ เสก Shadow สีม่วงขึ้นมาแทนที่ตัวเดิมเรียบร้อย!")
