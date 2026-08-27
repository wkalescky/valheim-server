IMAGE_NAME = valheim-base
TAG = latest

COMPOSE = sudo docker compose -f docker/base/docker-compose.yml

build:
	$(COMPOSE) build

runit:
	$(COMPOSE) up -d
	$(COMPOSE) exec valheim /bin/bash

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
