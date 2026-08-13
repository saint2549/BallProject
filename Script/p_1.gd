extends CharacterBody2D

@onready var hand: AnimatedSprite2D = $Hand
@onready var dagger: Area2D = $Dagger
@export var character_name: String = "Team"
@export var team: String = "P1"
signal hp_changed(new_hp: int)

@export var speed: int = 400
@export var hp: int = 100

# 🌟 Dagger & Skill Settings
@export var dagger_scene: PackedScene = preload("res://Scene/dagger.tscn")
@export var normal_spin_speed: float = 2.0
@export var fast_spin_speed: float = 40.0
@export var orbit_radius: float = 120.0

@export var skillcharge: float = 3.0
@export var skillduration: float = 1.0

var current_spin_speed: float = 2.0
var spin_direction: float = 1.0
var angle: float = 0.0

var dagger_instances: Array[Area2D] = []

var skilltimer: float = 0.0
var skillendtimer: float = 0.0
var is_skill_active: bool = false

# 🌟 Ultimate Variables
var is_ult_active: bool = false
@export var bounce_count: int = 25
@export var damage_per_bounce: int = 3

var damage_cooldown: float = 0.0
var move_direction: Vector2 = Vector2.ZERO
var is_silenced: bool = false
var ult_bar_ref: Node = null



func _ready() -> void:
	current_spin_speed = normal_spin_speed
	var random_x = randf_range(-1.0, 1.0)
	var random_y = randf_range(-1.0, 1.0)
	move_direction = Vector2(random_x, random_y).normalized()
	
	spawn_daggers()
	call_deferred("_connect_ult_bar")

# 🔗 เชื่อมต่อกับ Ult Bar UI
func _connect_ult_bar() -> void:
	var main_scene = get_tree().current_scene
	if not main_scene:
		return
		
	var ult_bar_name = team + "_UltBar" # จะได้ "P1_UltBar"
	
	# ค้นหาโหนดแบบทั่วทั้ง Scene Tree (ไม่สนใจว่าจะซ่อนอยู่ในโหนดไหน)
	ult_bar_ref = main_scene.find_child(ult_bar_name, true, false)

	if ult_bar_ref:
		if ult_bar_ref.has_signal("ult_ready"):
			if not ult_bar_ref.ult_ready.is_connected(_on_ult_ready):
				ult_bar_ref.ult_ready.connect(_on_ult_ready)
				print("✅ ", team, " เชื่อมต่อกับ ", ult_bar_ref.name, " สำเร็จ!")
	else:
		print("❌ ", team, " หาโหนด ", ult_bar_name, " ไม่เจอ!")

func _on_ult_ready(ult_team: String) -> void:
	print("⚡ ได้รับ Signal ult_ready จากทีม: ", ult_team)
	
	if ult_team == self.team and not is_ult_active:
		# 🟢 สั่งล้างเกจจาก Reference ที่บันทึกไว้ได้ทันที 100%
		if is_instance_valid(ult_bar_ref) and ult_bar_ref.has_method("consume_ult"):
			ult_bar_ref.consume_ult()
			print("🔋 ล้างเกจ Ult เรียบร้อย!")
		else:
			print("⚠️ ไม่สามารถเรียก consume_ult() ได้ เนื่องจาก ult_bar_ref ไม่สมบูรณ์")

		activate_ultimate()

func activate_ultimate() -> void:
	if is_ult_active:
		return
	is_ult_active = true
	
	await P1Ult.execute(self, bounce_count, damage_per_bounce)
	
	is_ult_active = false

func spawn_daggers() -> void:
	if not dagger_scene:
		print("❌ ERROR: dagger_scene is NULL! Check P1's Inspector slot.")
		return

	print("🗡️ Spawning daggers...")
	dagger_instances.clear()
	
	for i in range(2):
		var dagger = dagger_scene.instantiate() as Area2D
		if not dagger:
			print("❌ ERROR: Failed to instantiate dagger!")
			continue
			
		if "team" in dagger:
			dagger.team = self.team
		
		# Put daggers above background visuals
		dagger.z_index = 10 
		
		dagger_instances.append(dagger)
		add_child(dagger)
		print("✅ Dagger ", i + 1, " added to scene tree.")
		
	_update_dagger_positions()

func toggle_spin_direction() -> void:
	spin_direction *= -1.0

func _update_dagger_positions() -> void:
	if dagger_instances.size() > 0 and is_instance_valid(dagger_instances[0]):
		var offset1 = Vector2(cos(angle), sin(angle)) * orbit_radius
		dagger_instances[0].position = offset1
		dagger_instances[0].rotation = angle

	if dagger_instances.size() > 1 and is_instance_valid(dagger_instances[1]):
		var opposite_angle = angle + PI
		var offset2 = Vector2(cos(opposite_angle), sin(opposite_angle)) * orbit_radius
		dagger_instances[1].position = offset2
		dagger_instances[1].rotation = opposite_angle

func _physics_process(delta: float) -> void:
	if is_ult_active:
		return
	if not is_silenced:
		if not is_skill_active:
			skilltimer += delta
			if skilltimer >= skillcharge:
				P1Skill.activate_spin_skill(self)
		else:
			skillendtimer += delta
			if skillendtimer >= skillduration:
				P1Skill.deactivate_spin_skill(self)

		angle += current_spin_speed * spin_direction * delta
		_update_dagger_positions()

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
					P1Skill.try_revive_enemy(self, collider)

func take_damage(amount: int) -> void:
	if damage_cooldown > 0:
		return 

	if hp > 0:
		hp = clampi(hp - amount, 0, 100)
		hp_changed.emit(hp)
		
		damage_cooldown = 0.2
		if hp <= 0:
			for dagger in dagger_instances:
				if is_instance_valid(dagger):
					dagger.queue_free()
			visible = false

func set_ult_visual_mode(active: bool) -> void:
	# 🗡️ ลูปสั่ง ซ่อน/แสดง และ ปิด/เปิด Collision ของกริชทุกเล่มใน dagger_instances
	for dagger_item in dagger_instances:
		if is_instance_valid(dagger_item):
			# ถ้า active เป็น true (ใช้ Ult) ให้ visible = false (ซ่อน)
			dagger_item.visible = !active
			
			# ปิด/เปิด Hitbox ของกริชชั่วคราว
			if dagger_item.has_node("CollisionShape2D"):
				dagger_item.get_node("CollisionShape2D").set_deferred("disabled", active)

	# ✋ แสดง/ซ่อน มือ Hand
	if is_instance_valid(hand):
		hand.visible = active

# 🔄 เปลี่ยน Frame ของ Hand ตามทิศทางที่ศัตรูพุ่งไป
func update_ult_sprite_direction(dir: Vector2) -> void:
	if not is_instance_valid(hand):
		return

	# หยุดอนิเมชันอัตโนมัติเพื่อล็อกเฟรม
	hand.stop()

	# คำนวณแกนที่มีแรงพุ่งมากกว่า (แกน X หรือ แกน Y)
	if abs(dir.x) > abs(dir.y):
		if dir.x < 0:
			hand.frame = 0 # ⬅️ ศัตรูพุ่งไปทาง "ซ้าย"  -> เล่น Frame 1
		else:
			hand.frame = 1 # ➡️ ศัตรูพุ่งไปทาง "ขวา"  -> เล่น Frame 2
	else:
		if dir.y < 0:
			hand.frame = 2 # ⬆️ ศัตรูพุ่งไปทาง "ขึ้น"   -> เล่น Frame 3
		else:
			hand.frame = 3 # ⬇️ ศัตรูพุ่งไปทาง "ลง"    -> เล่น Frame 4
