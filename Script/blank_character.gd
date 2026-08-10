extends CharacterBody2D

@export var character_name: String = "blank"
@export var team: String = "P1"
signal hp_changed(new_hp: int)

@export var speed: int = 400
@export var hp: int = 100

var damage_cooldown: float = 0.0
var move_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
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
		
		move_direction = move_direction.bounce(normal)
		global_position += normal * 3.0
		
		if is_instance_valid(collider) and collider.has_method("take_damage"):
			if !("team" in collider) or collider.team != self.team:
				# 🟢 ทำความเสียหายใส่ศัตรูเมื่อชนกัน
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
