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

## Problemas comuns

- **Erro `dockerDesktopLinuxEngine`:** abra o Docker Desktop e espere iniciar.
- **Erro `mysqld.sock` ou `Unable to obtain connection`:** o banco ainda está subindo; espere o `healthy`.
- **Porta 3307 ocupada:** troque `"3307:3306"` no `docker-compose.yml` (ex.: `"3308:3306"`).