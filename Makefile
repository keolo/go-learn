.DEFAULT_GOAL := help

APP := go-learn
CHART := $(APP)
RELEASE := $(APP)-local
APP_POD := $(shell kubectl get pods --namespace $(APP) -o \
	jsonpath='{.items[*].metadata.name}')
PWD := $(shell pwd)
SHA := $(shell git rev-parse --verify --short HEAD)

.PHONY: upgrade
upgrade: ## Install/upgrade application
	@eval $$(minikube docker-env) \
		&& helm init

	eval $$(minikube docker-env) \
		&& docker build -t keolo/$(APP):latest . \
		&& helm upgrade \
			$(RELEASE) \
			$(CHART) \
			--install \
			--repo http://127.0.0.1:8879 \
			--namespace $(APP) \
			--recreate-pods \
			--force \
		&& make restart

	@kubectl get -w pods --namespace $(APP)

.PHONY: test
test: ## Run test suite
	@kubectl exec $(APP_POD) rspec

.PHONY: get
get: ## Get running resources
	kubectl get pods,services,rs,deployments,pvc,pv,secrets --namespace $(APP)

.PHONY: open
open: ## Open application in the browser
	minikube service $(RELEASE) --namespace $(APP)

.PHONY: sh
sh: ## Shell into application pod
	@kubectl exec -it $(APP_POD) sh --namespace $(APP)

.PHONY: logs
logs: ## Tail application logs
	kubectl logs -f $(APP_POD) --namespace $(APP)

.PHONY: restart
restart: ## Delete pod (which will automatically start another one)
	kubectl delete pod $(APP_POD) --namespace $(APP)
	@kubectl get -w pods --namespace $(APP)

.PHONY: ls
ls: ## List deployments
	@helm ls

.PHONY: delete
delete: ## Delete deployment
	helm delete --purge $(RELEASE)
	@make clean

.PHONY: manifest
manifest: ## Get the compiled manifest for this application
	helm get manifest $(RELEASE)

.PHONY: history
history: ## Get the history of this release
	helm history $(RELEASE)

.PHONY: rollback
rollback: ## Rollback to a particular version
	helm rollback go-learn-local --recreate-pods $(VERSION)

.PHONY: clean
clean: ## Remove dangling docker images
	@eval $$(minikube docker-env) \
		&& docker images -qf dangling=true | xargs docker rmi

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; \
		{printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
