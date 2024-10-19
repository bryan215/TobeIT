SHELL=/bin/bash
DOCKER_NAME_GRAFANA	= grafana-personalizado:latest
DOCKER_NAME_PERCONA = percona-personalizado:latest
DOCKER_NAME_PYTHON =  python-personalizado:latest
GRAFANA_POD_NAME = $(shell kubectl get pods -n grafana -l app=grafana -o jsonpath='{.items[0].metadata.name}')
PERCONA_POD_NAME = $(shell kubectl get pods -n bbdd -l app=percona -o jsonpath='{.items[0].metadata.name}')

default: help ;


help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
## start proyect
build: is-minikube-running docker-build deploy-grafana deploy-percona ps-grafana ps-percona docker-run-python

destroy: delete-deploy-grafana delete-deploy-percona

#### Minikube ###
run-minikube: ##Iniciar Minikube
	@minikube start --driver=docker


is-minikube-running: ## Comprobar si Minikube esta running
	@if ! minikube status | grep -q "host: Running"; then \
		$(MAKE) run-minikube; \
	else \
		echo "Minikube ya está en ejecución."; \
	fi

deploy-grafana: ## Deployar grafana en minikube
	@kubectl apply -f Grafana/grafana.yml -n grafana
delete-deploy-grafana: ## Borrar completamente Grafana en minikube
	@kubectl delete -f Grafana/grafana.yml -n grafana

ps-grafana: ## Visualizar pods en el namespace de Grafana
	@kubectl get pods -n grafana

grafana-logs: ## Visualizar logs del pod de Grafana
	@kubectl logs $(GRAFANA_POD_NAME) -n grafana

deploy-percona: ## Deployar percona en minikube
	@kubectl apply -f Mysql/percona.yml -n bbdd
delete-deploy-percona: ## Borrar completamente percona en minikube
	@kubectl delete -f Mysql/percona.yml -n bbdd
ps-percona: ## Visualizar pod en el namespace de percona
	@kubectl get pods -n bbdd
percona-logs:## Visualizar logs de pod de percona
	@kubectl logs $(PERCONA_POD_NAME) -n bbdd


### 🐋 Docker 🐋 ###
docker-build: docker-build-grafana docker-build-percona docker-build-python ## construir imagenes dockers
docker-build-grafana: ## construir imagen docker grafana
	@eval $$(minikube docker-env) && docker build -f ./Grafana/Dockerfile -t $(DOCKER_NAME_GRAFANA) --no-cache  .
	
docker-build-percona: ### construir imagen docker percona
	@eval $$(minikube docker-env) && docker build -t $(DOCKER_NAME_PERCONA) -f ./Mysql/Dockerfile --no-cache .
docker-build-python: ## construir imagen docker python
	docker build -f ./Scripts/Dockerfile -t $(DOCKER_NAME_PYTHON) --no-cache  .
docker-run-python: check-db ## ejecutar script python
	@eval $(minikube docker-env) && docker run --rm --network host -v $(PWD)/Scripts:/app -w /app $(DOCKER_NAME_PYTHON) python3 fetch_data.py

check-db: ## comprobar si la BBDD esta conectada. 
	@echo "Esperando que la base de datos esté disponible..."
	@until nc -z -v -w30 192.168.49.2 30000; do \
		echo "Esperando..."; \
		sleep 5; \
	done
	@echo "La base de datos está lista."













