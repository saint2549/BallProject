class_name P1Ult
extends RefCounted

static func execute(p1: CharacterBody2D, bounce_count: int = 25, damage_per_bounce: int = 3) -> void:
	var main_scene = p1.get_tree().current_scene
	var main_enemy = _find_main_enemy(main_scene, p1)
	
	if not is_instance_valid(main_enemy):
		print("❌ ไม่พบ Main Enemy ในฉาก!")
		return

	# -------------------------------------------------------------
	# 🛑 1. เริ่ม Ult: ปิดสกิล + ซ่อน Dagger / แสดง Hand
	# -------------------------------------------------------------
	if "is_ult_active" in p1:
		p1.is_ult_active = true

	if is_instance_valid(main_enemy) and "is_silenced" in main_enemy:
		main_enemy.is_silenced = true

	# 🪄 ซ่อน Dagger และแสดง Hand
	if p1.has_method("set_ult_visual_mode"):
		p1.set_ult_visual_mode(true)

	_set_all_ult_bars_paused(main_scene, true)

	var p1_start_pos = p1.global_position
	var enemy_start_pos = main_enemy.global_position

	_set_all_units_frozen(main_scene, p1, main_enemy, true)

	if is_instance_valid(main_enemy) and main_enemy.has_method("set_physics_process"):
		main_enemy.set_physics_process(true)

	var canvas_inv = p1.get_viewport().get_canvas_transform().affine_inverse()
	var viewport_rect = p1.get_viewport_rect()
	var center_pos = canvas_inv * (viewport_rect.size / 2.0)
	var p1_target_pos = center_pos - Vector2(650, 0)

	# --- PHASE 1: ย้าย P1 ไปซ้าย และ Enemy ไปกลางจอ ---
	var tween_setup = p1.create_tween().set_parallel(true)
	tween_setup.tween_property(p1, "global_position", p1_target_pos, 0.6).set_trans(Tween.TRANS_SINE)
	if is_instance_valid(main_enemy):
		tween_setup.tween_property(main_enemy, "global_position", center_pos, 0.6).set_trans(Tween.TRANS_SINE)
	await tween_setup.finished

	# --- PHASE 2: PURE PHYSICS PINBALL BOUNCE ---
	var throw_speed: float = 2200.0
	var return_speed: float = 350.0

	var max_throw_time: float = 0.6
	var recoil_duration: float = 0.35

	for i in range(bounce_count):
		if not is_instance_valid(main_enemy):
			break

		var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		var current_velocity = random_dir * throw_speed

		# 🎬 เปลี่ยน Frame ของ Hand เฉพาะตอนเริ่มขว้าง/พุ่ง (Throw) เท่านั้น
		if p1.has_method("update_ult_sprite_direction"):
			p1.update_ult_sprite_direction(current_velocity)

		var hit_wall = false
		var timer = 0.0

		while not hit_wall and timer < max_throw_time:
			if not is_instance_valid(main_enemy):
				break

			var delta = p1.get_physics_process_delta_time()
			timer += delta

			if "velocity" in main_enemy:
				main_enemy.velocity = current_velocity
			
			var collision: KinematicCollision2D = null
			if main_enemy.has_method("move_and_collide"):
				collision = main_enemy.move_and_collide(current_velocity * delta)

			if collision:
				hit_wall = true
				current_velocity = current_velocity.bounce(collision.get_normal())
				
				# ✋ ไม่เปลี่ยน Frame ตอนเด้งกลับ (ปล่อยให้ใช้ Frame เดิมจากตอนพุ่ง)

				if is_instance_valid(main_enemy) and main_enemy.has_method("take_damage"):
					main_enemy.take_damage(damage_per_bounce)

			await p1.get_tree().physics_frame

		var recoil_timer = 0.0

		while recoil_timer < recoil_duration:
			if not is_instance_valid(main_enemy):
				break

			var delta = p1.get_physics_process_delta_time()
			recoil_timer += delta

			var recoil_vel = current_velocity.normalized() * return_speed
			if "velocity" in main_enemy:
				main_enemy.velocity = recoil_vel

			if main_enemy.has_method("move_and_collide"):
				main_enemy.move_and_collide(recoil_vel * delta)

			await p1.get_tree().physics_frame

	if is_instance_valid(main_enemy) and "velocity" in main_enemy:
		main_enemy.velocity = Vector2.ZERO

	# --- PHASE 3: Reset ตำแหน่งเดิม ---
	var tween_reset = p1.create_tween().set_parallel(true)
	tween_reset.tween_property(p1, "global_position", p1_start_pos, 0.6).set_trans(Tween.TRANS_SINE)
	if is_instance_valid(main_enemy):
		tween_reset.tween_property(main_enemy, "global_position", enemy_start_pos, 0.6).set_trans(Tween.TRANS_SINE)
	await tween_reset.finished

	# -------------------------------------------------------------
	# 🟢 2. Ult จบลง: คืนค่า Dagger ให้แสดงผล / ซ่อน Hand
	# -------------------------------------------------------------
	if is_instance_valid(p1):
		if "is_ult_active" in p1:
			p1.is_ult_active = false
		
		if p1.has_method("set_ult_visual_mode"):
			p1.set_ult_visual_mode(false)

	if is_instance_valid(main_enemy) and "is_silenced" in main_enemy:
		main_enemy.is_silenced = false

	_set_all_units_frozen(main_scene, p1, main_enemy, false)
	_set_all_ult_bars_paused(main_scene, false)

# 🔍 ค้นหา Main Enemy
static func _find_main_enemy(main_scene: Node, p1: Node2D) -> Node2D:
	for child in main_scene.get_children():
		if child != p1 and "team" in child and child.team != p1.team:
			if not ("is_revived" in child and child.is_revived):
				return child
	return null

# ❄️ แช่แข็ง/ปลดแช่แข็งยูนิต
static func _set_all_units_frozen(main_scene: Node, p1: Node2D, main_enemy: Node2D, frozen: bool) -> void:
	for child in main_scene.get_children():
		if child != p1 and child != main_enemy and "team" in child:
			if child.has_method("set_physics_process"):
				child.set_physics_process(!frozen)
			if child.has_method("set_process"):
				child.set_process(!frozen)

			if "modulate" in child:
				child.modulate.a = 0.3 if frozen else 1.0

			_set_node_collision_disabled(child, frozen)

# 🛠️ ปิด/เปิด Collision
static func _set_node_collision_disabled(node: Node, disabled: bool) -> void:
	for child in node.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", disabled)
		elif child.get_child_count() > 0:
			_set_node_collision_disabled(child, disabled)

# ⏸️ ควบคุม UltBar
static func _set_all_ult_bars_paused(node: Node, paused: bool) -> void:
	if node.has_method("set_paused") and node is ProgressBar:
		node.set_paused(paused)
		
	for child in node.get_children():
		_set_all_ult_bars_paused(child, paused)
