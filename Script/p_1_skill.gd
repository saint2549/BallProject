class_name P1Skill
extends RefCounted

static func activate_spin_skill(character: Node2D) -> void:
	character.is_skill_active = true
	character.skilltimer = 0.0
	character.current_spin_speed = character.fast_spin_speed
	
	for dagger in character.dagger_instances:
		if is_instance_valid(dagger):
			dagger.is_empowered = true

static func deactivate_spin_skill(character: Node2D) -> void:
	character.is_skill_active = false
	character.skillendtimer = 0.0
	character.current_spin_speed = character.normal_spin_speed
	
	for dagger in character.dagger_instances:
		if is_instance_valid(dagger):
			dagger.is_empowered = false

static func try_revive_enemy(character: Node2D, target: Node) -> void:
	if not is_instance_valid(target):
		return
		
	if not ("hp" in target) or target.hp > 0:
		return
		
	MinionConverter.spawn_revived_minion(target, character.team)
