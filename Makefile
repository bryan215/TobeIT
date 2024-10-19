SHELL=/bin/bash
DOCKER_NAME_GRAFANA	= grafana-personalizado:latest
DOCKER_NAME_PERCONA = percona-personalizado:latest
GRAFANA_POD_NAME = $(shell kubectl get pods -n grafana -l app=grafana -o jsonpath='{.items[0].metadata.name}')
PERCONA_POD_NAME = $(shell kubectl get pods -n bbdd -l app=percona -o jsonpath='{.items[0].metadata.name}')

default: help ;


help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' Makefile | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
## start proyect
build: is-minikube-running docker-build deploy-grafana deploy-percona ps-grafana ps-percona


#### Minikube ###
run-minikube:
	@minikube start

is-minikube-running:
	@if ! minikube status | grep -q "host: Running"; then \
		$(MAKE) run-minikube; \
	else \
		echo "Minikube ya está en ejecución."; \
	fi

deploy-grafana:
	@kubectl apply -f Grafana/grafana.yml -n grafana
delete-deploy-grafana:
	@kubectl delete -f Grafana/grafana.yml -n grafana

ps-grafana:
	@kubectl get pods -n grafana

grafana-logs:
	@kubectl logs $(GRAFANA_POD_NAME) -n grafana

deploy-percona:
	@kubectl apply -f Mysql/percona.yml -n bbdd
delete-deploy-percona:
	@kubectl delete -f Mysql/percona.yml -n bbdd
ps-percona:
	@kubectl get pods -n bbdd
percona-logs:
	@kubectl logs $(PERCONA_POD_NAME) -n bbdd


### 🐋 Docker 🐋 ###
docker-build: docker-build-grafana docker-build-percona
docker-build-grafana: ## docker-build
	@eval $$(minikube docker-env) && docker build -f ./Grafana/Dockerfile -t $(DOCKER_NAME_GRAFANA) --no-cache  .
	
docker-build-percona: ## docker-build
	@eval $$(minikube docker-env) && docker build -t $(DOCKER_NAME_PERCONA) -f ./Mysql/Dockerfile --no-cache .





