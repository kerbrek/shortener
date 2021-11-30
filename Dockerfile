# For more information, please refer to https://aka.ms/vscode-docker-python
FROM python:3.9-slim-bullseye
EXPOSE 8000

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1

# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install pip requirements
COPY Pipfile.lock .
RUN python -m pip install --no-cache-dir pipfile-requirements && \
    pipfile2req > requirments.txt && \
    python -m pip install --no-cache-dir -r requirments.txt

COPY . /app

# Creates a non-root user with an explicit UID and adds permission to access the /app folder
# For more info, please refer to https://aka.ms/vscode-docker-python-configure-containers
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

ENTRYPOINT ["/app/entrypoint.sh"]

CMD ["gunicorn", "--config", "./gunicorn.conf.py", "shortener.main:app"]
