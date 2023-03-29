import time
from functools import wraps


def async_log_response(f):
    @wraps(f)
    async def decorated(*args, **kwargs):
        t0 = time.perf_counter()
        result = await f(*args, **kwargs)
        parameters = {k: v for k, v in kwargs.items() if k != "request"}
        kwargs["request"].app.logger.info(
            f"{f.__name__}_{parameters}: response: {result}"
        )
        kwargs["request"].app.logger.info(
            f"{f.__name__} took: {time.perf_counter() - t0}"
        )

        return result

    return decorated
