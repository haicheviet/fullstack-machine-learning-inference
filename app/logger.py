import os

LOGGER_DIR = os.getenv("LOGGER_DIR", "logs")
if not os.path.exists(LOGGER_DIR):
    os.makedirs(LOGGER_DIR)
level_log = "DEBUG"
format_log = (
    "%(asctime)s [%(threadName)-12.12s] "
    "[%(levelname)-5.5s] "
    "%(filename)s:%(funcName)s:%(lineno)d: %(message)s"
)


DEFAULT_LOGGER = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {"standard": {"format": format_log}},
    "handlers": {
        "api": {
            "level": "INFO",
            "class": "logging.StreamHandler",
            "formatter": "standard",
        },
        "model_log": {
            "level": level_log,
            "class": "logging.handlers.TimedRotatingFileHandler",
            "filename": "{}/{}".format(LOGGER_DIR, "model_log.log"),
            "formatter": "standard",
            "when": "d",
            "interval": 1,
            "backupCount": 5,
        },
    },
    "loggers": {
        "app.main": {"handlers": ["api"], "level": level_log},
        "app.core": {
            "handlers": ["model_log"],
            "level": level_log,
        },
    },
}
