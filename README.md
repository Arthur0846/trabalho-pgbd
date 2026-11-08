# Trabalho PGBD: Migrações com Flyway

Trabalho final de Projeto e Gerência de Banco de Dados (2026/2, UFSM).
Tema 9: versionamento e migrações de banco de dados, com **Flyway** (edição OSS 11), **MySQL 8.4** e **Docker**.

## O que é

O Flyway aplica scripts SQL versionados (`V1__...sql`, `V2__...sql`) em ordem e registra no próprio banco o que já foi aplicado, na tabela `flyway_schema_history`. Assim, todo mundo da equipe (e o servidor de CI) chega ao mesmo esquema, partindo de um banco vazio e com um único comando.

## Como rodar

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

3. Aplicar as migrações e conferir:
   ```
   docker compose run --rm flyway migrate
   docker compose run --rm flyway info
   ```
   Em um banco vazio, o `info` antes do `migrate` mostra `Schema version: << Empty Schema >>`.
   (Na primeira vez o Docker baixa as imagens, então demora mais.)

## Comandos básicos

```
docker compose run --rm flyway info       # estado de cada migração (aplicada, pendente, falha)
docker compose run --rm flyway migrate    # aplicar migrações pendentes
docker compose run --rm flyway validate   # conferir se os arquivos batem com o histórico (checksum)
docker compose run --rm flyway repair     # corrigir o histórico (remove falhas, realinha checksums)
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

O Flyway conecta ao banco por JDBC, conforme `conf/flyway.conf`.

## Estrutura

```
docker-compose.yml             # MySQL 8.4 + Flyway 11
conf/flyway.conf               # conexão e pasta das migrações
sql/                           # migrações (V<n>__nome.sql e R__nome.sql)
.github/workflows/flyway.yml   # CI: migrate + validate + info a cada push
```

## Regras das migrações

- Versionadas: `V<número>__<descrição>.sql` (dois sublinhados). Rodam uma única vez, em ordem crescente.
- Repetíveis: `R__<descrição>.sql`. Rodam de novo sempre que o conteúdo muda, sempre depois de todas as versionadas.
- **Nunca editar uma migração já aplicada.** Para mudar algo, criar uma nova versão. (Na demonstração do erro de checksum a edição é feita de propósito e depois revertida com `git restore`.)
- Uma migração por commit, com mensagem no formato `feat: V4 adiciona email em clientes`.
- Antes de criar uma migração, conferir no repositório qual é o próximo número livre.

---

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
| `V7__adicionar_telefone_clientes` | Coluna `telefone` em `clientes` | Contato por telefone |
| `V8__adicionar_categoria_produtos` | Coluna `categoria` em `produtos` | Organizar o catálogo (veio de outra branch, ver cenário 4) |
| `V9__nascimento_e_indice_sobrenome` | Coluna `data_nascimento` e índice em `clientes.sobrenome` | Duas mudanças na mesma migração |
| `V10__remover_data_nascimento` | Remove `data_nascimento` (o índice de sobrenome permanece) | Decisão de não guardar o dado (**migração corretiva**, ver cenário 5) |
| `R__view_resumo_pedidos` | View `vw_resumo_pedidos` | Relatório que muda com frequência (**migração repetível**) |

Nota sobre a V3: os dados de exemplo estão em uma migração por simplicidade. Em um projeto real, dados de teste ficam separados do esquema.

## Cenários avançados da demonstração

| # | Cenário | Como foi feito |
|---|---|---|
| 1 | **Erro de checksum** | Editar a `V1` já aplicada, rodar `validate` (falha), mostrar o `repair` e reverter o arquivo com `git restore` |
| 2 | **Falha no meio da migração** | `V11` local, não versionada, com dois comandos: `ADD COLUMN cpf` funciona e o `CREATE INDEX` em coluna inexistente falha. No MySQL não há DDL transacional, então a coluna `cpf` fica criada e o histórico marca a V11 como falha. Correção: apagar `cpf` à mão, `repair`, corrigir o arquivo e rodar `migrate` de novo |
| 3 | **Conflito entre branches** | Duas branches criaram a `V7` (telefone e categoria). Após o merge, a categoria foi renumerada para `V8` (commit `fix: renumera V7 de categoria para V8`) |
| 4 | **Reversão sem a edição paga** | O Flyway gratuito não tem undo. A `V10` desfaz parte da `V9` com uma migração nova, e `migrate -target=N` reconstrói o banco até uma versão |
| 5 | **`baseline`** | Adoção em um banco que já existe |
| 6 | **CI/CD** | GitHub Actions: sobe um MySQL 8.4 como serviço e roda `migrate`, `validate` e `info` a cada push. A branch `teste/ci-vermelho` contém a `V11__quebrada.sql` (coluna inexistente) para provar um pipeline vermelho. **Essa branch nunca é mesclada na `main`** |

### Atenção: repetível e `-target`

Mesmo com `migrate -target=4`, o Flyway aplica a migração repetível. A `R__view_resumo_pedidos` usa a coluna `sobrenome` (criada na V5), então ela falha se rodar antes. Para mostrar o banco "antes da V5" na demonstração, tire o arquivo da pasta `sql/` temporariamente:

```
Move-Item sql\R__view_resumo_pedidos.sql $env:TEMP\R__view_resumo_pedidos.sql
docker compose run --rm flyway migrate -target=4
docker compose exec db mysql -uapp -papp123 loja -e "SELECT id, nome FROM clientes;"
Move-Item $env:TEMP\R__view_resumo_pedidos.sql sql\R__view_resumo_pedidos.sql
docker compose run --rm flyway migrate
docker compose exec db mysql -uapp -papp123 loja -e "SELECT id, nome, sobrenome FROM clientes;"
```

## Dados e conexão com o banco (demonstração)

- A **V5** transforma dados existentes: "Carla Mendes Oliveira" vira `nome = Carla` e `sobrenome = Mendes Oliveira`.
- Consultas diretas (terminal ou DBeaver) mostram os dados antes e depois, e a view `vw_resumo_pedidos`.
- Dados inseridos à mão **não são versionados**: o Flyway versiona o esquema, e o `down -v` apaga tudo.

## Problemas comuns

- **Erro `dockerDesktopLinuxEngine`:** abra o Docker Desktop e espere iniciar.
- **Erro `mysqld.sock` ou `Unable to obtain connection`:** o banco ainda está subindo; espere o `healthy`.
- **Porta 3307 ocupada:** troque `"3307:3306"` no `docker-compose.yml` (ex.: `"3308:3306"`).
- **`validate` falha com checksum:** alguém editou uma migração já aplicada. Desfaça a edição (`git restore`) ou, se a mudança for intencional, rode `repair`.
- **`migrate` recusa seguir com migração falha:** em MySQL, desfaça à mão o que a migração aplicou pela metade, rode `repair` e só então corrija o arquivo.
- **`migrate` falha na `V11` ao rodar na branch `teste/ci-vermelho`:** é proposital, essa branch existe para o CI vermelho. Volte para a `main` (`git switch main`).
