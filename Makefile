build-infra:
	. ./.env
	./deploy.sh

build-local:
	echo "Note: set environment REDIS_HOST to redis"
	. ./.env
	docker-compose up -d
	echo "Service is on http://localhost:2000/ "

delete-infra:
	echo "Warning: Will delete all infra in about 3s"
	sleep 3
	. ./.env
	./deploy.sh delete