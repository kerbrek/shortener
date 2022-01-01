.DEFAULT_GOAL := help

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

.PHONY: test # Run tests
test: prepare-test-containers
	@sleep 1
	@bash -c "trap \
	            'echo && echo Stopping db and cache containers...; \
	            docker stop ${project}_test_db; \
	            docker stop ${project}_test_cache' \
	          EXIT; \
	          echo Initializing database... && \
	          env PIPENV_DOTENV_LOCATION=.env.example pipenv run env POSTGRES_PORT=5433 python -m ${project}.init_db && \
	          echo Starting tests... && \
	          env PIPENV_DOTENV_LOCATION=.env.example pipenv run env POSTGRES_PORT=5433 pytest tests/"

.PHONY: coverage # Run tests with coverage report
coverage: prepare-test-containers
	@sleep 1
	@bash -c "trap \
	            'echo && echo Stopping db and cache containers...; \
	            docker stop ${project}_test_db; \
	            docker stop ${project}_test_cache' \
	          EXIT; \
	          echo Initializing database... && \
	          env PIPENV_DOTENV_LOCATION=.env.example pipenv run env POSTGRES_PORT=5433 python -m ${project}.init_db && \
	          echo Starting tests... && \
	          env PIPENV_DOTENV_LOCATION=.env.example pipenv run env POSTGRES_PORT=5433 pytest --cov-report term-missing:skip-covered --cov=${project} tests/"

.PHONY: prepare-temp-containers
prepare-temp-containers:
	@echo Starting db container...
	@docker run -d --rm --name ${project}_temp_db --env-file ./.env.example -p 5432:5432 postgres:13-alpine
	@echo Starting cache container...
	@docker run -d --rm --name ${project}_temp_cache -p 11211:11211 memcached:1-alpine

.PHONY: start # Start development Web server (with database and cache)
start: prepare-temp-containers
	@sleep 1
	@bash -c "trap \
	            'echo && echo Stopping db and cache containers...; \
	            docker stop ${project}_temp_db; \
	            docker stop ${project}_temp_cache' \
	          EXIT; \
	          echo Initializing database... && \
	          env PIPENV_DOTENV_LOCATION=.env.example pipenv run python -m ${project}.init_db && \
	          echo Starting application... && \
	          env PIPENV_DOTENV_LOCATION=.env.example pipenv run uvicorn ${project}.main:app --reload"

.PHONY: db # Start Postgres and Memcached containers
db: prepare-temp-containers
	@bash -c "trap \
	            'echo && echo Stopping db and cache containers...; \
	            docker stop ${project}_temp_db; \
	            docker stop ${project}_temp_cache' \
	          EXIT; \
	          echo Press CTRL+C to stop && \
	          sleep 1d"

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

.PHONY: up-prod
up-prod:
	docker-compose -f docker-compose.prod.yml up --build --detach

.PHONY: down-prod
down-prod:
	docker-compose -f docker-compose.prod.yml down

## https://stackoverflow.com/a/45843594/6475258
.PHONY: help # Print list of targets with descriptions
help:
	@grep '^.PHONY: .* #' $(lastword $(MAKEFILE_LIST)) | sed 's/\.PHONY: \(.*\) # \(.*\)/\1	\2/' | expand -t20

## https://stackoverflow.com/a/26339924/6475258
# .PHONY: list # Print list of targets
# list:
# 	@LC_ALL=C $(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
