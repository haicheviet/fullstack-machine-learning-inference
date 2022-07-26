from fastapi import APIRouter, Depends

from app.api.api_v1.endpoints import inference
from app.api.deps import get_current_username

api_router = APIRouter()

api_router.include_router(
    inference.router,
    tags=["inference"],
    dependencies=[Depends(get_current_username)],
)
