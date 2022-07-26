from tweepy import models


def prefixed_key(f):
    """
    A method decorator that prefixes return values.
    Prefixes any string that the decorated method `f` returns with the value of
    the `prefix` attribute on the owner object `self`.
    """

    def prefixed_method(*args, **kwargs):
        self = args[0]
        key = f(*args, **kwargs)
        return f"{self.prefix}:{key}"

    return prefixed_method


class Keys:
    def __init__(self, tweet: models.Status):
        self.prefix = self.generate_prefix(tweet)

    @staticmethod
    def generate_prefix(tweet: models.Status):
        return f"{tweet.author.id}:{tweet.id}"

    @prefixed_key
    def cache_key(self) -> str:
        """A time series containing 30-second snapshots of BTC sentiment."""
        return "sentiment"
