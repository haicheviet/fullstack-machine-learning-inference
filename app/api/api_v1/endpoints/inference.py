from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException
from pydantic import HttpUrl
from starlette.requests import Request
from tweepy import API

from app.api.deps import get_backend, get_twitter_api
from app.core import TwitterSentiment
from app.decorator import async_log_response
from app.feature_store.backends import Backend
from app.feature_store.core import Keys, get_cache, set_cache
from app.schemas import SentimentResponse

router = APIRouter()


@router.get("/inference", response_model=SentimentResponse)
@async_log_response
async def inference(
    request: Request,
    tweetUrl: HttpUrl,
    background_tasks: BackgroundTasks,
    feature_store: Backend = Depends(get_backend),
    twitter_api: API = Depends(get_twitter_api),
):
    try:
        tweet = twitter_api.get_status(tweetUrl.split("/")[-1])
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error{type(e).__name__}: {e}")
    key = Keys(tweet=tweet)
    data = await get_cache(keys=key, feature_store=feature_store)
    if not data:
        request.app.logger.info("Prediction is not exist in feature store")
        twitter = TwitterSentiment(**request.app.model_params)

        prediction = twitter.prediction(tweet.text)
        if prediction:
            result = SentimentResponse(
                sentiment_analyst=prediction, text_input=tweet.text
            )
            background_tasks.add_task(set_cache, result.dict(), key, feature_store)
        else:
            raise HTTPException(status_code=400, detail="Empty prediction")
    else:
        request.app.logger.info("Prediction hits")
        result = SentimentResponse(**data)

    return result


@router.get("/clear")
async def refresh(prefix: str, feature_store: Backend = Depends(get_backend)):
    flag_clear = await feature_store.clear(namespace=prefix)
    if flag_clear and any(flag_clear):
        return "success"
    return "fail"
