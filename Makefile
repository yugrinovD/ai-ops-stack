SHELL := /usr/bin/env bash
COMPOSE ?= docker compose

.PHONY: help init-env up down reset pull-model keys smoke smoke-fallback \
        config logs ps

help:
	@echo "AI Ops Stack"
	@echo "  make init-env       generate .env and empty .secrets/runtime.env"
	@echo "  make up             pull the model, start the stack and create gateway keys"
	@echo "  make pull-model     pull the pinned model"
	@echo "  make keys           create/verify gateway keys"
	@echo "  make smoke          end-to-end health + upload + explain (expects LLM)"
	@echo "  make smoke-fallback stop gogate and verify heuristic fallback"
	@echo "  make config         validate docker-compose.yml"
	@echo "  make logs           follow stack logs"
	@echo "  make ps             show service status"
	@echo "  make down           stop the stack, keep volumes"
	@echo "  make reset          stop the stack and delete volumes and generated keys"

init-env:
	./scripts/init-env.sh

up: init-env
	@# One compose pass: gogate waits for ollama-pull; lmlog starts in
	@# heuristic mode until the gateway key is created below.
	$(COMPOSE) up -d --build
	./scripts/bootstrap-keys.sh
	$(COMPOSE) up -d --force-recreate lmlog-api ops-console
	@set -a; . ./.env; set +a; \
	echo; \
	echo "ops-console: http://localhost:$${CONSOLE_PORT:-3100}"; \
	echo "gogate:      http://localhost:$${GOGATE_HTTP_PORT:-8080}/v1"; \
	echo "lmlog:       http://localhost:$${LMLOG_SERVE_PORT:-8090}/healthz"

pull-model: init-env
	$(COMPOSE) run --rm ollama-pull

keys: init-env
	./scripts/bootstrap-keys.sh

smoke:
	SMOKE_REQUIRE_LLM=$${SMOKE_REQUIRE_LLM:-1} ./scripts/smoke.sh

smoke-fallback:
	./scripts/smoke-fallback.sh

config: init-env
	$(COMPOSE) config -q
	@echo "compose config is valid"

logs:
	$(COMPOSE) logs -f --tail=200

ps:
	$(COMPOSE) ps

down: init-env
	$(COMPOSE) down --remove-orphans

reset: init-env
	$(COMPOSE) down -v --remove-orphans
	rm -rf .secrets
	./scripts/init-env.sh
	@echo "volumes and generated gateway keys removed; .env kept"
