NAME = xyz27900/rtsp2hls

.PHONY: docker-build
docker-build:
	docker build -t $(NAME) .

.PHONY: docker-compose
docker-compose:
	docker-compose up --build -d

.PHONY: exec
exec:
	docker container exec -it $$(docker ps -aqf "name=$(NAME)") /bin/bash

.PHONY: logs
logs:
	docker-compose logs -f
