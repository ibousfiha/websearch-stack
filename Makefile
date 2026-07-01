DOCKER := docker compose

.PHONY: up down stop restart logs pull ps build rebuild

up:      ## Start the stack and wait for all health checks to pass
	$(DOCKER) up --wait

down:    ## Stop and remove containers, networks, and volumes
	$(DOCKER) down

stop:    ## Stop running containers without removing them
	$(DOCKER) stop

restart: ## Restart the stack
	$(DOCKER) restart

logs:    ## Tail logs from all services
	$(DOCKER) logs -f

pull:    ## Pull latest images for all services
	$(DOCKER) pull

ps:      ## Show container status
	$(DOCKER) ps

build:   ## Build the SearXNG image (no pull, local Dockerfile only)
	$(DOCKER) build

rebuild: ## Pull latest images, rebuild SearXNG, then start healthy
	$(DOCKER) pull --ignore-pull-failures
	$(DOCKER) build
	$(DOCKER) up -d --wait

# ── Help ──────────────────────────────────────────────────
help:    ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'
