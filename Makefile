GHCR_USER   = wkalescky
ECS_IMAGE   = ghcr.io/$(GHCR_USER)/valheim-server
GIT_SHA    := $(shell git rev-parse --short HEAD)

COMPOSE   = sudo docker compose -f docker/ecs/docker-compose.yml
TF_DIR    = terraform
TF_CREDS  := $(shell aws configure export-credentials --format env-no-export 2>/dev/null)
TERRAFORM  = env $(TF_CREDS) terraform -chdir=$(TF_DIR)

export AWS_DEFAULT_REGION = us-west-2

.PHONY: build deploy apply plan start ghcr-login runit exec

build:
	sudo docker buildx build \
		--platform linux/amd64 \
		--push \
		-t $(ECS_IMAGE):latest \
		-t $(ECS_IMAGE):$(GIT_SHA) \
		-f docker/ecs/Dockerfile \
		docker/ecs

runit:
	$(COMPOSE) down --remove-orphans
	$(COMPOSE) up -d --build

exec:
	$(COMPOSE) exec valheim /bin/bash

deploy: build
	$(TERRAFORM) apply

apply:
	$(TERRAFORM) apply

plan:
	$(TERRAFORM) plan

start:
ifndef WORLD
	$(error WORLD is required — usage: make start WORLD=dedicated)
endif
	$(eval SUBNET  := $(shell $(TERRAFORM) output -raw public_subnet_id))
	$(eval SG      := $(shell $(TERRAFORM) output -raw ecs_security_group_id))
	$(eval CLUSTER := $(shell $(TERRAFORM) output -raw ecs_cluster))
	$(eval TASKDEF := $(shell $(TERRAFORM) output -raw ecs_task_definition))
	SUBNET=$(SUBNET) SG=$(SG) CLUSTER=$(CLUSTER) TASKDEF=$(TASKDEF) WORLD=$(WORLD) \
	  bash scripts/start.sh

ghcr-login:
	gh auth token | sudo docker login ghcr.io -u $(GHCR_USER) --password-stdin
