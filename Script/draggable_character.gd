extends Control

@export var character_id: String = "Char1"

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var initial_position: Vector2

func _ready() -> void:
	initial_position = position

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_offset = get_global_mouse_position() - global_position
		else:
			is_dragging = false
			check_drop_zone()

func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset

func check_drop_zone() -> void:
	var parent = get_parent()
	var p1_zone = parent.get_node_or_null("P1Zone")
	var p2_zone = parent.get_node_or_null("P2Zone")
	
	if p1_zone and p1_zone.get_global_rect().has_point(global_position + size / 2):
		global_position = p1_zone.global_position + (p1_zone.size - size) / 2
		Global.p1_selected_character = character_id
		
	elif p2_zone and p2_zone.get_global_rect().has_point(global_position + size / 2):
		global_position = p2_zone.global_position + (p2_zone.size - size) / 2
		Global.p2_selected_character = character_id
		
	else:
		global_position = initial_position
