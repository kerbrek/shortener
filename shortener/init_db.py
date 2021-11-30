from . import database, models


def create_tables():
    models.Base.metadata.create_all(bind=database.engine)


def drop_tables():
    models.Base.metadata.drop_all(bind=database.engine)


if __name__ == "__main__":
    create_tables()
    database.engine.dispose()
