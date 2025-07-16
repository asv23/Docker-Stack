# Переменные
REGISTRY := 192.168.10.182:5000
SUBMODULES_DIR := libs
COMPOSE_FILE := docker-compose.yml
STACK_NAME := nginxstack

DOCKER_BUILDKIT ?= 1

# Путь к сабмодулям
FASTAPI_PATH ?= ./libs/MyPyServer
ASPNET_PATH ?= ./libs/MyCSharpServer

# Названия образов
FASTAPI_IMAGE_NAME ?= fastapi-swarm-test
ASPNET_IMAGE_NAME ?= aspnet-swarm-test

# Цветной вывод для удобства
# GREEN := \033[0;32m
# RED := \033[0;31m
# RESET := \033[0m

# По умолчанию выводим помощь
.PHONY: help
help:
	@echo "Доступные команды:"
	@echo "  make build-submodules    - Собрать образы из подмодулей"
	@echo "  make push-submodules     - Загрузить образы в локальный registry"
	@echo "  make stack-deploy        - Запустить все сервисы стэка"
	@echo "  make stack-down          - Остановить все сервисы стэка"
	@echo "  make stop-service        - Остановить перечисленные службы (укажите SERVICE_LIST)"
	@echo "Пример: make stop-service stack_name SERVICE_LIST='service1 service2'"

# Сборка buildx
.PHONY: buildx-push
buildx-push:
	@echo "Сборка образов Docker Buildx..."
	@if [ -z "$(REGISTRY)"]; then \
		echo "Сборка без REGISTRY"; \
		DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) docker buildx build --tag $(FASTAPI_IMAGE_NAME) $(FASTAPI_PATH) --file $(FASTAPI_PATH)/Dockerfile; \
		DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) docker buildx build --tag $(ASPNET_IMAGE_NAME) $(ASPNET_PATH) --file $(ASPNET_PATH)/Dockerfile; \
	else \
		echo "Сборка с REGISTRY"; \
		DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) docker buildx build --tag $(REGISTRY)/$(FASTAPI_IMAGE_NAME) $(FASTAPI_PATH) --file $(FASTAPI_PATH)/Dockerfile --push; \
		DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) docker buildx build --tag $(REGISTRY)/$(ASPNET_IMAGE_NAME) $(ASPNET_PATH) --file $(ASPNET_PATH)/Dockerfile --push; \
	fi

# Запуск всех сервисов стэка
.PHONY: stack-deploy
stack-deploy:
	@echo "Запуск служб..."
	docker stack deploy -c $(COMPOSE_FILE) $(STACK_NAME) --with-registry-auth
	@echo "Все службы запущены."

# Остановка всех сервисов стэка
.PHONY: stack-down
stack-down:  
	@echo "Остановка всех служб..."
	docker stack rm $(STACK_NAME)
	@echo "Все службы остановлены."

# # Остановка перечисленных служб
.PHONY: stop-services
stop-service:
	@if [ -z "$(SERVICE_LIST)" ]; then \
		echo "Ошибка: SERVICE_LIST не определен. Использование: make stop-service SERVICE_LIST='service1 service2'"; \
		exit 1; \
	fi; \
	for service in $(SERVICE_LIST); do \
		echo "Остановка сервиса: nginxstack_$${service}"; \
		docker service rm nginxstack_$${service} || echo "Сервис nginxstack_$${service} не найден или уже остановлен"; \
	done