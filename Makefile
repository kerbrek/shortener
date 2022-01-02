.DEFAULT_GOAL := help

SHELL := /usr/bin/env bash

project := shortener

.PHONY: setup # Setup a working environment
setup:
	env PIPENV_VENV_IN_PROJECT=1 pipenv install --dev

.PHONY: shell # Spawn a shell within the virtual environment
shell:
	env PIPENV_DOTENV_LOCATION=.env.example pipenv shell

.PHONY: lint # Run linter
lint:
	pipenv run pylint ${project}/

.PHONY: prepare-test-containers
prepare-test-containers:
	@echo Starting db container...
	@docker run -d --rm --name ${project}_test_db --env-file ./.env.example -p 5433:5432 postgres:13-alpine
	@echo Starting cache container...
	@docker run -d --rm --name ${project}_test_cache -p 11211:11211 memcached:1-alpine

stop-prepared-test-containers := echo; \
	echo Stopping db container...; \
	docker stop ${project}_test_db; \
	echo Stopping cache container...; \
	docker stop ${project}_test_cache

.PHONY: test # Run tests
test: prepare-test-containers
	@sleep 1
	@trap '${stop-prepared-test-containers}' EXIT && \
		echo Initializing database... && \
		env PIPENV_DOTENV_LOCATION=.env.example pipenv run env POSTGRES_PORT=5433 python -m ${project}.init_db && \
		echo Starting tests... && \
		env PIPENV_DOTENV_LOCATION=.env.example pipenv run env POSTGRES_PORT=5433 pytest tests/

.PHONY: coverage # Run tests with coverage report
coverage: prepare-test-containers
	@sleep 1
	@trap '${stop-prepared-test-containers}' EXIT && \
		echo Initializing database... && \
		env PIPENV_DOTENV_LOCATION=.env.example pipenv run env POSTGRES_PORT=5433 python -m ${project}.init_db && \
		echo Starting tests... && \
		env PIPENV_DOTENV_LOCATION=.env.example pipenv run env POSTGRES_PORT=5433 pytest --cov-report term-missing:skip-covered --cov=${project} tests/

.PHONY: prepare-temp-containers
prepare-temp-containers:
	@echo Starting db container...
	@docker run -d --rm --name ${project}_temp_db --env-file ./.env.example -p 5432:5432 postgres:13-alpine
	@echo Starting cache container...
	@docker run -d --rm --name ${project}_temp_cache -p 11211:11211 memcached:1-alpine

stop-prepared-temp-containers := echo; \
	echo Stopping db container...; \
	docker stop ${project}_temp_db; \
	echo Stopping cache container...; \
	docker stop ${project}_temp_cache

.PHONY: start # Start development Web server (with database and cache)
start: prepare-temp-containers
	@sleep 1
	@trap '${stop-prepared-temp-containers}' EXIT && \
		echo Initializing database... && \
		env PIPENV_DOTENV_LOCATION=.env.example pipenv run python -m ${project}.init_db && \
		echo Starting application... && \
		env PIPENV_DOTENV_LOCATION=.env.example pipenv run uvicorn ${project}.main:app --reload

.PHONY: db # Start Postgres and Memcached containers
db: prepare-temp-containers
	@trap '${stop-prepared-temp-containers}' EXIT && \
		echo Press CTRL+C to stop && \
		sleep 1d

.PHONY: requirements # Generate requirements.txt file
requirements:
	pipenv lock --requirements > requirements.txt

.PHONY: up # Start Compose services
up:
	docker-compose pull db cache nginx
	docker-compose build --pull
	docker-compose up

.PHONY: down # Stop Compose services
down:
	docker-compose down

.PHONY: up-dev # Start Compose services (development)
up-dev:
	docker-compose -f docker-compose.dev.yml pull db cache
	docker-compose -f docker-compose.dev.yml build --pull
	docker-compose -f docker-compose.dev.yml up

.PHONY: down-dev # Stop Compose services (development)
down-dev:
	docker-compose -f docker-compose.dev.yml down

.PHONY: up-debug # Start Compose services (debug)
up-debug:
	docker-compose -f docker-compose.debug.yml pull db cache
	docker-compose -f docker-compose.debug.yml build --pull
	docker-compose -f docker-compose.debug.yml up

.PHONY: down-debug # Stop Compose services (debug)
down-debug:
	docker-compose -f docker-compose.debug.yml down

.PHONY: prod-pull-build
prod-pull-build:
	@echo Pulling docker images
	docker-compose -f docker-compose.prod.yml pull cache nginx
	@echo Building docker images
	docker-compose -f docker-compose.prod.yml build --pull

.PHONY: prod-up
prod-up:
	@echo Starting compose services
	docker-compose -f docker-compose.prod.yml up --detach

.PHONY: prod-down
prod-down:
	@echo Stopping compose services
	docker-compose -f docker-compose.prod.yml down

.PHONY: prod-restart
prod-restart: prod-pull-build prod-down prod-up

.PHONY: help # Print list of targets with descriptions
help:
	@echo; \
		for mk in $(MAKEFILE_LIST); do \
			echo \# $$mk; \
			grep '^.PHONY: .* #' $$mk | sed 's/\.PHONY: \(.*\) # \(.*\)/\1	\2/' | expand -t20; \
			echo; \
		done
