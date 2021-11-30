.DEFAULT_GOAL := help

.PHONY: setup # Setup a working environment
setup:
	env PIPENV_VENV_IN_PROJECT=1 pipenv install --dev

.PHONY: shell # Spawn a shell within the virtual environment
shell:
	PIPENV_DOTENV_LOCATION=.env.example pipenv shell

.PHONY: lint # Run linter
lint:
	PIPENV_DOTENV_LOCATION=.env.example pipenv run pylint shortener/

.PHONY: test # Run tests
test:
	@echo Starting db container...
	docker run -d --rm --name shortener_test_db -p 5433:5432 --env-file ./.env.example postgres:13
	@sleep 1
	@bash -c "trap 'echo && echo Stopping db container... && docker stop shortener_test_db' EXIT; \
	echo Initializing database...; \
	PIPENV_DOTENV_LOCATION=.env.example pipenv run env POSTGRES_PORT=5433 python -m shortener.init_db; \
	echo Starting tests...; \
	PIPENV_DOTENV_LOCATION=.env.example pipenv run env POSTGRES_PORT=5433 pytest tests/"

.PHONY: coverage # Run tests with coverage report
coverage:
	@echo Starting db container...
	docker run -d --rm --name shortener_test_db -p 5433:5432 --env-file ./.env.example postgres:13
	@sleep 1
	@bash -c "trap 'echo && echo Stopping db container... && docker stop shortener_test_db' EXIT; \
	echo Initializing database...; \
	PIPENV_DOTENV_LOCATION=.env.example pipenv run env POSTGRES_PORT=5433 python -m shortener.init_db; \
	echo Starting tests...; \
	PIPENV_DOTENV_LOCATION=.env.example pipenv run env POSTGRES_PORT=5433 pytest --cov-report term-missing:skip-covered --cov=shortener tests/"

.PHONY: start # Start development Web server (with database)
start:
	@echo Starting db container...
	docker run -d --rm --name shortener_temp_db -p 5432:5432 --env-file ./.env.example postgres:13
	@sleep 1
	@bash -c "trap 'echo && echo Stopping db container... && docker stop shortener_temp_db' EXIT; \
	echo Initializing database...; \
	PIPENV_DOTENV_LOCATION=.env.example pipenv run python -m shortener.init_db; \
	echo Starting application...; \
	PIPENV_DOTENV_LOCATION=.env.example pipenv run uvicorn shortener.main:app --reload"

.PHONY: db # Start Postgres container
db:
	@echo Starting db container...
	docker run -d --rm --name shortener_temp_db -p 5432:5432 --env-file ./.env.example postgres:13
	@bash -c "trap 'echo && echo Stopping db container... && docker stop shortener_temp_db' EXIT; \
	echo Press CTRL+C to stop && sleep 1d"

.PHONY: requirements # Generate requirements.txt file
requirements:
	pipenv lock --requirements > requirements.txt

.PHONY: up # Start Compose services
up:
	docker-compose up --build

.PHONY: down # Stop Compose services
down:
	docker-compose down

.PHONY: up-dev # Start Compose services (development)
up-dev:
	docker-compose -f docker-compose.dev.yml up --build

.PHONY: down-dev # Stop Compose services (development)
down-dev:
	docker-compose -f docker-compose.dev.yml down

.PHONY: up-debug # Start Compose services (debug)
up-debug:
	docker-compose -f docker-compose.debug.yml up --build

.PHONY: down-debug # Stop Compose services (debug)
down-debug:
	docker-compose -f docker-compose.debug.yml down

## https://stackoverflow.com/a/45843594/6475258
.PHONY: help # Print list of targets with descriptions
help:
	@grep '^.PHONY: .* #' $(lastword $(MAKEFILE_LIST)) | sed 's/\.PHONY: \(.*\) # \(.*\)/\1	\2/' | expand -t20

## https://stackoverflow.com/a/26339924/6475258
# .PHONY: list # Print list of targets
# list:
# 	@LC_ALL=C $(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
