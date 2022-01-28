import os

from baseconv import base64
from fastapi import FastAPI, HTTPException, status
from fastapi.responses import RedirectResponse

from . import crud, schemas
from .database import cache, session

BASE_URL = os.environ["SHORTENER_BASE_URL"]

app = FastAPI(docs_url="/docs.html", redoc_url=None)


@app.get("/", response_class=RedirectResponse)
async def redirect_to_docs():
    return "/docs.html"


@app.get(
    "/{short_id}",
    response_class=RedirectResponse,
    responses={404: {"description": "ID not found"}}
)
def read_short(short_id: str):
    cached_url = cache.get(short_id)
    if cached_url:
        return cached_url.decode()

    with session() as db:
        db_short = crud.get_short(db, base64_id=short_id)
        if db_short is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="ID not found"
            )

        cache.set(short_id, db_short.url.encode())
        return db_short.url


@app.post(
    "/",
    response_model=schemas.ShortOut,
    status_code=status.HTTP_201_CREATED,
    responses={409: {"description": "ID already exists"}}
)
def write_short(short_in: schemas.ShortIn):
    with session() as db:
        if not short_in.custom_id:
            db_short = None
            while db_short is None:
                num_id = crud.get_next_id(db=db)
                new_short = schemas.ShortInDB(
                    base64_id=base64.encode(num_id),
                    url=short_in.url
                )
                db_short = crud.create_short(db=db, short=new_short)

            return {"url": f"{BASE_URL}/{db_short.base64_id}"}

        new_short = schemas.ShortInDB(
            base64_id=short_in.custom_id,
            url=short_in.url
        )
        db_short = crud.create_short(db=db, short=new_short)
        if db_short is None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="ID already exists"
            )

        return {"url": f"{BASE_URL}/{db_short.base64_id}"}
