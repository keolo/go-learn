.DEFAULT_GOAL := help

APP := go-learn
CHART := helm-chart
REPOSITORY := iamplus/$(APP)
TAG := latest
RELEASE := $(APP)-local
ENVIRONMENT := development

define app_pod
	$(shell kubectl get pods \
		--namespace $(APP) \
		-l app=$(APP) \
		-o jsonpath='{.items[0].metadata.name}' \
	)
endef

.PHONY: upgrade
upgrade: ## Install/upgrade application
	@eval $$(minikube docker-env) \
		&& helm init

	eval $$(minikube docker-env) \
		&& docker build -t $(REPOSITORY):$(TAG) . \
		&& helm upgrade \
			$(RELEASE) \
			$(CHART) \
			--install \
			--namespace $(APP) \
			--recreate-pods \
			--force \
			--set image.repository=$(REPOSITORY) \
			--set image.tag=$(TAG) \
			--set environment=$(ENVIRONMENT) \
		&& make restart

	@kubectl get -w pods --namespace $(APP)

.PHONY: test
test: ## Run test suite
	kubectl exec $(app_pod) rspec --namespace $(APP)

.PHONY: get
get: ## Get running resources
	kubectl get pods,services,rs,deployments,pvc,pv,secrets --namespace $(APP)

.PHONY: open
open: ## Open application in the browser
	minikube service $(RELEASE) --namespace $(APP)

.PHONY: sh
sh: ## Shell into application pod
	@kubectl exec -it $(app_pod) sh --namespace $(APP)

.PHONY: logs
logs: ## Tail application logs
	kubectl logs -f $(app_pod) --namespace $(APP)

.PHONY: restart
restart: ## Delete application pods (deployments auto-create pods)
	kubectl delete pod --namespace $(APP) -l app=$(APP)
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
	helm rollback $(RELEASE) --recreate-pods $(VERSION)

.PHONY: clean
clean: ## Remove dangling docker images
	@eval $$(minikube docker-env) \
		&& docker images -qf dangling=true | xargs docker rmi -f

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; \
		{printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
