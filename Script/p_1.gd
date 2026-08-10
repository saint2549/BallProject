extends CharacterBody2D

@export var character_name: String = "ทีม"
@export var team: String = "P1"
signal hp_changed(new_hp: int)

@export var speed: int = 400
@export var hp: int = 100
const MinionConverterScript = preload("res://Script/minion_converter.gd")

# 🌟 ตั้งค่าระบบหมุนกริชและสกิล
@export var dagger_scene: PackedScene = preload("res://Scene/dagger.tscn")
@export var normal_spin_speed: float = 2.0  # ความเร็วหมุนปกติ
@export var fast_spin_speed: float = 40.0   # ความเร็วหมุนตอนใช้สกิล
@export var orbit_radius: float = 120.0     # รัศมีระยะห่างของกริช

@export var skillcharge: float = 3.0        # สกิลทำงานทุกๆ 3 วินาที
@export var skillduration: float = 1.0      # ระยะเวลาแสดงผลสกิล

var current_spin_speed: float = 2.0
var spin_direction: float = 1.0            # 🌟 1 = หมุนตามเข็ม, -1 = หมุนทวนเข็ม
var angle: float = 0.0

var dagger_instances: Array[Area2D] = []

var skilltimer: float = 0.0
var skillendtimer: float = 0.0
var is_skill_active: bool = false

var damage_cooldown: float = 0.0
var move_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	current_spin_speed = normal_spin_speed
	var random_x = randf_range(-1.0, 1.0)
	var random_y = randf_range(-1.0, 1.0)
	move_direction = Vector2(random_x, random_y).normalized()
	
	spawn_daggers()

func spawn_daggers() -> void:
	if dagger_scene:
		for i in range(2):
			var dagger = dagger_scene.instantiate()
			dagger.team = self.team
			dagger_instances.append(dagger)
			add_child(dagger)

func toggle_spin_direction() -> void:
	spin_direction *= -1.0
	print("กริชเปลี่ยนทิศทางการหมุนเป็น: ", "ตามเข็ม" if spin_direction > 0 else "ทวนเข็ม")

func _physics_process(delta: float) -> void:
	if not is_skill_active:
		skilltimer += delta
		if skilltimer >= skillcharge:
			activate_skill()
	else:
		skillendtimer += delta
		if skillendtimer >= skillduration:
			deactivate_skill()

	angle += current_spin_speed * spin_direction * delta
	
	if dagger_instances.size() > 0 and is_instance_valid(dagger_instances[0]):
		var offset1 = Vector2(cos(angle), sin(angle)) * orbit_radius
		dagger_instances[0].position = offset1
		dagger_instances[0].rotation = angle

	if dagger_instances.size() > 1 and is_instance_valid(dagger_instances[1]):
		var opposite_angle = angle + PI
		var offset2 = Vector2(cos(opposite_angle), sin(opposite_angle)) * orbit_radius
		dagger_instances[1].position = offset2
		dagger_instances[1].rotation = opposite_angle

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
				# 🟢 ทำความเสียหายใส่ศัตรู
				collider.take_damage(10)
				take_damage(10)
				
				_maybe_revive_on_kill(collider)

func _maybe_revive_on_kill(target: Node) -> void:
	if not is_instance_valid(target):
		return
	if not ("hp" in target) or target.hp > 0:
		return
	MinionConverterScript.spawn_revived_minion(target, self.team)

func activate_skill() -> void:
	is_skill_active = true
	skilltimer = 0.0
	current_spin_speed = fast_spin_speed
	
	for dagger in dagger_instances:
		if is_instance_valid(dagger):
			dagger.is_empowered = true

func deactivate_skill() -> void:
	is_skill_active = false
	skillendtimer = 0.0
	current_spin_speed = normal_spin_speed
	
	for dagger in dagger_instances:
		if is_instance_valid(dagger):
			dagger.is_empowered = false

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
