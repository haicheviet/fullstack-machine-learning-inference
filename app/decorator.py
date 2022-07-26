from functools import wraps


def async_log_response(f):
    @wraps(f)
    async def decorated(*args, **kwargs):
        result = await f(*args, **kwargs)
        parameters = {k: v for k, v in kwargs.items() if k != "request"}
        kwargs["request"].app.logger.info(
            f"{f.__name__}_{parameters}: response: {result}"
        )

        return result

    return decorated
