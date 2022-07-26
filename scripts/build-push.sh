#! /usr/bin/env sh

# Exit in case of error
set -e

TAG=${TAG?Variable not set}
sh ./scripts/build.sh

docker push $DOCKER_IMAGE_APP:$TAG