#!/bin/bash

./docker/wait-for-it.sh "${POSTGRES_HOST}:${POSTGRES_PORT}"
echo Initializing database...
python -m shortener.init_db

exec "$@"
