
extends Control

const NOME_SAVE = "Bruna"

func _ready() -> void:
	var dialogue_resource = load("res://backgrounds/cena1intro.dialogue")

	# Carrega os dados do jogador
	var dados_save = Database.carregar_save(NOME_SAVE)

	# Verifica o ponto salvo
	var ponto_inicial = "introducao"

	if not dados_save.is_empty():
		var progresso_salvo = dados_save.get("progresso", null)

		if progresso_salvo != null and str(progresso_salvo) != "":
			ponto_inicial = str(progresso_salvo)

	print("Iniciando diálogo em: ", ponto_inicial)

	# Inicia a narrativa
	DialogueManager.show_dialogue_balloon(dialogue_resource, ponto_inicial)
