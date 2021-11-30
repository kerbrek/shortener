from sqlalchemy import Column, DateTime, Sequence, String, func

from .database import Base


class Short(Base):
    __tablename__ = "shorts"

    shorts_id_seq = Sequence("shorts_id_seq", metadata=Base.metadata)

    base64_id = Column(String(50), primary_key=True)
    url = Column(String(2083), nullable=False)
    created_at = Column(DateTime, server_default=func.now())
