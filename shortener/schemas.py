import re
from typing import Optional

from baseconv import base64
from pydantic import AnyHttpUrl, BaseModel, Field, HttpUrl


class ShortIn(BaseModel):
    url: HttpUrl
    custom_id: Optional[str] = Field(
        None,
        min_length=1,
        max_length=50,
        regex=f"^[{re.escape(base64.digits)}]+$",
    )


class ShortOut(BaseModel):
    url: AnyHttpUrl


class ShortInDB(BaseModel):
    base64_id: str
    url: HttpUrl
