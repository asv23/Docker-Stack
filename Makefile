# Переменные
REGISTRY := 192.168.10.182:5000
SUBMODULES_DIR := libs
COMPOSE_FILE := docker-compose.yml
STACK_NAME := nginxstack

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

# Сборка образов из подмодулей
.PHONY: build-submodules
build-submodules:
	@echo "Сборка образов из подмодулей..."
	@for dir in $(SUBMODULES_DIR)/*; do \
		echo "Путь $$dir"; \
		if [ -d "$$dir" ] && [ -f "$$dir/docker-compose.yml" ]; then \
			echo "Сборка образа для $$dir..."; \
			image_name=$$(grep 'image:' "$$dir/docker-compose.yml" | head -1 | awk '{print $\$2}' | sed 's|${REGISTRY}/||' | sed 's|$$(REGISTRY)/||'); \
			echo "Image $$image_name"; \
			if [ -z "$$image_name" ]; then \
				echo "Ошибка: Не удалось извлечь image_name для $$dir"; \
				exit 1; \
			fi; \
			REGISTRY=$(REGISTRY) docker compose -f "$$dir/docker-compose.yml" build --no-cache || { echo "Ошибка сборки для $$dir"; exit 1; }; \
		elif [ -d "$$dir" ]; then \
			echo "Путь: $$dir (docker-compose.yml не найден)"; \
		fi; \
	done
	@echo "Сборка завершена."

# Загрузка образов в локальный registry
.PHONY: push-submodules
push-submodules:
	@if ! docker images --format '{{.Repository}}:{{.Tag}}' --filter=reference='$(REGISTRY)/*' | grep -q .; then \
		echo "Ошибка: Нет образов для загрузки в $(REGISTRY)"; \
		exit 1; \
	fi
	@docker images --format '{{.Repository}}:{{.Tag}}' --filter=reference='$(REGISTRY)/*' | \
	while read image; do \
		echo "Загрузка: $$image"; \
		docker push "$$image" || exit 1; \
	done
	@echo "✅ Все образы успешно загружены в $(REGISTRY)"

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