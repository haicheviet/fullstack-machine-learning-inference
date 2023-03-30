build-infra:
	. ./.env && ./scripts/deploy.sh

build-local:
	echo "Note: set environment REDIS_HOST to redis"
	. ./.env && export DOCKER_IMAGE_APP=app && \
	bash scripts/build.sh && \
	docker compose up -d --force-recreate

	echo "Service is on http://localhost:2000/"

delete-infra:
	echo "Warning: Will delete all infra in 3s"
	sleep 3
	. ./.env
	./scripts/deploy.sh delete