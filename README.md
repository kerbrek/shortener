# Shortener

JSON API сервис для сокращения URL с возможностью задавать кастомные ссылки.
Используется фреймворк _FastAPI_, библиотека _SQLAlchemy_ и база _PostgreSQL_.

Запускается командой `make up` и доступен по адресу <http://127.0.0.1:8000/>.

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
