extends Control

func _ready() -> void:
	pass

func _on_jogar_pressed() -> void:
	get_tree().change_scene_to_file("res://introducao.tscn")

func _on_créditos_pressed() -> void:
	print("Créditos")

func _on_configuracoes_pressed() -> void:
	get_tree().change_scene_to_file("res://configuracoes.tscn")
	
func _on_sair_pressed() -> void:
	get_tree().quit()
	
