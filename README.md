# Trabalho PGBD: Migrações com Flyway

Trabalho final de Projeto e Gerência de Banco de Dados (2026/2).
Tema: versionamento e migrações de banco de dados com **Flyway**, usando **MySQL** e **Docker**.

## O que é

O Flyway aplica scripts SQL versionados (`V1__...sql`, `V2__...sql`) em ordem e registra o que já foi aplicado no banco. Assim, todo mundo da equipe mantém o mesmo esquema.

## Como configurar

**Pré-requisitos:** Git e Docker Desktop **aberto e rodando**.

1. Clonar o repositório:
   ```
   git clone https://github.com/Arthur0846/trabalho-pgbd.git
   cd trabalho-pgbd
   ```

2. Subir o banco e esperar o status `healthy` (leva cerca de 1 minuto):
   ```
   docker compose up -d db
   docker compose ps
   ```

3. Testar o Flyway:
   ```
   docker compose run --rm flyway info
   ```
   Se aparecer `Schema version: << Empty Schema >>`, está tudo certo.
   (Na primeira vez o Docker baixa as imagens, então demora mais.)

## Comandos básicos

```
docker compose run --rm flyway info       # ver estado das migrações
docker compose run --rm flyway migrate    # aplicar migrações pendentes
docker compose down -v                    # apagar o banco e voltar ao zero
```

Ver as tabelas direto no banco:
```
docker compose exec db mysql -uapp -papp123 loja -e "SHOW TABLES;"
```

## Conexão (para DBeaver etc.)

| | |
|---|---|
| Host | `localhost` |
| Porta | `3307` |
| Banco | `loja` |
| Usuário / senha | `app` / `app123` |

## Estrutura

```
docker-compose.yml   # MySQL + Flyway
conf/flyway.conf     # configuração do Flyway
sql/                 # migrações (V1__nome.sql, V2__nome.sql ...)
```

## Regras das migrações

- Nome: `V<número>__<descrição>.sql` (dois sublinhados).
- Nunca editar uma migração já aplicada; criar uma nova versão.

# Estudo de caso: loja virtual

Banco de dados: `loja` (MySQL 8.4). Migrações gerenciadas pelo Flyway, arquivos em `sql/`.

## Por que este domínio

- Pequeno: 4 tabelas, fácil de explicar em um slide.
- Tem relacionamentos (chaves estrangeiras), o que mostra a importância da **ordem** das migrações.
- Evolui de forma natural: campos novos, dados que precisam ser transformados, índices, relatórios.

## História de evolução do banco

| Arquivo | O que muda | Motivo (para contar na apresentação) |
|---|---|---|
| `V1__criar_clientes_e_produtos` | Tabelas `clientes` e `produtos` | Lançamento da loja |
| `V2__criar_pedidos_e_itens` | `pedidos` e `itens_pedido` (com chaves estrangeiras) | A loja passa a vender |
| `V3__inserir_dados_iniciais` | Clientes, produtos e pedidos de exemplo | Ambiente de desenvolvimento com dados |
| `V4__adicionar_email_clientes` | Coluna `email` em `clientes` | Marketing quer contatar os clientes |
| `V5__separar_nome_sobrenome` | `nome` vira `nome` + `sobrenome`, preservando os dados | Nota fiscal exige o sobrenome separado (**migração de dados**) |
| `V6__criar_indices` | Índices em `pedidos.data_pedido` e `clientes.email` | Consultas por data e por e-mail ficaram lentas |
| `R__view_resumo_pedidos` | View `vw_resumo_pedidos` | Relatório que muda com frequência (**migração repetível**) |

## Versões reservadas (V7 em diante)

Ficam livres para os cenários avançados da demonstração:

- Erro de checksum (editar uma migração já aplicada e rodar `validate`).
- Conflito de versão entre duas branches (duas pessoas criando a mesma V7).
- Falha no meio de uma migração (no MySQL não há DDL transacional, o banco fica parcialmente alterado).
- Reversão sem a edição paga do Flyway (migração corretiva).
- Adoção em um banco já existente (`baseline`).

## Regras do time

- Nome dos arquivos: `V<número>__<descrição>.sql` (dois sublinhados).
- **Nunca editar uma migração já aplicada.** Para mudar algo, criar uma nova versão.
- Uma migração por commit, com mensagem no formato `feat: V4 adiciona email em clientes`.
- Antes de criar uma migração, conferir no repositório qual é o próximo número livre.

## Divisão de tarefas

| Integrante | Migrações |
|---|---|
| (nome) | V1 e V2 |
| (nome) | V3 e V4 |
| (nome) | V5, V6 e `R__view_resumo_pedidos` |

## Problemas comuns

- **Erro `dockerDesktopLinuxEngine`:** abra o Docker Desktop e espere iniciar.
- **Erro `mysqld.sock` ou `Unable to obtain connection`:** o banco ainda está subindo; espere o `healthy`.
- **Porta 3307 ocupada:** troque `"3307:3306"` no `docker-compose.yml` (ex.: `"3308:3306"`).
