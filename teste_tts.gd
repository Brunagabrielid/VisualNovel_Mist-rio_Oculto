

extends Node

var voz_portugues: String = ""
var velocidade: float = 1.0

var texto_teste: String = """
Olá! Bem-vinda ao Mistério Oculto.

Mina Kang entrou na sala lentamente.
Seus olhos percorreram os móveis antes de encontrar uma pista sobre o caso.
"""

func _ready() -> void:
	var vozes = DisplayServer.tts_get_voices_for_language("pt")

	if vozes.is_empty():
		print("Nenhuma voz em português encontrada.")
		return

	voz_portugues = vozes[0]

	print("Narradora selecionada: ", voz_portugues)
	print("CONTROLES:")
	print("ESPAÇO: pausar ou continuar")
	print("R: repetir a leitura")
	print("S: parar a leitura")
	print("+ ou =: aumentar velocidade")
	print("-: diminuir velocidade")

	falar(texto_teste)

func falar(texto: String) -> void:
	if voz_portugues.is_empty():
		return

	DisplayServer.tts_speak(
		texto,
		voz_portugues,
		100,
		1.0,
		velocidade,
		1,
		true
	)

	print("Lendo texto na velocidade: ", velocidade)


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_SPACE:
			if DisplayServer.tts_is_paused():
				DisplayServer.tts_resume()
				print("Leitura retomada.")
			elif DisplayServer.tts_is_speaking():
				DisplayServer.tts_pause()
				print("Leitura pausada.")

		KEY_R:
			falar(texto_teste)

		KEY_S:
			DisplayServer.tts_stop()
			print("Leitura interrompida.")

		KEY_EQUAL, KEY_KP_ADD:
			velocidade = minf(velocidade + 0.1, 2.0)
			print("Velocidade: ", velocidade)

		KEY_MINUS, KEY_KP_SUBTRACT:
			velocidade = maxf(velocidade - 0.1, 0.5)
			print("Velocidade: ", velocidade)
