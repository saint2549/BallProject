extends Control
func _ready() -> void:
	Global.p1_selected_character = ""
	Global.p2_selected_character = ""

func _on_start_pressed() -> void:
	if Global.p1_selected_character != "" and Global.p2_selected_character != "":
		print("เลือกตัวละครสำเร็จ! กำลังเข้าสู่ฉากต่อสู้...")
		get_tree().change_scene_to_file("res://Scene/Main.tscn") # เปลี่ยนไปยัง Scene หลัก (ปรับ Path ให้ตรงกับไฟล์ main.tscn ของคุณ)
	else:
		print("กรุณาลากตัวละครลงในช่อง P1 (แดง) และ P2 (น้ำเงิน) ให้ครบก่อนเริ่มเกม!")


func _on_return_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/Menu.tscn")
