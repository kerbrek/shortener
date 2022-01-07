# Shortener

JSON API сервис для сокращения URL с возможностью задавать кастомные ссылки.
Используется фреймворк _FastAPI_, библиотека _SQLAlchemy_ и база _PostgreSQL_.

Запускается командой `make up` и доступен по адресу <http://127.0.0.1:8000/>.

Пример:

Запрос 1

`POST /`

```json
{
  "url": "https://stackoverflow.com/questions/28152523/make-postgres-choose-the-next-minimal-available-id"
}
```

Ответ 1

```json
{
  "url": "http://localhost/Fe"
}
```

Запрос 2

`POST /`

```json
{
  "url": "https://stackoverflow.com/questions/11828270/how-do-i-exit-the-vim-editor",
  "custom_id": "vim"
}
```

Ответ 2

```json
{
  "url": "http://localhost/vim"
}
```

## Prerequisites

- pipenv
- make
- docker
- docker-compose

## Commands

- Start _Docker Compose_ services

  `make up`

- Setup a working environment using _Pipenv_

  `make setup`

- Start development Web server (with database and cache)

  `make start`

- Run tests

  `make test`

- Run linter

  `make lint`

- List all available _Make_ commands

  `make help`
