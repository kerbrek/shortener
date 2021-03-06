import multiprocessing
import os

from pymemcache.client.base import PooledClient
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

WORKERS_DEFAULT = multiprocessing.cpu_count() * 2 + 1
WORKERS = int(os.environ.get("WORKERS", WORKERS_DEFAULT))

DB_URL_TEMPLATE = "postgresql://{user}:{password}@{host}:{port}/{database}"
DB_URL = DB_URL_TEMPLATE.format(
    user=os.environ["POSTGRES_USER"],
    password=os.environ["POSTGRES_PASSWORD"],
    host=os.environ["POSTGRES_HOST"],
    port=os.environ["POSTGRES_PORT"],
    database=os.environ["POSTGRES_DB"],
)

DB_MAX_CONNECTIONS = int(os.environ.get("DB_MAX_CONNECTIONS", 100))
POOL_SIZE_DEFAULT = DB_MAX_CONNECTIONS // WORKERS

POOL_SIZE = int(os.environ.get("SQLALCHEMY_POOL_SIZE", POOL_SIZE_DEFAULT))
MAX_OVERFLOW = int(os.environ.get("SQLALCHEMY_MAX_OVERFLOW", 0))
POOL_TIMEOUT = float(os.environ.get("SQLALCHEMY_POOL_TIMEOUT", 30.0))
ECHO = bool(int(os.environ.get("DEBUG", 0)))

engine = create_engine(
    DB_URL,
    pool_size=POOL_SIZE,
    max_overflow=MAX_OVERFLOW,
    pool_timeout=POOL_TIMEOUT,
    echo=ECHO
)
session = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

CACHE_HOST = os.environ["MEMCACHED_HOST"]
CACHE_PORT = os.environ["MEMCACHED_PORT"]
CACHE_MAX_CONNECTIONS = int(os.environ.get("CACHE_MAX_CONNECTIONS", 1024))
CACHE_MAX_POOL_SIZE_DEFAULT = CACHE_MAX_CONNECTIONS // WORKERS

CACHE_MAX_POOL_SIZE = int(os.environ.get(
    "CACHE_MAX_POOL_SIZE",
    CACHE_MAX_POOL_SIZE_DEFAULT
))

cache = PooledClient(
    f"{CACHE_HOST}:{CACHE_PORT}",
    max_pool_size=CACHE_MAX_POOL_SIZE
)
