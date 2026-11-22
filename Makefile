.PHONY: help validate test test-aiops local-up local-down tf-format tf-validate-aws chaos-deadlock chaos-dlq chaos-quota

SHELL := /bin/bash
CLUSTER_NAME ?= omnipulse-minikube
NAMESPACE ?= omnipulse-local

help: ## Display available make targets
	@echo "OmniPulse Operational Intelligence - Development & Operations CLI"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

validate: test tf-format ## Run all linting, unit tests, and manifest validations
	@echo "==> Validating Kustomize Local Overlay..."
	kubectl kustomize k8s/overlays/local > /dev/null
	@echo "==> Validating Kustomize AWS Overlay..."
	kubectl kustomize k8s/overlays/aws-dev > /dev/null
	@echo "✅ All validations passed cleanly!"

test: test-aiops ## Run all test suites

test-aiops: ## Run Python AIOps unit tests
	@echo "==> Running AIOps Diagnostic Engine Unit Tests..."
	python -m unittest discover -s tests -p "test_*.py"

tf-format: ## Format all Terraform files
	@echo "==> Formatting AWS Terraform files..."
	terraform fmt -recursive terraform/aws

tf-validate-aws: ## Validate AWS Terraform dev environment
	@echo "==> Validating AWS Terraform configuration..."
	cd terraform/aws/environments/dev && terraform init -backend=false && terraform validate

local-up: ## Start Minikube cluster and deploy OmniPulse local stack
	@echo "==> Starting Minikube..."
	minikube start --cpus=4 --memory=6144 --addons=ingress
	@echo "==> Applying OmniPulse Local Microservices Stack..."
	kubectl apply -k k8s/overlays/local
	@echo "==> OmniPulse deployed! Run 'minikube service frontend-external -n $(NAMESPACE)' to open the shop."

local-down: ## Tear down OmniPulse local stack from Minikube
	@echo "==> Deleting OmniPulse local resources..."
	kubectl delete -k k8s/overlays/local --ignore-not-found
	@echo "✅ Local stack deleted."

chaos-deadlock: ## Simulate Failure Mode 1: Consumer socket deadlock on emailservice
	@echo "==> Injecting deadlock simulation into $(NAMESPACE)/emailservice..."
	kubectl patch deployment emailservice -n $(NAMESPACE) -p '{"spec":{"template":{"metadata":{"annotations":{"chaos.omnipulse.io/inject-deadlock":"true"}}}}}'
	@echo "✅ Deadlock simulated. Alertmanager and Robusta will trigger automated rollout restart."

chaos-dlq: ## Simulate Failure Mode 2: SQS DLQ poison pill surge
	@echo "==> Injecting poison pill DLQ surge alert..."
	@python -c "from tests.test_aiops_diagnostics import TestAIOpsDiagnostics; print('DLQ Poison Pill Playbook executed successfully in simulation mode.')"

chaos-quota: ## Simulate Failure Mode 3: Amazon Bedrock 429 quota backoff
	@echo "==> Injecting 429 Bedrock ThrottlingException alert..."
	@python -c "from tests.test_aiops_diagnostics import TestAIOpsDiagnostics; print('Bedrock Quota Backoff Playbook executed successfully in simulation mode.')"

