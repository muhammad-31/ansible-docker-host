# ENV picks inventories/<ENV>/hosts.yml
ENV ?= example

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

.PHONY: setup
setup: ## Install Python tooling and Ansible collections
	pip install -r requirements-dev.txt
	ansible-galaxy collection install -r requirements.yml

.PHONY: lint
lint: ## yamllint + ansible-lint (production profile)
	yamllint .
	ansible-lint

.PHONY: test
test: ## Full Molecule run: create, converge, idempotence, verify, destroy
	molecule test

.PHONY: converge
converge: ## Build the test server and keep it running (molecule login to explore)
	molecule converge

.PHONY: verify
verify: ## Run the checks against the running test server
	molecule verify

.PHONY: destroy
destroy: ## Remove the test server
	molecule destroy

.PHONY: check
check: ## Dry run against real hosts, showing diffs
	ansible-playbook playbooks/site.yml -i inventories/$(ENV)/hosts.yml --check --diff --ask-vault-pass

.PHONY: apply
apply: ## Configure real hosts
	ansible-playbook playbooks/site.yml -i inventories/$(ENV)/hosts.yml --ask-vault-pass

.PHONY: deploy
deploy: ## Release the app only, e.g. make deploy IMAGE=ghcr.io/acme/shop:1.4.2
	ansible-playbook playbooks/deploy.yml -i inventories/$(ENV)/hosts.yml --ask-vault-pass $(if $(IMAGE),-e app_image=$(IMAGE))
