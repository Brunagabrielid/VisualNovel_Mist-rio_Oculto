extends Control

const ARQUIVO_CONFIG := "user://configuracoes.cfg"
const CODIGOS_IDIOMA := ["pt_BR", "en"]

const PADROES := {
	"volume": 1.0,
	"velocidade_texto": 1.0,
	"tamanho_fonte": 20,
	"tela_cheia": false,
	"idioma": "pt_BR",
}

var slider_volume: HSlider
var slider_velocidade: HSlider
var slider_fonte: HSlider
var check_tela_cheia: CheckButton
var opcao_idioma: OptionButton


func _ready() -> void:
	_construir_interface()
	_carregar_valores()
	_conectar_sinais()


# ---------- Interface ----------

func _construir_interface() -> void:
	var background := TextureRect.new()
	background.name = "Background"
	background.texture = load("res://backgrounds/fundo_policial.png")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 120)
	margin.add_theme_constant_override("margin_right", 120)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)

	var titulo := Label.new()
	titulo.name = "Titulo"
	titulo.text = "Configurações"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 40)
	vbox.add_child(titulo)

	# Áudio
	var secao_audio := _criar_secao("SecaoAudio", "Áudio")
	vbox.add_child(secao_audio)
	slider_volume = _criar_slider(secao_audio, "Volume", 0.0, 1.0, 0.05)

	# Diálogos
	var secao_dialogos := _criar_secao("SecaoDialogos", "Diálogos")
	vbox.add_child(secao_dialogos)
	slider_velocidade = _criar_slider(secao_dialogos, "Velocidade do texto", 0.5, 2.0, 0.1)

	# Aparência
	var secao_aparencia := _criar_secao("SecaoAparencia", "Aparência")
	vbox.add_child(secao_aparencia)
	check_tela_cheia = CheckButton.new()
	check_tela_cheia.text = "Tela cheia"
	secao_aparencia.add_child(check_tela_cheia)
	slider_fonte = _criar_slider(secao_aparencia, "Tamanho da fonte", 12, 32, 1)

	# Idioma
	var secao_idioma := _criar_secao("SecaoIdioma", "Idioma")
	vbox.add_child(secao_idioma)
	opcao_idioma = OptionButton.new()
	opcao_idioma.add_item("Português (Brasil)", 0)
	opcao_idioma.add_item("English", 1)
	secao_idioma.add_child(opcao_idioma)

	# Botões do rodapé
	var botoes := HBoxContainer.new()
	botoes.name = "BotoesRodape"
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 30)
	vbox.add_child(botoes)

	var restaurar := Button.new()
	restaurar.name = "BotaoRestaurar"
	restaurar.text = "Restaurar padrões"
	restaurar.custom_minimum_size = Vector2(260, 50)
	restaurar.pressed.connect(_on_restaurar_pressed)
	botoes.add_child(restaurar)

	var voltar := Button.new()
	voltar.name = "BotaoVoltar"
	voltar.text = "Voltar"
	voltar.custom_minimum_size = Vector2(200, 50)
	voltar.pressed.connect(_on_voltar_pressed)
	botoes.add_child(voltar)


func _criar_secao(nome: String, titulo: String) -> VBoxContainer:
	var secao := VBoxContainer.new()
	secao.name = nome
	secao.add_theme_constant_override("separation", 8)
	var rotulo := Label.new()
	rotulo.text = titulo
	rotulo.add_theme_font_size_override("font_size", 26)
	secao.add_child(rotulo)
	return secao


func _criar_slider(pai: Control, texto: String, minimo: float, maximo: float, passo: float) -> HSlider:
	var rotulo := Label.new()
	rotulo.text = texto
	pai.add_child(rotulo)
	var slider := HSlider.new()
	slider.min_value = minimo
	slider.max_value = maximo
	slider.step = passo
	pai.add_child(slider)
	return slider


# ---------- Valores ----------


func _carregar_valores() -> void:
	var dados: Dictionary = Database.carregar_configuracoes()

	if dados.is_empty():
		return

	slider_volume.value = dados["volume"]
	slider_velocidade.value = dados["velocidade_texto"]
	slider_fonte.value = dados["tamanho_fonte"]
	check_tela_cheia.button_pressed = bool(dados["tela_cheia"])

	var idioma: String = dados["idioma"]
	opcao_idioma.select(maxi(CODIGOS_IDIOMA.find(idioma), 0))

	_aplicar_todos()


func _salvar() -> void:
	print("A FUNÇÃO SALVAR FOI CHAMADA!")

	Database.salvar_configuracoes(
		slider_volume.value,
		slider_velocidade.value,
		int(slider_fonte.value),
		check_tela_cheia.button_pressed,
		CODIGOS_IDIOMA[opcao_idioma.selected]
	)
	
	

func _aplicar_todos() -> void:
	_aplicar_volume(slider_volume.value)
	_aplicar_tela_cheia(check_tela_cheia.button_pressed)
	_aplicar_idioma(CODIGOS_IDIOMA[opcao_idioma.selected])


# ---------- Sinais ----------

func _conectar_sinais() -> void:
	slider_volume.value_changed.connect(func(v: float) -> void:
		_aplicar_volume(v)
		_salvar())
	slider_velocidade.value_changed.connect(func(_v: float) -> void: _salvar())
	slider_fonte.value_changed.connect(func(_v: float) -> void: _salvar())
	check_tela_cheia.toggled.connect(func(ativa: bool) -> void:
		_aplicar_tela_cheia(ativa)
		_salvar())
	opcao_idioma.item_selected.connect(func(i: int) -> void:
		_aplicar_idioma(CODIGOS_IDIOMA[i])
		_salvar())


func _on_restaurar_pressed() -> void:
	slider_volume.value = PADROES["volume"]
	slider_velocidade.value = PADROES["velocidade_texto"]
	slider_fonte.value = PADROES["tamanho_fonte"]
	check_tela_cheia.button_pressed = PADROES["tela_cheia"]
	opcao_idioma.select(maxi(CODIGOS_IDIOMA.find(PADROES["idioma"]), 0))
	_aplicar_todos()
	_salvar()


func _on_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")


# ---------- Aplicação ----------

func _aplicar_volume(valor: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(valor, 0.0001)))


func _aplicar_tela_cheia(ativa: bool) -> void:
	if ativa:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _aplicar_idioma(codigo: String) -> void:
	TranslationServer.set_locale(codigo)
