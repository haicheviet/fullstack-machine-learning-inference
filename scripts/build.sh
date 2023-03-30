#! /usr/bin/env sh

# Exit in case of error
set -e

TAG=${TAG:-latest}
DOCKER_IMAGE_APP=${DOCKER_IMAGE_APP?Variable-not-set}
S3_DATA_PATH=${S3_DATA_PATH}
BUCKET_NAME=${BUCKET_NAME}
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

if [[ -z "${S3_DATA_PATH}" ]]; then
    MODEL_ENV="copy"
else
    MODEL_ENV="download"
fi

docker pull $DOCKER_IMAGE_APP:model-image-stage-$TAG || true
docker pull $DOCKER_IMAGE_APP:compile-stage-$TAG || true
docker pull $DOCKER_IMAGE_APP:$TAG_LATEST || true


# Build the download data stage:
docker build --file Dockerfile \
    --target model-image-general \
    --label git-commit=$CI_COMMIT_SHORT_SHA \
    --build-arg APP_ENV="$APP_ENV" \
    --build-arg MODEL_ENV="$MODEL_ENV" \
    --build-arg S3_DATA_PATH="$S3_DATA_PATH" \
    --build-arg BUCKET_NAME="$BUCKET_NAME" \
    --build-arg AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    --build-arg AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
    --build-arg AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    --tag $DOCKER_IMAGE_APP:model-image-stage-$TAG  .

# Build the compile stage:
docker build --file Dockerfile \
    --target compile-image \
    --label git-commit=$CI_COMMIT_SHORT_SHA \
    --build-arg APP_ENV="$APP_ENV" \
    --build-arg S3_DATA_PATH="$S3_DATA_PATH" \
    --build-arg BUCKET_NAME="$BUCKET_NAME" \
    --build-arg AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    --build-arg AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
    --build-arg AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    --cache-from $DOCKER_IMAGE_APP:compile-stage-$TAG \
    --cache-from $DOCKER_IMAGE_APP:model-image-stage-$TAG \
    --tag $DOCKER_IMAGE_APP:compile-stage-$TAG .

# Build the runtime stage, using cached compile stage:
docker build --file Dockerfile \
    --target runtime-image \
    --label git-commit=$CI_COMMIT_SHORT_SHA \
    --build-arg APP_ENV="$APP_ENV" \
    --build-arg S3_DATA_PATH="$S3_DATA_PATH" \
    --build-arg BUCKET_NAME="$BUCKET_NAME" \
    --build-arg AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    --build-arg AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
    --build-arg AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    --cache-from $DOCKER_IMAGE_APP:compile-stage-$TAG \
    --cache-from $DOCKER_IMAGE_APP:model-image-stage-$TAG \
    --cache-from $DOCKER_IMAGE_APP:$TAG \
    --tag $DOCKER_IMAGE_APP:$TAG .
