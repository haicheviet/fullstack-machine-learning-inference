import re
from enum import Enum

from pydantic import BaseModel


def to_camel(text):
    text = re.sub(r"(_|-)+", " ", text).title().replace(" ", "")
    return text[0].lower() + text[1:]


class CamelModel(BaseModel):
    class Config:
        allow_population_by_field_name = True
        alias_generator = to_camel


class SentimentLabel(str, Enum):
    NEGATIVE: str = "negative"
    NEUTRAL: str = "neutral"
    POSITIVE: str = "positive"


class SentimentResponse(CamelModel):
    sentiment_analyst: SentimentLabel
    text_input: str
