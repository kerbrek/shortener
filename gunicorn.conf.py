import multiprocessing
import os

WORKERS_DEFAULT = multiprocessing.cpu_count() * 2 + 1

bind = "0.0.0.0:8000"
workers = int(os.environ.get("WORKERS", WORKERS_DEFAULT))
worker_class = "uvicorn.workers.UvicornWorker"
