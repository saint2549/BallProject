extends Node2D

@onready var p1_hp_label: Label = $P1HP
@onready var p2_hp_label: Label = $P2HP
@onready var winner_label: Label = $WinnerLabel

# 🟢 [เพิ่มใหม่] อ้างอิงถึง HFlowContainer ของ Minion ทั้ง 2 ฝั่ง
@onready var p1_minion_container: HFlowContainer = $P1MinionContainer
@onready var p2_minion_container: HFlowContainer = $P2MinionContainer

var p1_ref: Node2D = null
var p2_ref: Node2D = null

func _ready() -> void:
	winner_label.visible = false
	
	if get_tree():
		get_tree().paused = false
	
	winner_label.process_mode = Node.PROCESS_MODE_ALWAYS
	if has_node("ReturnButton"):
		$ReturnButton.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# ตั้งค่าระยะห่างช่องว่างให้ Container ดูเป็นระเบียบ
	setup_container_spacing(p1_minion_container)
	setup_container_spacing(p2_minion_container)
	
	spawn_players()

func setup_container_spacing(container: HFlowContainer) -> void:
	if is_instance_valid(container):
		container.add_theme_constant_override("h_separation", 20)
		container.add_theme_constant_override("v_separation", 5)

func spawn_players() -> void:
	var p1_id = Global.p1_selected_character if Global.p1_selected_character != "" else "Char1"
	var p2_id = Global.p2_selected_character if Global.p2_selected_character != "" else "Char2"
	
	var p1_info = Global.character_data[p1_id]
	var p2_info = Global.character_data[p2_id]
	
	# 1. Instantiate ตัวละครทั้งคู่ขึ้นมาก่อน
	var p1 = load(p1_info["scene"]).instantiate()
	p1.team = "P1"
	p1.position = Vector2(200, 300)
	
	var p2 = load(p2_info["scene"]).instantiate()
	p2.team = "P2"
	p2.position = Vector2(800, 300)
	
	# 2. แปะ P1 และ P2 เข้า Scene หลักให้เรียบร้อยก่อน 🟢
	add_child(p1)
	add_child(p2)
	
	p1_ref = p1
	p2_ref = p2
	
	setup_player_hp_ui(p1, p1_hp_label)
	setup_player_hp_ui(p2, p2_hp_label)

	# 3. สั่งเสก Minion หลังจาก P1 และ P2 อยู่ใน Scene หลักเรียบร้อยแล้ว 🟢
	if p1.has_method("spawn_minion_at_random_position"):
		p1.spawn_minion_at_random_position()

	if p2.has_method("spawn_minion_at_random_position"):
		p2.spawn_minion_at_random_position()

# ฟังก์ชันจัดการ HP ตัวละครหลัก (P1/P2)
func setup_player_hp_ui(unit: Node2D, label: Label) -> void:
	if not is_instance_valid(unit) or not is_instance_valid(label):
		return
		
	var unit_name = unit.character_name if "character_name" in unit else unit.name
	var current_hp = unit.hp if "hp" in unit else 0
	
	label.text = unit_name + " HP: " + str(current_hp)
	
	if unit.has_signal("hp_changed"):
		unit.hp_changed.connect(func(new_hp: int):
			if is_instance_valid(label):
				label.text = unit_name + " HP: " + str(new_hp)
			check_game_over()
		)

# 🟢 [เพิ่มใหม่] ฟังก์ชันสำหรับให้ Minion/ตัวละครที่ถูกชุบชีวิตมาลงทะเบียน HP UI ใน Container
func register_unit_hp_ui(unit: Node2D) -> void:
	if not is_instance_valid(unit):
		return
		
	# เลือก Container ตามทีมของ Minion
	var target_container: HFlowContainer = null
	if "team" in unit:
		if unit.team == "P1":
			target_container = p1_minion_container
		elif unit.team == "P2":
			target_container = p2_minion_container
			
	if not is_instance_valid(target_container):
		return

	var hp_label = Label.new()
	var unit_name = unit.character_name if "character_name" in unit else unit.name
	var current_hp = unit.hp if "hp" in unit else 0
	
	hp_label.text = unit_name + " HP: " + str(current_hp)
	hp_label.add_theme_font_size_override("font_size", 20) # ปรับขนาดฟอนต์มินเนี่ยนตามต้องการ
	
	target_container.add_child(hp_label)
	
	# อัปเดต HP เมื่อโดนโจมตี
	if unit.has_signal("hp_changed"):
		unit.hp_changed.connect(func(new_hp: int):
			if is_instance_valid(hp_label):
				hp_label.text = unit_name + " HP: " + str(new_hp)
			check_game_over()
		)
	
	# ลบ Label ทิ้งเมื่อ Minion ตัวนี้ตาย
	unit.tree_exited.connect(func():
		if is_instance_valid(hp_label):
			hp_label.queue_free()
		check_game_over()
	)

func check_game_over() -> void:
	var p1_alive = is_instance_valid(p1_ref) and "hp" in p1_ref and p1_ref.hp > 0
	var p2_alive = is_instance_valid(p2_ref) and "hp" in p2_ref and p2_ref.hp > 0
	
	if p1_alive and not p2_alive:
		end_game("P1 WINS!")
	elif p2_alive and not p1_alive:
		end_game("P2 WINS!")
	elif not p1_alive and not p2_alive:
		end_game("DRAW!")

func end_game(winner_text: String) -> void:
	winner_label.text = winner_text
	winner_label.visible = true
	if get_tree():
		get_tree().paused = true

func _on_return_pressed() -> void:
	if get_tree():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://Scene/character_select.tscn")
