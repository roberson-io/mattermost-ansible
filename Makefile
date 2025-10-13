.PHONY: help ci clean clean-all deploy-local deploy-local-check deploy-production deploy-production-check install lint lint-fix ping-local ping-production safety-check setup syntax-check test test-all test-certbot test-mattermost test-mattermost-calls test-mattermost-rocky test-nginx test-nginx-rocky test-postgresql test-postgresql-rocky test-rocky test-rtcd test-ubuntu

# Default target
.DEFAULT_GOAL := help

# Detect OS
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	VENV_ACTIVATE = . venv/bin/activate
else
	VENV_ACTIVATE = . venv/bin/activate
endif

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

ci: lint syntax-check safety-check test ## Run all CI checks (lint, syntax, security, test)

clean: ## Clean up test artifacts and containers
	@echo "Cleaning up..."
	@$(VENV_ACTIVATE) && cd roles/postgresql && molecule destroy --all || true
	@$(VENV_ACTIVATE) && cd roles/mattermost && molecule destroy --all || true
	@$(VENV_ACTIVATE) && cd roles/nginx && molecule destroy --all || true
	@$(VENV_ACTIVATE) && cd roles/certbot && molecule destroy --all || true
	@$(VENV_ACTIVATE) && cd roles/rtcd && molecule destroy --all || true
	@find . -type d -name ".molecule" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete
	@echo "✓ Cleaned up"

clean-all: clean ## Clean everything including venv
	@echo "Removing virtual environment..."
	@rm -rf venv
	@echo "✓ Full cleanup complete"

deploy-local: ## Deploy to local VMs (inventory/local.ini)
	@echo "Deploying to local environment..."
	@$(VENV_ACTIVATE) && ansible-playbook -i inventory/local.ini site.yml

deploy-local-check: ## Dry-run deploy to local VMs
	@echo "Checking local deployment (dry-run)..."
	@$(VENV_ACTIVATE) && ansible-playbook -i inventory/local.ini site.yml --check --diff

deploy-production: ## Deploy to production (inventory/production.ini)
	@echo "Deploying to production environment..."
	@read -p "Are you sure you want to deploy to PRODUCTION? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(VENV_ACTIVATE) && ansible-playbook -i inventory/production.ini site.yml; \
	else \
		echo "Deployment cancelled."; \
	fi

deploy-production-check: ## Dry-run deploy to production
	@echo "Checking production deployment (dry-run)..."
	@$(VENV_ACTIVATE) && ansible-playbook -i inventory/production.ini site.yml --check --diff

install: ## Install dependencies (creates venv if needed)
	@if [ ! -d "venv" ]; then \
		echo "Creating virtual environment..."; \
		python3 -m venv venv; \
	fi
	@echo "Installing dependencies..."
	@$(VENV_ACTIVATE) && pip install --upgrade pip
	@$(VENV_ACTIVATE) && pip install -r requirements.txt
	@echo "✓ Dependencies installed"

lint: ## Run linting (ansible-lint + yamllint)
	@echo "Running ansible-lint..."
	@$(VENV_ACTIVATE) && ansible-lint site.yml roles/*/
	@echo "Running yamllint..."
	@$(VENV_ACTIVATE) && yamllint .
	@echo "✓ Linting passed"

lint-fix: ## Auto-fix linting issues where possible
	@echo "Auto-fixing linting issues..."
	@$(VENV_ACTIVATE) && ansible-lint --fix site.yml roles/*/

ping-local: ## Test connectivity to local VMs
	@$(VENV_ACTIVATE) && ansible all -i inventory/local.ini -m ping

ping-production: ## Test connectivity to production servers
	@$(VENV_ACTIVATE) && ansible all -i inventory/production.ini -m ping

safety-check: ## Check for known security vulnerabilities in dependencies
	@echo "Checking for security vulnerabilities..."
	@$(VENV_ACTIVATE) && safety scan --detailed-output || true
	@echo "✓ Security scan completed"

setup: install ## Alias for install (first-time setup)

syntax-check: ## Check playbook syntax
	@echo "Checking syntax..."
	@$(VENV_ACTIVATE) && ansible-playbook site.yml --syntax-check
	@echo "✓ Syntax check passed"

test: test-ubuntu ## Run all default (Ubuntu) role tests
	@echo "✓ All default tests completed"

test-all: test-ubuntu test-rocky test-certbot ## Run ALL tests (Ubuntu + Rocky + certbot)
	@echo "✓ All multi-distro tests completed"

test-certbot: ## Test certbot role (Ubuntu only)
	@echo "Testing certbot role..."
	@$(VENV_ACTIVATE) && cd roles/certbot && molecule test

test-mattermost: ## Test mattermost role (Ubuntu - default scenario)
	@echo "Testing mattermost role (Ubuntu)..."
	@$(VENV_ACTIVATE) && cd roles/mattermost && molecule test -s default

test-mattermost-calls: ## Test mattermost role with Calls/rtcd configuration
	@echo "Testing mattermost role with Calls enabled..."
	@$(VENV_ACTIVATE) && cd roles/mattermost && molecule test -s with-calls

test-mattermost-rocky: ## Test mattermost role (Rocky Linux)
	@echo "Testing mattermost role (Rocky Linux)..."
	@$(VENV_ACTIVATE) && cd roles/mattermost && molecule test -s rocky

test-nginx: ## Test nginx role (Ubuntu - default scenario)
	@echo "Testing nginx role (Ubuntu)..."
	@$(VENV_ACTIVATE) && cd roles/nginx && molecule test -s default

test-nginx-rocky: ## Test nginx role (Rocky Linux)
	@echo "Testing nginx role (Rocky Linux)..."
	@$(VENV_ACTIVATE) && cd roles/nginx && molecule test -s rocky

test-postgresql: ## Test postgresql role (Ubuntu - default scenario)
	@echo "Testing postgresql role (Ubuntu)..."
	@$(VENV_ACTIVATE) && cd roles/postgresql && molecule test -s default

test-postgresql-rocky: ## Test postgresql role (Rocky Linux)
	@echo "Testing postgresql role (Rocky Linux)..."
	@$(VENV_ACTIVATE) && cd roles/postgresql && molecule test -s rocky

test-rocky: test-postgresql-rocky test-mattermost-rocky test-nginx-rocky ## Run all Rocky Linux tests
	@echo "✓ All Rocky Linux tests completed"

test-rtcd: ## Test rtcd role (Ubuntu - default scenario)
	@echo "Testing rtcd role (Ubuntu)..."
	@$(VENV_ACTIVATE) && cd roles/rtcd && molecule test -s default

test-ubuntu: test-postgresql test-mattermost test-mattermost-calls test-nginx test-rtcd ## Run all Ubuntu tests (default scenarios)
	@echo "✓ All Ubuntu tests completed"
