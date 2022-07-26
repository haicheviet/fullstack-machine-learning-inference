import json
from typing import Dict, Optional

from app.feature_store.backends import Backend
from app.feature_store.key_builder import Keys

SIXTY_DAYS = 60 * 60 * 60 * 60


async def set_cache(data, keys: Keys, feature_store: Backend):
    await feature_store.set(
        keys.cache_key(),
        json.dumps(data),
        expire=SIXTY_DAYS,
    )


async def get_cache(keys: Keys, feature_store: Backend) -> Optional[Dict]:
    data = await feature_store.get(keys.cache_key())
    if data:
        return json.loads(data)
    return None
