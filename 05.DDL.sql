-- SCRIPT DDL

CREATE TABLE Individuo (
  CPF VARCHAR(14),
  nome VARCHAR(100) NOT NULL,
  ficha VARCHAR(5) DEFAULT 'LIMPA',
  genero VARCHAR(100),
  naturalidade VARCHAR(100),
  dataNascimento DATE,
  profissao VARCHAR(100),
  contato VARCHAR(100),

  CONSTRAINT pk_cpf_individuo PRIMARY KEY(CPF),
  CONSTRAINT ck_cpf_formato CHECK (CPF ~ '^\d{3}\.\d{3}\.\d{3}-\d{2}$'),
  CONSTRAINT ck_ficha_individuo CHECK (upper(ficha) IN ('LIMPA', 'SUJA'))
);

CREATE TABLE ProcessoJudicial (
  ID SERIAL,
  Reu VARCHAR(14) NOT NULL,
  titulo VARCHAR(100) NOT NULL,
  procedente VARCHAR(3) DEFAULT 'NÃO',
  dataInicio TIMESTAMP NOT NULL,
  dataFim TIMESTAMP,

  CONSTRAINT pk_id_processo PRIMARY KEY(ID),
  CONSTRAINT ck_reu_processo CHECK (Reu ~ '^\d{3}\.\d{3}\.\d{3}-\d{2}$'),
  CONSTRAINT ck_procedente_processo CHECK (upper(procedente) IN ('NAO', 'SIM')),
  CONSTRAINT fk_reu_processo FOREIGN KEY(Reu) REFERENCES Individuo(CPF)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE Partido (
  nome VARCHAR(50),
  programa VARCHAR(256) NOT NULL,
  CEP VARCHAR(10),
  dataFundacao TIMESTAMP NOT NULL,
  contato VARCHAR(100),

  CONSTRAINT pk_nome_partido PRIMARY KEY(nome),
  CONSTRAINT ck_cep_partido CHECK (CEP ~ '^[0-9]{5}-[0-9]{3}$')
);

CREATE TABLE Candidato (
  CPF VARCHAR(14),
  Partido VARCHAR(50) NOT NULL,

  CONSTRAINT pk_cpf_candidato PRIMARY KEY(CPF),
  CONSTRAINT fk_cpf_candidato FOREIGN KEY(CPF) REFERENCES Individuo(CPF)
    ON DELETE CASCADE,
  CONSTRAINT ck_cpf_candidato CHECK (CPF ~ '^\d{3}\.\d{3}\.\d{3}-\d{2}$'),
  CONSTRAINT fk_partido_candidato FOREIGN KEY(Partido) REFERENCES Partido(nome)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE Cargo (
  nomeCargo VARCHAR(100),
  localCargo VARCHAR(100),
  totalEleitos INTEGER DEFAULT 0 NOT NULL,
  salario NUMERIC(10,2),
  descricao VARCHAR(256),

  CONSTRAINT pk_cargo PRIMARY KEY (nomeCargo, localCargo),
  CONSTRAINT ck_total_eleitos CHECK (totalEleitos >= 0)
);

CREATE TABLE Candidatura (
  candidato VARCHAR(14),
  ano INTEGER,
  cargoNome VARCHAR(50) NOT NULL,
  cargoLocal VARCHAR(100) NOT NULL,
  Vice VARCHAR(14),
  Pleito INTEGER DEFAULT 0 NOT NULL,

  CONSTRAINT pk_candidatura PRIMARY KEY(candidato, ano),
  CONSTRAINT fk_candidato_candidatura FOREIGN KEY(candidato) REFERENCES Candidato(CPF)
    ON DELETE CASCADE,
  CONSTRAINT ck_candidato_candidatura CHECK (candidato ~ '^\d{3}\.\d{3}\.\d{3}-\d{2}$'),
  CONSTRAINT fk_cargo FOREIGN KEY(cargoNome, cargoLocal) REFERENCES Cargo(nomeCargo, localCargo)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT ck_ano_candidatura CHECK (ano >= 1984 AND ano <= 2026),
  CONSTRAINT fk_vice_candidatura FOREIGN KEY(Vice) REFERENCES Candidato(CPF)
    ON DELETE CASCADE,
  CONSTRAINT ck_vice_candidatura CHECK (Vice <> candidato),
  CONSTRAINT ck_pleito CHECK (Pleito >= 0)
);

CREATE TABLE EquipeDeApoio (
  ordem INTEGER NOT NULL,
  candidato VARCHAR(14) NOT NULL,
  ano INTEGER NOT NULL,
  funcao VARCHAR(50), -- marketing, estrategias, infraestrutura, etc.
  status VARCHAR(50) DEFAULT 'ATIVA' NOT NULL, -- ativa ou inativa

  CONSTRAINT pk_equipe PRIMARY KEY(ordem, candidato, ano),
  CONSTRAINT fk_candidatura_equipe FOREIGN KEY(candidato, ano) REFERENCES Candidatura(candidato, ano)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT ck_status_equipe CHECK (upper(status) IN ('ATIVA', 'INATIVA'))
);

CREATE TABLE Apoiador (
  CPF VARCHAR(14),
  EquipeOrdem INTEGER NOT NULL,
  EquipeCandidaturaCandidato VARCHAR(14) NOT NULL,
  EquipeCandidaturaAno INTEGER NOT NULL,
  funcao VARCHAR(30),
  dataIngresso DATE,

  CONSTRAINT pk_cpf_apoiador PRIMARY KEY(CPF, EquipeOrdem, EquipeCandidaturaCandidato, EquipeCandidaturaAno),
  CONSTRAINT fk_equipe_apoiador FOREIGN KEY(EquipeOrdem, EquipeCandidaturaCandidato, EquipeCandidaturaAno) REFERENCES EquipeDeApoio(ordem, candidato, ano)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT ck_cpf_apoiador CHECK (CPF ~ '^\d{3}\.\d{3}\.\d{3}-\d{2}$')
);

CREATE TABLE DoadorJuridico (
  CNPJ VARCHAR(18), -- XX.XXX.XXX/XXXX-XX
  nome VARCHAR(100) NOT NULL,
  tipo VARCHAR(100), --ONG, empresa privada, empresa publica, instituições educacionais, organizações religiosas, sindicatos, cooperativas
  setor VARCHAR(50),
  CEP VARCHAR(9),
  contato VARCHAR(50),

  CONSTRAINT pk_cnpj_doadorjuridico PRIMARY KEY(CNPJ),
  CONSTRAINT ck_cnpj_doadorjuridico CHECK (CNPJ ~ '^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}\-[0-9]{2}$'),
  CONSTRAINT ck_cep_doadorjuridico CHECK (CEP ~ '^[0-9]{5}-[0-9]{3}$')
);
	
CREATE TABLE DoacaoJuridica (
	DoadorJuridico VARCHAR(18),
	CandidaturaCandidato VARCHAR(14),
  CandidaturaAno INTEGER,
	valor NUMERIC(10,2) NOT NULL,

  CONSTRAINT pk_doacaojuridica PRIMARY KEY(DoadorJuridico, CandidaturaCandidato, CandidaturaAno),
  CONSTRAINT fk_doador_doacaojuridica FOREIGN KEY(DoadorJuridico) REFERENCES DoadorJuridico(CNPJ)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_candidatura_doacaojuridica FOREIGN KEY(CandidaturaCandidato, CandidaturaAno) REFERENCES Candidatura(Candidato, ano)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT ck_candidato_doacaojuridica CHECK (CandidaturaCandidato ~ '^(\d{3}).(\d{3}).(\d{3})-(\d{2})$')
);

CREATE TABLE DoacaoFisica (
  ordem INTEGER,
  DoadorFisico VARCHAR(14),
  CandidaturaCandidato VARCHAR(14),
  CandidaturaAno INTEGER,
  valor NUMERIC(10,2) NOT NULL,

  CONSTRAINT pk_doacaofisica PRIMARY KEY(ordem, DoadorFisico, CandidaturaCandidato, CandidaturaAno),
  CONSTRAINT fk_doador_doacaofisico FOREIGN KEY(DoadorFisico) REFERENCES Individuo(CPF)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT ck_doador_doacaofisica CHECK (DoadorFisico ~ '^(\d{3}).(\d{3}).(\d{3})-(\d{2})$'),
  CONSTRAINT fk_candidatura_doacaofisica FOREIGN KEY(CandidaturaCandidato, CandidaturaAno) REFERENCES Candidatura(Candidato, ano)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT ck_candidato_doacaofisica CHECK (CandidaturaCandidato ~ '^(\d{3}).(\d{3}).(\d{3})-(\d{2})$'),
  CONSTRAINT ck_doadorFisico CHECK (DoadorFisico <> CandidaturaCandidato)
);


-- TRIGGER 1
-- Verificar se quando o candidato é criado existe um processo a ele que tenha data de termino referente ate cinco anos antes, se tiver o individuo tem ficha 'SUJA' e nao pode ser candidato.

-- Função de verificação e atualização de ficha
CREATE OR REPLACE FUNCTION verificar_e_atualizar_ficha_candidato()
RETURNS TRIGGER AS $$
BEGIN
  -- Verificar se o indivíduo tem processos judiciais finalizados nos últimos 5 anos
  IF EXISTS (
    SELECT 1
    FROM ProcessoJudicial
    WHERE Reu = NEW.CPF
      AND dataFim IS NOT NULL
      AND dataFim >= NOW() - INTERVAL '5 years'
  ) THEN
    -- Se houver processo finalizado nos últimos 5 anos, atualizar ficha para 'SUJA'
    UPDATE Individuo
    SET ficha = 'SUJA'
    WHERE CPF = NEW.CPF;

    -- Impedir a criação do candidato
    RAISE EXCEPTION 'O indivíduo % tem processos judiciais finalizados nos últimos 5 anos e não pode ser candidato.', NEW.CPF;
  ELSE
    -- Se não houver processos finalizados nos últimos 5 anos, atualizar ficha para 'LIMPA'
    UPDATE Individuo
    SET ficha = 'LIMPA'
    WHERE CPF = NEW.CPF;
  END IF;

  -- Permitir a criação do candidato
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para verificar e atualizar ficha antes da inserção em Candidato
CREATE TRIGGER trigger_verificar_e_atualizar_ficha_candidato
BEFORE INSERT ON Candidato
FOR EACH ROW
EXECUTE FUNCTION verificar_e_atualizar_ficha_candidato();



-- TRIGGER 2
-- Garantir que um apoiador não possa ser adicionado em mais de uma equipe que esteja relacionada a candidaturas do mesmo ano.

-- Trigger para verificar a inserção de apoiador em equipe
CREATE OR REPLACE FUNCTION verificar_apoiador_equipe()
RETURNS TRIGGER AS $$
DECLARE
  equipe_existente BOOLEAN;
BEGIN
  -- Verificar se o apoiador já está associado a uma equipe com candidaturas do mesmo ano
  SELECT TRUE INTO equipe_existente
  FROM Apoiador
  WHERE CPF = NEW.CPF
    AND EquipeCandidaturaAno = NEW.EquipeCandidaturaAno
    AND (EquipeCandidaturaCandidato, EquipeCandidaturaAno) <> (NEW.EquipeCandidaturaCandidato, NEW.EquipeCandidaturaAno)
  LIMIT 1;

  -- Se já existe uma equipe com o mesmo apoiador e mesma candidatura do mesmo ano, impedir a inserção
  IF equipe_existente THEN
    RAISE EXCEPTION 'O apoiador já está associado a uma equipe com candidaturas do mesmo ano.';
  END IF;

  -- Permitir a inserção do apoiador na equipe
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para verificar a inserção de apoiador em equipe
CREATE TRIGGER trigger_verificar_apoiador_equipe
BEFORE INSERT ON Apoiador
FOR EACH ROW
EXECUTE FUNCTION verificar_apoiador_equipe();



-- TRIGGER 3
-- Garantir que um candidato não possa ser também vice de outra candidatura.

-- Trigger para verificar a criação de candidatura
CREATE OR REPLACE FUNCTION verificar_candidato_vice()
RETURNS TRIGGER AS $$
DECLARE
  vice_existente BOOLEAN;
BEGIN
  -- Verificar se o CPF do candidato está sendo usado como vice em outra candidatura
  SELECT TRUE INTO vice_existente
  FROM Candidatura
  WHERE Vice = NEW.candidato;

  -- Se o candidato já é vice em outra candidatura, impedir a inserção da nova candidatura
  IF vice_existente THEN
    RAISE EXCEPTION 'O candidato já é vice em outra candidatura e não pode ser candidato.';
  END IF;

  -- Permitir a inserção da nova candidatura
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para verificar a criação de candidatura
CREATE TRIGGER trigger_verificar_candidato_vice
BEFORE INSERT ON Candidatura
FOR EACH ROW
EXECUTE FUNCTION verificar_candidato_vice();