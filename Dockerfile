ARG MODEL_ENV=copy

FROM python:3.10-slim-bullseye as base_img

## Base working dir
WORKDIR /app

# Download model image from S3
FROM base_img AS model-image-download

## Declare aws enviroment
ARG APP_ENV

ENV APP_ENV "$APP_ENV"

ARG S3_DATA_PATH

ENV S3_DATA_PATH "$S3_DATA_PATH"

ARG BUCKET_NAME

ENV BUCKET_NAME "$BUCKET_NAME"

ARG AWS_ACCESS_KEY_ID

ENV AWS_ACCESS_KEY_ID "$AWS_ACCESS_KEY_ID"

ARG AWS_DEFAULT_REGION

ENV AWS_DEFAULT_REGION "$AWS_DEFAULT_REGION"

ARG AWS_SECRET_ACCESS_KEY

ENV AWS_SECRET_ACCESS_KEY "$AWS_SECRET_ACCESS_KEY"

ONBUILD COPY download_model.py ./download_model.py

ONBUILD RUN pip install boto3 tqdm

ONBUILD RUN python download_model.py


# Copy local model image
FROM base_img AS model-image-copy

ONBUILD Add data ./data


# Define general layer download cause the current docker is not support --from=$var
# Ref: https://github.com/moby/buildkit/issues/2717
FROM model-image-$MODEL_ENV AS model-image-general


FROM base_img AS compile-image

RUN echo "deb http://us.archive.ubuntu.com/ubuntu/ precise main universe" >> /etc/apt/source.list

RUN apt-get update -qq && \
    apt-get update -y && \
    apt-get install curl python3-dev -y

# Download rust-chain to install tokenizer
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"

RUN python -m venv /opt/venv
## Make sure we use the virtualenv:
ENV PATH="/opt/venv/bin:$PATH"

## Install Poetry
RUN curl -sSL https://install.python-poetry.org | POETRY_VERSION=1.3.0 POETRY_HOME=/opt/poetry python3 && \
    cd /usr/local/bin && \
    ln -s /opt/poetry/bin/poetry && \
    poetry config virtualenvs.create false --local && \
    poetry config virtualenvs.prefer-active-python true


## Install dependency
COPY pyproject.toml ./pyproject.toml
RUN . /opt/venv/bin/activate && if [ $APP_ENV == 'dev' ] ; then poetry install --no-root ; else poetry install --no-root --only main ; fi


# Last layer will use to serve API
FROM base_img AS runtime-image

COPY --from=compile-image /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY --from=model-image-general /app /app

COPY gunicorn_conf.py ./gunicorn_conf.py

ADD app ./app

ENV PORT 2000
ENV LOG_LEVEL info
ENV TIMEOUT 120
ENV MAX_REQUESTS 300
CMD gunicorn -k uvicorn.workers.UvicornWorker -c gunicorn_conf.py app.main:app
