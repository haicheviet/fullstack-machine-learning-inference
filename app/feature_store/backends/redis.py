from typing import Tuple

from aioredis import Redis

from app.feature_store.backends import Backend


class RedisBackend(Backend):
    def __init__(self, redis: Redis):
        self.redis = redis

    async def get_with_ttl(self, key: str) -> Tuple[int, str]:
        p = self.redis.pipeline()
        p.ttl(key)
        p.get(key)
        return await p.execute()

    async def get(self, key) -> str:
        return await self.redis.get(key)

    async def set(self, key: str, value: str, expire: int = None):
        return await self.redis.set(key, value, expire=expire)

    async def clear(self, namespace: str = None, key: str = None) -> int:
        if namespace:
            lua = (
                "local foo = {}"
                f"for i, name in ipairs(redis.call('KEYS', '{namespace}:*')) "
                "do table.insert(foo,redis.call('DEL', name)); end; return foo"
            )
            return await self.redis.eval(lua)
        elif key:
            return await self.redis.delete(key)
        else:
            return await self.redis.flushdb()
