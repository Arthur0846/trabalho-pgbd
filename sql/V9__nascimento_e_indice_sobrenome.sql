ALTER TABLE clientes ADD COLUMN data_nascimento DATE NULL;

CREATE INDEX idx_clientes_sobrenome ON clientes (sobrenome);