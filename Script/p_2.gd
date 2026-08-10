extends CharacterBody2D

@export var character_name: String = "Pugun"
@export var team: String = "P2"
signal hp_changed(new_hp: int)

@export var speed: int = 400
@export var hp: int = 100
@export var minion_scene: PackedScene = preload("res://Scene/p_2_1.tscn")

var damage_cooldown: float = 0.0
var move_direction: Vector2 = Vector2.ZERO
var has_spawned_minion: bool = false # 🌟 ตัวแปรป้องกันการสปอว์นซ้ำ
var is_revived: bool = false #

func _ready() -> void:
	var random_x = randf_range(-1.0, 1.0)
	var random_y = randf_range(-1.0, 1.0)
	move_direction = Vector2(random_x, random_y).normalized()

	# เสก Minion ครั้งเดียวเมื่อเข้าสนาม
	call_deferred("spawn_minion_at_random_position")

func spawn_minion_at_random_position() -> void:
	# 🟢 ถ้าตายอยู่, เป็นตัวละครที่ถูกชุบชีวิตขึ้นมา หรือเคยเสกไปแล้ว ให้ยกเลิกทันที
	if hp <= 0 or is_revived or has_spawned_minion: # 👈 [แก้ไข]
		return
		
	if minion_scene:
		has_spawned_minion = true
		
		var minion = minion_scene.instantiate()
		var spawn_x = randf_range(100.0, 1000.0)
		var spawn_y = randf_range(100.0, 500.0)
		minion.global_position = Vector2(spawn_x, spawn_y)
		
		if "team" in minion:
			minion.team = self.team

		if "character_name" in minion:
			minion.character_name = self.team + " Minion"
			
		var main_scene = get_parent()
		if main_scene:
			main_scene.add_child(minion)
			if main_scene.has_method("register_unit_hp_ui"):
				main_scene.register_unit_hp_ui(minion)

func _physics_process(delta: float) -> void:
	if damage_cooldown > 0:
		damage_cooldown -= delta

	velocity = move_direction * speed
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var collider = collision.get_collider()
		var normal = collision.get_normal()
		
		move_direction = move_direction.bounce(normal)
		global_position += normal * 3.0
		
		if collider.has_method("take_damage"):
			if !("team" in collider) or collider.team != self.team:
				collider.take_damage(10)
				take_damage(10)

func take_damage(amount: int) -> void:
	if damage_cooldown > 0:
		return

	if hp > 0:
		hp = clampi(hp - amount, 0, 100)
		hp_changed.emit(hp)
		
		damage_cooldown = 0.2
		if hp <= 0:
			visible = false
