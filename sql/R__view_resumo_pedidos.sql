CREATE OR REPLACE VIEW vw_resumo_pedidos AS
SELECT
    p.id AS pedido_id,
    p.data_pedido,
    CONCAT(c.nome, ' ', c.sobrenome) AS cliente,
    COUNT(i.id) AS qtd_itens,
    SUM(i.quantidade * i.preco_unitario) AS total
FROM pedidos p
JOIN clientes c ON c.id = p.cliente_id
JOIN itens_pedido i ON i.pedido_id = p.id
GROUP BY p.id, p.data_pedido, c.nome, c.sobrenome;