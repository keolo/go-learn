.PHONY: install setup get open sh logs ls delete manifest clean help
.DEFAULT_GOAL := help

APP := go-learn
RELEASE := $(APP)-local
APP_POD := $(shell kubectl get pods --namespace $(APP) -o \
	jsonpath='{.items[*].metadata.name}')
PWD := $(shell pwd)

install: ## Install application
	@eval $$(minikube docker-env) \
		&& helm init

	eval $$(minikube docker-env) \
		&& docker build -t keolo/$(APP):latest -f Dockerfile . \
		&& helm install $(APP) --name $(RELEASE) --namespace $(APP) --replace

	@make clean

	@kubectl get -w pods --namespace $(APP)

test: ## Run test suite
	@kubectl exec $(APP_POD) rspec

get: ## Get running resources
	kubectl get pods,services,rs,deployments,pvc,pv,secrets --namespace $(APP)

open: ## Open application in the browser
	minikube service $(RELEASE) --namespace $(APP)

sh: ## Shell into application pod
	@kubectl exec -it $(APP_POD) bash

logs: ## Tail application logs
	kubectl logs -f $(APP_POD) --namespace $(APP)

restart: ## Delete pod (which will automatically start another one)
	kubectl delete pod $(APP_POD) --namespace $(APP)

ls: ## List deployments
	helm ls

delete: ## Delete deployment
	helm delete --purge $(RELEASE)

manifest: ## Get the compiled manifest for this application
	helm get manifest $(RELEASE)

clean: ## Remove dangling docker images
	@eval $$(minikube docker-env) \
		&& docker images -qf dangling=true | xargs docker rmi

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; \
		{printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
