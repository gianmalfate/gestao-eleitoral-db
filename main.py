import psycopg2
from tabulate import tabulate
import os
from dotenv import load_dotenv

# Carregar variáveis de ambiente do arquivo .env
load_dotenv()

# Configurações do banco de dados
dbname = os.getenv('DB_NAME')
username = os.getenv('DB_USER')
password = os.getenv('DB_PASSWORD')
host = os.getenv('DB_HOST')
port = os.getenv('DB_PORT')

#definindo esquemas para pegar os headers das tabelas
esquemas = {
    "Individuo": ['CPF', 'Nome', 'Ficha', 'Genero', 'Naturalidade', 'Data de Nascimento', 'Profissao', 'Contato'],
    "ProcessoJudicial": ['ID', 'Reu', 'Titulo', 'Procedente', 'Data de Inicio', 'Data de Fim'],
    "Partido": ['Nome', 'Programa', 'CEP', 'Data de Fundacao', 'Contato'],
    "Candidato": ['CPF', 'Partido'],
    "Cargo": ['Nome do Cargo', 'Local do Cargo', 'Total de Eleitos', 'Salario', 'Descricao'],
    "Candidatura": ['Candidato', 'Ano', 'Nome do Cargo', 'Local do Cargo', 'Vice', 'Pleito'],
    "EquipeDeApoio": ['Ordem', 'Candidato', 'Ano', 'Funcao', 'Status'],
    "Apoiador": ['CPF', 'Equipe Ordem', 'Equipe Candidato', 'Equipe Ano', 'Funcao', 'Data de Ingresso'],
    "DoadorJuridico": ['CNPJ', 'Nome', 'Tipo', 'Setor', 'CEP', 'Contato'],
    "DoacaoJuridica": ['Doador Juridico', 'Candidatura Candidato', 'Candidatura Ano', 'Valor'],
    "DoacaoFisica": ['Ordem', 'Doador Fisico', 'Candidatura Candidato', 'Candidatura Ano', 'Valor']
}

# Definindo chaves primárias para as tabelas
chaves_primarias = {
    "Individuo": ['CPF'],
    "ProcessoJudicial": ['ID'],
    "Partido": ['nome'],
    "Candidato": ['CPF'],
    "Cargo": ['nomeCargo', 'localCargo'],
    "Candidatura": ['candidato', 'ano'],
    "EquipeDeApoio": ['ordem', 'candidato', 'ano'],
    "Apoiador": ['CPF', 'EquipeOrdem', 'EquipeCandidaturaCandidato', 'EquipeCandidaturaAno'],
    "DoadorJuridico": ['CNPJ'],
    "DoacaoJuridica": ['DoadorJuridico', 'CandidaturaCandidato', 'CandidaturaAno'],
    "DoacaoFisica": ['ordem', 'DoadorFisico', 'CandidaturaCandidato', 'CandidaturaAno']
}

def conectar():
    return psycopg2.connect(
        dbname=dbname,
        user=username,
        password=password,
        host=host,
        port=port
    )

def consultar(tabela):
    menu_base()
    print(f"\nConsulta de {tabela}:\n")
    print(f"Aqui estão os detalhes de {tabela}.")

    conn = conectar()
    cur = conn.cursor()
    if tabela == "Candidato":
        sql = f"""
                SELECT 
                    c.cpf,
                    i.nome,
                    c.partido
                FROM candidato c
                JOIN individuo i
                ON i.cpf = c.cpf
                """
        headers = ["CPF", "Nome", "Partido"]
    else:
        sql = f"SELECT * FROM {tabela}"
        headers = esquemas[tabela]
   
    
    try:
        cur.execute(sql)
        records = cur.fetchall()

        # Montando tabela para apresentação
        table = tabulate(records, headers=headers, tablefmt='fancy_grid', missingval="-")
        print(table)

    except psycopg2.DatabaseError as ex:        
        print("[ERRO] Erro interno na consulta do banco")
        print(ex)

    cur.close()
    conn.close()

    input("Pressione enter para retornar ao menu: ")

def obter_chaves_primarias(tabela):
    """
    Retorna as chaves primárias da tabela especificada.
    """
    if tabela in chaves_primarias:
        return chaves_primarias[tabela]
    else:
        return []

def remover(tabela):
    menu_base()
    print(f"\nRemoção de dados da tabela {tabela}:\n")

    # Obter chaves primárias da tabela
    chaves_primarias = obter_chaves_primarias(tabela)

    # Perguntar ao usuário se ele quer remover todos os dados ou um dado específico
    opcao = input("Digite '*' para remover todos os dados ou '1' para remover um dado específico: ").strip().upper()

    if opcao == '*':
        # Remover todos os dados
        conn = conectar()
        cur = conn.cursor()
        sql = f"DELETE FROM {tabela}"

        try:
            cur.execute(sql)
            conn.commit()
            print(f"Todos os dados da tabela {tabela} foram removidos com sucesso.")
        except psycopg2.DatabaseError as ex:
            print("[ERRO] Erro interno na remoção dos dados")
            print(ex)
        finally:
            cur.close()
            conn.close()

    elif opcao == '1' and chaves_primarias:
        # Remover um dado específico
        condicoes = []
        valores = []

        for chave in chaves_primarias:
            valor = input(f"Digite o valor de {chave}: ").strip()
            condicoes.append(f"{chave} = %s")
            valores.append(valor)

        condicao_sql = " AND ".join(condicoes)
        sql = f"DELETE FROM {tabela} WHERE {condicao_sql}"

        conn = conectar()
        cur = conn.cursor()

        try:
            cur.execute(sql, valores)
            conn.commit()
            if cur.rowcount > 0:
                print(f"O dado específico da tabela {tabela} foi removido com sucesso.")
            else:
                print("Nenhum dado correspondente foi encontrado para remoção.")
        except psycopg2.DatabaseError as ex:
            print("[ERRO] Erro interno na remoção dos dados")
            print(ex)
        finally:
            cur.close()
            conn.close()

    else:
        print("Opção inválida ou tabela sem chaves primárias definidas.")

    input("Pressione enter para retornar ao menu: ")

def listar_candidaturas(ano=None, nome_candidato=None, nome_cargo=None, ordenacao='Ano'):
    menu_base()
    print("\nListagem de candidaturas:\n")

    conn = conectar()
    cur = conn.cursor()
    
    sql = """
            SELECT 
                c.candidato,
                candidato.nome,
                c.ano,
                c.cargonome,
                c.cargolocal,
                c.vice,
                vice.nome,
                c.pleito
            FROM Candidatura c
            JOIN Individuo candidato
            ON c.candidato = candidato.cpf 
            LEFT JOIN Individuo vice
            ON c.Vice = vice.CPF
            WHERE TRUE
            """
    if ano:
        sql += f" AND c.ano = {ano}"
    if nome_candidato:
        sql += f" AND candidato.nome = '{nome_candidato}'"
    if nome_cargo:
        sql += f" AND c.cargonome = '{nome_cargo}'"

    if ordenacao == "Ano":
        sql += f" ORDER BY c.ano"
    elif ordenacao == "Local":
        sql += f" ORDER BY c.cargolocal"


    headers = ["CPF Candidato", "Nome Candidato", "Ano Candidatura", "Nome do Cargo", "Local do Cargo", "CPF Vice", "Nome Vice", "Pleito"]

    try:
        cur.execute(sql)
        records = cur.fetchall()

        table = tabulate(records, headers=headers, tablefmt='fancy_grid', missingval="-")
        print(table)
    except psycopg2.DatabaseError as ex:
        print("[ERRO] Erro interno na consulta do banco")
        print(ex)

    cur.close()
    conn.close()

    input("Pressione enter para retornar ao menu: ")

def relatorio_candidaturas_eleitos():
    menu_base()
    print("\nRelatório de candidaturas eleitas:\n")

    conn = conectar()
    cur = conn.cursor()

    sql = f"""
            SELECT 
                c.candidato,
                candidato.nome,
                c.ano,
                c.cargonome,
                c.cargolocal,
                c.vice,
                vice.nome,
                c.pleito
            FROM Candidatura c
            JOIN Individuo candidato
            ON c.candidato = candidato.cpf 
            LEFT JOIN Individuo vice
            ON c.Vice = vice.CPF
            WHERE c.Pleito = 1
            """
    
    headers = ["CPF do Candidato", "Nome do Candidato", "Ano da Candidatura", "Nome do Cargo", "Local do Cargo", "CPF do Vice", "Nome do Vice", "Pleito"]

    try:
        cur.execute(sql)
        records = cur.fetchall()

        table = tabulate(records, headers=headers, tablefmt='fancy_grid', missingval="-")
        print(table)
    except psycopg2.DatabaseError as ex:
        print("[ERRO] Erro interno na consulta do banco")
        print(ex)

    cur.close()
    conn.close()

    input("Pressione enter para retornar ao menu: ")

def listar_ficha_limpa():
    menu_base()
    print("\nListagem de pessoas ficha limpa:\n")

    conn = conectar()
    cur = conn.cursor()

    sql = f"""
            SELECT * FROM Individuo
            WHERE Ficha = 'LIMPA'
            """
    
    headers = esquemas["Individuo"]

    try:
        cur.execute(sql)
        records = cur.fetchall()

        table = tabulate(records, headers=headers, tablefmt='fancy_grid', missingval="-")
        print(table)
    except psycopg2.DatabaseError as ex:
        print("[ERRO] Erro interno na consulta do banco")
        print(ex)

    cur.close()
    conn.close()

    input("Pressione enter para retornar ao menu: ")

def limpar_terminal():
    if os.name == 'posix':  # Para sistemas Unix/Linux/Mac
        os.system('clear')
    elif os.name == 'nt':  # Para sistemas Windows
        os.system('cls')

def menu_base():
    print("\n============= MENU =============\n")

def menu_principal():
    menu_base()
    print("    1 - Consultar tabelas")
    print("    2 - Remover dados")
    print("    3 - Listar candidaturas")
    print("    4 - Relatório de candidaturas eleitas")
    print("    5 - Listar pessoas ficha limpa")
    print("    0 - Sair\n")

def menu_consultar():
    menu_base()
    print("    1 - Consultar Individuos")
    print("    2 - Consultar Processos Judiciais")
    print("    3 - Consultar Partidos")
    print("    4 - Consultar Candidatos")
    print("    5 - Consultar Cargos")
    print("    6 - Consultar Candidaturas")
    print("    7 - Consultar Equipes De Apoio")
    print("    8 - Consultar Apoiadores")
    print("    9 - Consultar Doadores Juridicos")
    print("    10 - Consultar Doações Juridicas")
    print("    11 - Consultar Doações Fisicas")
    print("    0 - Retornar\n")

def menu_remover():
    menu_base()
    print("    1 - Remover Individuo")
    print("    2 - Remover Processo Judicial")
    print("    3 - Remover Partido")
    print("    4 - Remover Candidato")
    print("    5 - Remover Cargo")
    print("    6 - Remover Candidatura")
    print("    7 - Remover Equipe De Apoio")
    print("    8 - Remover Apoiador")
    print("    9 - Remover Doador Juridico")
    print("    10 - Remover Doacao Juridica")
    print("    11 - Remover Doacao Fisica")
    print("    0 - Retornar\n")

def processar_opcao(opcao):
    if opcao == 1:
        menu_consultar()
        sub_opcao = int(input("Escolha uma opção de consulta: "))
        limpar_terminal()

        if sub_opcao == 0:
            print("Retornando")

        elif sub_opcao == 1:
            consultar("Individuo")

        elif sub_opcao == 2:
            consultar("ProcessoJudicial")

        elif sub_opcao == 3:
            consultar("Partido")

        elif sub_opcao == 4:
            consultar("Candidato")

        elif sub_opcao == 5:
            consultar("Cargo")

        elif sub_opcao == 6:
            consultar("Candidatura")

        elif sub_opcao == 7:
            consultar("EquipeDeApoio")

        elif sub_opcao == 8:
            consultar("Apoiador")

        elif sub_opcao == 9:
            consultar("DoadorJuridico")

        elif sub_opcao == 10:
            consultar("DoacaoJuridica")

        elif sub_opcao == 11:
            consultar("DoacaoFisica")

    elif opcao == 2:
        menu_remover()
        sub_opcao = int(input("Escolha uma opção de remoção: "))
        limpar_terminal()

        if sub_opcao == 0:
            print("Retornando")

        elif sub_opcao == 1:
            remover("Individuo")

        elif sub_opcao == 2:
            remover("ProcessoJudicial")

        elif sub_opcao == 3:
            remover("Partido")

        elif sub_opcao == 4:
            remover("Candidato")

        elif sub_opcao == 5:
            remover("Cargo")

        elif sub_opcao == 6:
            remover("Candidatura")

        elif sub_opcao == 7:
            remover("EquipeDeApoio")

        elif sub_opcao == 8:
            remover("Apoiador")

        elif sub_opcao == 9:
            remover("DoadorJuridico")

        elif sub_opcao == 10:
            remover("DoacaoJuridica")

        elif sub_opcao == 11:
            remover("DoacaoFisica")

    elif opcao == 3:
        print("\nEscolha os filtros para listagem de candidaturas (deixe em branco para ignorar):\n")
        ano = input("Ano: ") or None
        nome_candidato = input("Nome do candidato: ") or None
        nome_cargo = input("Nome do cargo: ") or None
        ordenacao = input("Ordenação (Ano ou Local): ") or 'Ano'
        listar_candidaturas(ano, nome_candidato, nome_cargo, ordenacao)

    elif opcao == 4:
        relatorio_candidaturas_eleitos()

    elif opcao == 5:
        listar_ficha_limpa()

    elif opcao == 0:
        print("Saindo do programa.")

    else:
        print("Opção inválida. Tente novamente.")
        opcao = int(input("Escolha uma opção: "))

if __name__ == '__main__':
    opcao = 1
    while opcao:
        menu_principal()
        opcao = int(input("Escolha uma opção: "))
        processar_opcao(opcao)
        limpar_terminal()