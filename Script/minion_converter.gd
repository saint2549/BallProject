class_name MinionConverter
extends Node

# 🧟‍♂️ ฟังก์ชันหลักที่เรียกใช้จากภายนอก
static func spawn_revived_minion(dead_character: Node2D, new_team: String = "P1") -> void:
	if not is_instance_valid(dead_character):
		return

	if dead_character.has_meta("is_converting"):
		return
	dead_character.set_meta("is_converting", true)

	# 🟢 สั่งประมวลผลการแปลงร่างแบบ Deferred เพื่อเลี่ยง Physics Flush Crash
	var converter_instance = MinionConverter.new()
	converter_instance._do_spawn_revived_minion.call_deferred(dead_character, new_team)

# 🛠️ ฟังก์ชันประมวลผลจริง (จะทำงานหลังจบจังหวะ Physics Flush)
func _do_spawn_revived_minion(dead_character: Node2D, new_team: String) -> void:
	if not is_instance_valid(dead_character):
		queue_free()
		return

	# 1. ดึง Scene (.tscn) ของตัวละครที่เพิ่งตาย
	var scene_path = dead_character.scene_file_path
	if scene_path.is_empty():
		queue_free()
		return
		
	var character_scene = load(scene_path) as PackedScene
	if not character_scene:
		queue_free()
		return
		
	# 2. เสก (Instantiate) ตัวละครใหม่ขึ้นมา
	var new_minion = character_scene.instantiate() as Node2D
	
	# 🛑 บล็อกไม่ให้ร่างชุบชีวิตสั่งเสก Minion ซ้ำ
	if "is_revived" in new_minion:
		new_minion.is_revived = true
	if "has_spawned_minion" in new_minion:
		new_minion.has_spawned_minion = true
	
	# 3. ย้ายตำแหน่ง
	new_minion.global_position = dead_character.global_position
	
	# 4. เปลี่ยนทีม
	if "team" in new_minion:
		new_minion.team = new_team

	# 5. ตั้งชื่อ Shadow
	if "character_name" in new_minion:
		new_minion.character_name = "Shadow"

	# 6. ค่า HP และ Damage
	if "hp" in new_minion:
		new_minion.hp = int(new_minion.hp)

	if "damage" in new_minion:
		new_minion.damage = int(new_minion.damage)

	# 7. ย้อมสีรูปภาพให้เป็นสีม่วง
	var sprite = new_minion.get_node_or_null("Sprite2D")
	if not sprite:
		sprite = new_minion.get_node_or_null("AnimatedSprite2D")
		
	if sprite:
		sprite.modulate = Color(0.65, 0.25, 0.95)
	else:
		new_minion.modulate = Color(0.65, 0.25, 0.95)

	# 8. แปะตัวละครใหม่ลงใน Scene หลัก และลงทะเบียน UI
	var main_scene = dead_character.get_tree().current_scene
	if is_instance_valid(main_scene):
		main_scene.add_child(new_minion)
		
		if main_scene.has_method("register_unit_hp_ui"):
			main_scene.register_unit_hp_ui(new_minion)

	# 9. ลบตัวละครเก่าทิ้งอย่างปลอดภัย
	dead_character.queue_free()
	print("🧟‍♂️ เสก Shadow สีม่วงเรียบร้อยแล้ว!")
	
	# ลบตัวเอง (Node ตัวช่วยสร้าง) ออกจาก Memory
	queue_free()
