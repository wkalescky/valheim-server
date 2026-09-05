IMAGE_NAME  = valheim-base
TAG         = latest
GHCR_USER   = wkalescky
ECS_IMAGE   = ghcr.io/$(GHCR_USER)/valheim-server
GIT_SHA    := $(shell git rev-parse --short HEAD)

COMPOSE = sudo docker compose -f docker/base/docker-compose.yml
TF_DIR = terraform
TF_SUBCMD = $(word 2,$(MAKECMDGOALS))
TERRAFORM = terraform -chdir=$(TF_DIR)
AWS_ENV_FILE = /tmp/.aws-valheim-env

build:
	$(COMPOSE) build

runit:
	$(COMPOSE) up -d
	$(COMPOSE) exec valheim /bin/bash

build-ecs:
	sudo docker buildx build \
		--platform linux/amd64 \
		--push \
		-t $(ECS_IMAGE):latest \
		-t $(ECS_IMAGE):$(GIT_SHA) \
		-f docker/ecs/Dockerfile \
		docker/ecs

ghcr-login:
	gh auth token | sudo docker login ghcr.io -u $(GHCR_USER) --password-stdin

aws-login:
	aws login
	aws configure export-credentials --format env > $(AWS_ENV_FILE)

tf:
	. $(AWS_ENV_FILE) && $(TERRAFORM) $(TF_SUBCMD)

%:
	@:

# xbuild:
# 	sudo docker buildx build -t $(IMAGE_NAME):$(TAG) --platform linux/amd64 .

# interactive:
# 	sudo docker run \
# 		-p 2456/tcp \
# 		-p 2456/udp \
# 		-p 2457/udp \
# 		-it --user steam --platform linux/amd64 $(IMAGE_NAME):$(TAG) /bin/bash

# arm:
# 	sudo docker run -it --user steam --platform linux/amd64 -e CPU_MHZ=2500 $(IMAGE_NAME):$(TAG) /bin/bash
