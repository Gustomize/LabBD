-- Trigger para adicionar um sufixo ao inserir um departamento
CREATE OR REPLACE TRIGGER tg_sufixo BEFORE
    INSERT ON depto
    FOR EACH ROW
BEGIN
    :new.nomedepto := :new.nomedepto
                      || 'sons';
END;

-- Trigger para impedir que o insert ou update de um professor que seja doutor

CREATE OR REPLACE TRIGGER tg_doutor BEFORE
    INSERT OR UPDATE OF codtit ON professor
    FOR EACH ROW
BEGIN
    IF :new.codtit = 1 THEN
        raise_application_error(-20000, 'Titulação Inválida');
    END IF;
END;

-- Trigger de auditoria, pega o horario e o usuário logado após cada alteração.

CREATE OR REPLACE TRIGGER tg_historico AFTER
    UPDATE ON professor
    FOR EACH ROW
DECLARE
    data_atualizacao   TIMESTAMP;
    login_atual        VARCHAR2(20);
BEGIN
    data_atualizacao := current_timestamp;
    login_atual := sys_context('USERENV', 'SESSION_USER');
    INSERT INTO professor_hist VALUES (
        :new.codprof,
        :new.coddepto,
        :new.codtit,
        :new.nomeprof,
        data_atualizacao,
        login_atual
    );

END;

-- trigger para garantir integridade referencial

CREATE OR REPLACE TRIGGER tg_fkprereq BEFORE
    DELETE ON disciplina
    FOR EACH ROW
BEGIN
    DELETE FROM prereq
    WHERE
        ( numdisc = :old.numdisc )
        OR ( prereq.numdiscprereq = :old.numdisc );

END;

CREATE OR REPLACE TRIGGER tg_fkdisciplina BEFORE
    INSERT OR UPDATE ON prereq
    FOR EACH ROW
DECLARE
    linhas NUMBER;
BEGIN
    SELECT
        numdisc
    INTO linhas
    FROM
        disciplina
    WHERE
        numdisc = :new.numdisc
        OR numdisc = :new.numdiscprereq;

    IF linhas < 1 THEN
        raise_application_error(-20000, 'INSERT ou UPDATE na tabela (prereq) viola a FK');
    END IF;
END;