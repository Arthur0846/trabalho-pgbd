ALTER TABLE clientes
    ADD COLUMN sobrenome VARCHAR(100) NOT NULL DEFAULT '';

UPDATE clientes
SET sobrenome = TRIM(SUBSTRING(nome, LOCATE(' ', nome) + 1)),
    nome = SUBSTRING_INDEX(nome, ' ', 1)
WHERE LOCATE(' ', nome) > 0;