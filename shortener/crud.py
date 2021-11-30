import sqlalchemy.exc
from sqlalchemy.orm import Session

from . import models, schemas


def get_next_id(db: Session):
    return db.scalar(models.Short.shorts_id_seq.next_value())


def get_short(db: Session, base64_id: str):
    return db.get(models.Short, base64_id)


def create_short(db: Session, short: schemas.ShortInDB):
    db_short = models.Short(**short.dict())
    try:
        db.add(db_short)
        db.commit()
        db.refresh(db_short)
    except sqlalchemy.exc.IntegrityError:
        db.rollback()
        db_short = None

    return db_short
