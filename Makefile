IMAGE_NAME  = valheim-base
GHCR_USER   = wkalescky
BASE_IMAGE  = ghcr.io/$(GHCR_USER)/valheim-base
ECS_IMAGE   = ghcr.io/$(GHCR_USER)/valheim-server
GIT_SHA    := $(shell git rev-parse --short HEAD)

COMPOSE   = sudo docker compose -f docker/base/docker-compose.yml
TF_DIR    = terraform
TERRAFORM = terraform -chdir=$(TF_DIR)

export AWS_DEFAULT_REGION = us-west-2

.PHONY: build build-base build-ecs deploy plan start ghcr-login runit

build: build-base build-ecs

runit:
	$(COMPOSE) up -d
	$(COMPOSE) exec valheim /bin/bash

build-base:
	sudo docker buildx build \
		--no-cache \
		--platform linux/amd64 \
		--push \
		-t $(BASE_IMAGE):latest \
		-t $(BASE_IMAGE):$(GIT_SHA) \
		-f docker/base/Dockerfile \
		docker/base

build-ecs:
	sudo docker buildx build \
		--platform linux/amd64 \
		--push \
		-t $(ECS_IMAGE):latest \
		-t $(ECS_IMAGE):$(GIT_SHA) \
		-f docker/ecs/Dockerfile \
		docker/ecs

deploy: build
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
