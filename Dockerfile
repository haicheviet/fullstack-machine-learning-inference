FROM python:3.10-slim-bullseye as base_img

# Base working dir
WORKDIR /app


FROM base_img AS download-model-image

# Declare aws enviroment
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

COPY download_model.py ./download_model.py

RUN pip install boto3 tqdm

RUN python download_model.py


FROM base_img AS compile-image

RUN echo "deb http://us.archive.ubuntu.com/ubuntu/ precise main universe" >> /etc/apt/source.list

RUN apt-get update -qq && \
    apt-get update -y && \
    apt-get install curl build-essential python3-dev  -y

# Download rust-chain to install tokenizer
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"

RUN cargo --version

RUN python -m venv /opt/venv
# Make sure we use the virtualenv:
ENV PATH="/opt/venv/bin:$PATH"

# Install Poetry
RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | POETRY_HOME=/opt/poetry python && \
    cd /usr/local/bin && \
    ln -s /opt/poetry/bin/poetry && \
    poetry config virtualenvs.create false

# Install dependency
COPY pyproject.toml ./pyproject.toml

RUN bash -c "if [ $APP_ENV == 'dev' ] ; then poetry install --no-root ; else poetry install --no-root --no-dev ; fi"


# Last layer will use to serve API
FROM base_img AS runtime-image

COPY --from=compile-image /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY --from=download-model-image /app /app

COPY gunicorn_conf.py ./gunicorn_conf.py

ADD app ./app

ENV PORT 2000
ENV LOG_LEVEL info
ENV TIMEOUT 120
ENV MAX_REQUESTS 300
CMD gunicorn -k uvicorn.workers.UvicornWorker -c gunicorn_conf.py app.main:app
