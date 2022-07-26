import json
import logging
import time
from logging.config import dictConfig

from fastapi import FastAPI, Request

from app.api.api_v1.api import api_router
from app.config import settings
from app.core import get_model, get_tokenizer
from app.logger import DEFAULT_LOGGER

dictConfig(DEFAULT_LOGGER)

app = FastAPI(
    title=settings.PROJECT_NAME, openapi_url=f"{settings.API_V1_STR}/openapi.json"
)
app.logger = logging.getLogger(__name__)  # type: ignore


@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.perf_counter()
    response = await call_next(request)
    process_time = time.perf_counter() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response


model_params = {
    "model": get_model(),
    "tokenizer": get_tokenizer(),
}
app.model_params = model_params  # type: ignore
app.logger.info("Done loading model")  # type: ignore


# Register api router with app
app.include_router(api_router, prefix=settings.API_V1_STR)


@app.get("/")
async def read_item(request: Request):
    return {"statusCode": 200, "body": json.dumps({"message": "OK"})}
