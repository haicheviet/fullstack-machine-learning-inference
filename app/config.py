from pydantic import BaseSettings


class Settings(BaseSettings):
    APP_ENV: str
    API_V1_STR: str = "/v1"
    PROJECT_NAME: str = "ml-template"
    DATADIR: str = "data"
    TWITTER_CONSUMER_KEY: str
    TWITTER_CONSUMER_SECRET: str
    TWITTER_ACCESS_TOKEN_KEY: str
    TWITTER_ACCESS_TOKEN_SECRET: str
    FIRST_SUPERUSER: str
    FIRST_SUPERUSER_PASSWORD: str
    REDIS_HOST: str
    REDIS_PORT: str


settings = Settings()
