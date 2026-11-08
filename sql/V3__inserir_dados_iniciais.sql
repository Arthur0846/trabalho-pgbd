INSERT INTO clientes (nome) VALUES
    ('Ana Souza'),
    ('Bruno Lima'),
    ('Carla Mendes Oliveira');

INSERT INTO produtos (nome, preco) VALUES
    ('Teclado', 150.00),
    ('Mouse', 80.00),
    ('Monitor', 900.00);

INSERT INTO pedidos (cliente_id) VALUES (1), (1), (2);

INSERT INTO itens_pedido (pedido_id, produto_id, quantidade, preco_unitario) VALUES
    (1, 1, 1, 150.00),
    (1, 2, 2, 80.00),
    (2, 3, 1, 900.00),
    (3, 2, 1, 80.00);