
extends Node

var db: SQLite


# ==========================================
# CONFIGURAÇÕES PADRÃO
# ==========================================

const CONFIGURACOES_PADRAO = {
	"volume": 1.0,
	"velocidade_texto": 1.0,
	"tamanho_fonte": 20,
	"tela_cheia": 0,
	"idioma": "pt_BR",
	"som_ativo": 1,
	"volume_musica": 1.0,
	"volume_efeitos": 1.0,
	"cor_legenda": "#FFFFFF",
	"espacamento_texto": 1.0,
	"alto_contraste": 0
}


# ==========================================
# CONEXÃO COM O BANCO
# ==========================================

func conectar() -> void:
	db = SQLite.new()
	db.path = "user://configuracoes.db"

	if not db.open_db():
		push_error("Erro ao conectar ao banco de dados: " + db.error_message)
		return

	print("Banco de dados conectado!")

	_criar_tabela_configuracoes()
	_migrar_tabela_configuracoes()
	_criar_tabela_salvar_progresso()


# ==========================================
# TABELA DE CONFIGURAÇÕES
# ==========================================

func _criar_tabela_configuracoes() -> void:
	db.query("""
	CREATE TABLE IF NOT EXISTS configuracoes (
		id INTEGER PRIMARY KEY CHECK (id = 1),
		volume REAL NOT NULL DEFAULT 1.0,
		velocidade_texto REAL NOT NULL DEFAULT 1.0,
		tamanho_fonte INTEGER NOT NULL DEFAULT 20,
		tela_cheia INTEGER NOT NULL DEFAULT 0,
		idioma TEXT NOT NULL DEFAULT 'pt_BR',
		som_ativo INTEGER NOT NULL DEFAULT 1,
		volume_musica REAL NOT NULL DEFAULT 1.0,
		volume_efeitos REAL NOT NULL DEFAULT 1.0,
		cor_legenda TEXT NOT NULL DEFAULT '#FFFFFF',
		espacamento_texto REAL NOT NULL DEFAULT 1.0,
		alto_contraste INTEGER NOT NULL DEFAULT 0
	);
	""")

	db.query("""
	INSERT OR IGNORE INTO configuracoes (id)
	VALUES (1);
	""")

	print("Tabela de configurações pronta!")


# ==========================================
# MIGRAÇÃO DE CONFIGURAÇÕES ANTIGAS
# ==========================================

func _migrar_tabela_configuracoes() -> void:

	var novas_colunas = {
		"som_ativo": "INTEGER NOT NULL DEFAULT 1",
		"volume_musica": "REAL NOT NULL DEFAULT 1.0",
		"volume_efeitos": "REAL NOT NULL DEFAULT 1.0",
		"cor_legenda": "TEXT NOT NULL DEFAULT '#FFFFFF'",
		"espacamento_texto": "REAL NOT NULL DEFAULT 1.0",
		"alto_contraste": "INTEGER NOT NULL DEFAULT 0"
	}

	db.query("PRAGMA table_info(configuracoes);")

	var colunas_existentes = []

	for coluna in db.query_result:
		colunas_existentes.append(coluna["name"])

	for nome_coluna in novas_colunas:
		if not nome_coluna in colunas_existentes:
			var comando = "ALTER TABLE configuracoes ADD COLUMN " + nome_coluna + " " + novas_colunas[nome_coluna] + ";"

			if not db.query(comando):
				push_error("Erro ao adicionar coluna: " + nome_coluna)
			else:
				print("Coluna adicionada: ", nome_coluna)

	print("Migração das configurações concluída!")


# ==========================================
# CARREGAR CONFIGURAÇÕES
# ==========================================

func carregar_configuracoes() -> Dictionary:

	if db == null:
		return {}

	db.query("SELECT * FROM configuracoes WHERE id = 1;")

	if db.query_result.is_empty():
		return {}

	return db.query_result[0]


# ==========================================
# SALVAR CONFIGURAÇÕES ANTIGAS
# Mantida para compatibilidade com configuracoes.gd
# ==========================================

func salvar_configuracoes(
	volume: float,
	velocidade: float,
	fonte: int,
	tela_cheia: bool,
	idioma: String
) -> void:

	var sucesso = db.query_with_bindings(
		"""
		UPDATE configuracoes
		SET volume = ?,
			velocidade_texto = ?,
			tamanho_fonte = ?,
			tela_cheia = ?,
			idioma = ?
		WHERE id = 1;
		""",
		[
			volume,
			velocidade,
			fonte,
			int(tela_cheia),
			idioma
		]
	)

	if not sucesso:
		push_error("Erro ao salvar configurações: " + db.error_message)
		return

	print("Configurações antigas salvas!")


# ==========================================
# SALVAR TODAS AS CONFIGURAÇÕES
# ==========================================

func salvar_configuracoes_completas(dados: Dictionary) -> void:

	var sucesso = db.query_with_bindings(
		"""
		UPDATE configuracoes
		SET volume = ?,
			velocidade_texto = ?,
			tamanho_fonte = ?,
			tela_cheia = ?,
			idioma = ?,
			som_ativo = ?,
			volume_musica = ?,
			volume_efeitos = ?,
			cor_legenda = ?,
			espacamento_texto = ?,
			alto_contraste = ?
		WHERE id = 1;
		""",
		[
			dados.get("volume", 1.0),
			dados.get("velocidade_texto", 1.0),
			dados.get("tamanho_fonte", 20),
			int(dados.get("tela_cheia", false)),
			dados.get("idioma", "pt_BR"),
			int(dados.get("som_ativo", true)),
			dados.get("volume_musica", 1.0),
			dados.get("volume_efeitos", 1.0),
			dados.get("cor_legenda", "#FFFFFF"),
			dados.get("espacamento_texto", 1.0),
			int(dados.get("alto_contraste", false))
		]
	)

	if not sucesso:
		push_error("Erro ao salvar configurações completas: " + db.error_message)
		return

	print("Todas as configurações foram salvas!")


# ==========================================
# TABELA SALVAR_PROGRESSO
# ==========================================

func _criar_tabela_salvar_progresso() -> void:

	db.query("""
	CREATE TABLE IF NOT EXISTS Salvar_Progresso (
		nome_usuario TEXT PRIMARY KEY NOT NULL
			CHECK (length(nome_usuario) <= 20),
		idioma TEXT NOT NULL DEFAULT 'pt-BR',
		tamanho_texto INTEGER NOT NULL DEFAULT 16,
		velocidade_texto REAL NOT NULL DEFAULT 1.0,
		volume_musica REAL NOT NULL DEFAULT 0.5,
		volume_efeito REAL NOT NULL DEFAULT 0.5,
		progresso TEXT
	);
	""")

	print("Tabela Salvar_Progresso criada ou já existente!")


# ==========================================
# CADASTRAR SAVE
# ==========================================

func criar_save(nome_usuario: String) -> bool:

	nome_usuario = nome_usuario.strip_edges()

	if nome_usuario.is_empty() or nome_usuario.length() > 20:
		push_warning("O nome deve ter entre 1 e 20 caracteres.")
		return false

	var sucesso = db.query_with_bindings(
		"""
		INSERT INTO Salvar_Progresso (
			nome_usuario,
			idioma,
			tamanho_texto,
			velocidade_texto,
			volume_musica,
			volume_efeito
		)
		SELECT ?, idioma, tamanho_fonte, velocidade_texto,
			volume_musica, volume_efeitos
		FROM configuracoes
		WHERE id = 1;
		""",
		[nome_usuario]
	)

	if not sucesso:
		push_error("Erro ao criar save: " + db.error_message)
		return false

	print("Registro salvo com sucesso!")
	return true


# ==========================================
# CARREGAR SAVE
# ==========================================

func carregar_save(nome_usuario: String) -> Dictionary:

	db.query_with_bindings(
		"""
		SELECT *
		FROM Salvar_Progresso
		WHERE nome_usuario = ?;
		""",
		[nome_usuario]
	)

	if db.query_result.is_empty():
		return {}

	return db.query_result[0]


# ==========================================
# EXCLUIR SAVE
# ==========================================

func excluir_save(nome_usuario: String) -> bool:

	var sucesso = db.query_with_bindings(
		"""
		DELETE FROM Salvar_Progresso
		WHERE nome_usuario = ?;
		""",
		[nome_usuario]
	)

	if not sucesso:
		push_error("Erro ao excluir save: " + db.error_message)
		return false

	print("Save excluído!")
	return true


# ==========================================
# SALVAR PROGRESSO DA HISTÓRIA
# ==========================================

func salvar_progresso(nome_usuario: String, progresso: String) -> bool:

	var sucesso = db.query_with_bindings(
		"""
		UPDATE Salvar_Progresso
		SET progresso = ?
		WHERE nome_usuario = ?;
		""",
		[
			progresso,
			nome_usuario
		]
	)

	if not sucesso:
		push_error("Erro ao salvar progresso: " + db.error_message)
		return false

	print("Progresso salvo!")
	return true


# ==========================================
# INICIALIZAÇÃO
# ==========================================
func _ready() -> void:
	conectar()
