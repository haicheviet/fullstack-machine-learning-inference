import logging
import os
from typing import Optional

import numpy as np
import torch
from scipy.special import softmax
from transformers import AutoTokenizer

from app.config import settings
from app.schemas import SentimentLabel

logger = logging.getLogger(__name__)


LABELS_INDEX = ["negative", "neutral", "positive"]


def get_tokenizer():
    tokenizer = AutoTokenizer.from_pretrained(settings.DATADIR)
    return tokenizer


def get_model():
    model = torch.jit.load(os.path.join(settings.DATADIR, "trace_model.pt"))
    return model


def preprocess(text: str):
    new_text = []

    for t in text.split(" "):
        t = "@user" if t.startswith("@") and len(t) > 1 else t
        t = "http" if t.startswith("http") else t
        new_text.append(t)
    return " ".join(new_text)


class TwitterSentiment:
    def __init__(self, model, tokenizer) -> None:
        self.model = model
        self.tokenizer = tokenizer

    def prediction(self, text: str) -> Optional[SentimentLabel]:
        if not text.strip():
            return None

        text = preprocess(text)
        encoded_input = self.tokenizer(text, return_tensors="pt")
        with torch.no_grad():
            output = self.model(**encoded_input)
        scores = output[0][0].detach().numpy()
        scores = softmax(scores)

        ranking = np.argsort(scores)
        ranking = ranking[::-1]
        prediction = list(
            map(
                lambda i: (LABELS_INDEX[ranking[i]], scores[ranking[i]]),
                range(scores.shape[0]),
            )
        )
        text = text.replace("\n", " ")
        logger.info(f"{text} have prediction: {prediction}")

        return SentimentLabel(prediction[0][0])
