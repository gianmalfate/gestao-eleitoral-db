<br />
<div align="center">
  <a href="https://github.com/othneildrew/Best-README-Template">
    <img src="https://cdn-icons-png.flaticon.com/512/9850/9850812.png" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">SSC0240 - Projeto de Base de Dados</h3>

  <p align="center">
    Este é um sistema de gerenciamento eleitoral desenvolvido em Python, que permite consultar, remover dados, listar candidaturas, gerar relatórios de candidaturas eleitas e listar pessoas com ficha limpa em um banco de dados PostgreSQL.
  </p>
</div>


## Instalação

1. Crie um banco de dados PostgreSQL, e execute os comandos
    - DDL.sql
    - DML.sql

    Eles realizaram a criação da instância do banco de dados e inserção de dados fictícios.

2. Instalação de dependências
    ```
    pip install psycopg2-binary
    pip install python-dotenv
    pip install tabulate
    ```

3. Configurar variáveis de ambiente
    - Crie um arquivo '.env' com a seguinte estrutura:
    
    ```
    DB_NAME=nome_do_banco_de_dados
    DB_USER=nome_do_usuario
    DB_PASSWORD=senha_do_usuario
    DB_HOST=endereco_do_host
    DB_PORT=porta_do_host
    ```

# Utilização

Para utilizar o script, basta executar o arquivo ``main.py`` com o seguinte código:

```
python main.py
```

Com isso você já poderá realizar consultas nos dados e excluí-los!
