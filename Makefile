.PHONY: help ci clean clean-all deploy-local deploy-local-check deploy-production deploy-production-check install lint lint-fix orb-create-vms orb-create-vms-rocky orb-create-vms-ubuntu orb-delete-vms orb-delete-vms-rocky orb-delete-vms-ubuntu ping-local ping-production safety-check setup syntax-check test test-all test-certbot test-integration test-integration-check-vms test-integration-db-config test-mattermost test-mattermost-boards test-mattermost-calls test-mattermost-db-config test-mattermost-migrate-to-db test-mattermost-rocky test-nginx test-nginx-rocky test-postgresql test-postgresql-rocky test-rocky test-rtcd test-ubuntu test-unit vault-create vault-create-secure vault-decrypt vault-edit vault-encrypt vault-rekey vault-view

# Default target
.DEFAULT_GOAL := help

# Virtual environment activation
VENV_ACTIVATE = . venv/bin/activate

# Vault password file (if exists)
VAULT_PASSWORD_FILE = .vault_password
VAULT_PASS_ARG = $(shell [ -f $(VAULT_PASSWORD_FILE) ] && echo "--vault-password-file $(VAULT_PASSWORD_FILE)" || echo "")

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
	@$(VENV_ACTIVATE) && ansible-playbook -i inventory/local.ini site.yml $(VAULT_PASS_ARG)

deploy-local-check: ## Dry-run deploy to local VMs
	@echo "Checking local deployment (dry-run)..."
	@$(VENV_ACTIVATE) && ansible-playbook -i inventory/local.ini site.yml --check --diff $(VAULT_PASS_ARG)

deploy-production: ## Deploy to production (inventory/production.ini)
	@echo "Deploying to production environment..."
	@read -p "Are you sure you want to deploy to PRODUCTION? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(VENV_ACTIVATE) && ansible-playbook -i inventory/production.ini site.yml $(VAULT_PASS_ARG); \
	else \
		echo "Deployment cancelled."; \
	fi

deploy-production-check: ## Dry-run deploy to production
	@echo "Checking production deployment (dry-run)..."
	@$(VENV_ACTIVATE) && ansible-playbook -i inventory/production.ini site.yml --check --diff $(VAULT_PASS_ARG)

orb-create-vms: orb-create-vms-rocky ## Create OrbStack VMs for local testing (default: Rocky)

orb-create-vms-rocky: ## Create Rocky Linux 9 AMD64 VMs (mattermost-rocky, postgresql-rocky, rtcd-rocky)
	@echo "Creating Rocky Linux 9 AMD64 VMs in OrbStack..."
	@orb create -a amd64 rocky:9 postgresql-rocky || echo "postgresql-rocky may already exist"
	@orb create -a amd64 rocky:9 mattermost-rocky || echo "mattermost-rocky may already exist"
	@orb create -a amd64 rocky:9 rtcd-rocky || echo "rtcd-rocky may already exist"
	@echo "✓ Rocky Linux 9 VMs created"
	@echo ""
	@echo "Update inventory/local.ini with:"
	@echo "  [database]"
	@echo "  $(USER)@postgresql-rocky@orb"
	@echo "  [app]"
	@echo "  $(USER)@mattermost-rocky@orb"
	@echo "  [rtcd]"
	@echo "  $(USER)@rtcd-rocky@orb"

orb-create-vms-ubuntu: ## Create Ubuntu AMD64 VMs (mattermost-ubuntu, postgresql-ubuntu, rtcd-ubuntu)
	@echo "Creating Ubuntu AMD64 VMs in OrbStack..."
	@orb create -a amd64 ubuntu postgresql-ubuntu || echo "postgresql-ubuntu may already exist"
	@orb create -a amd64 ubuntu mattermost-ubuntu || echo "mattermost-ubuntu may already exist"
	@orb create -a amd64 ubuntu rtcd-ubuntu || echo "rtcd-ubuntu may already exist"
	@echo "✓ Ubuntu VMs created"
	@echo ""
	@echo "Update inventory/local.ini with:"
	@echo "  [database]"
	@echo "  $(USER)@postgresql-ubuntu@orb"
	@echo "  [app]"
	@echo "  $(USER)@mattermost-ubuntu@orb"
	@echo "  [rtcd]"
	@echo "  $(USER)@rtcd-ubuntu@orb"

orb-delete-vms: orb-delete-vms-rocky ## Delete OrbStack VMs (default: Rocky)

orb-delete-vms-rocky: ## Delete Rocky Linux VMs
	@echo "Deleting Rocky Linux VMs..."
	@orb delete -f postgresql-rocky mattermost-rocky rtcd-rocky 2>/dev/null || true
	@echo "✓ Rocky Linux VMs deleted"

orb-delete-vms-ubuntu: ## Delete Ubuntu VMs
	@echo "Deleting Ubuntu VMs..."
	@orb delete -f postgresql-ubuntu mattermost-ubuntu rtcd-ubuntu 2>/dev/null || true
	@echo "✓ Ubuntu VMs deleted"

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

test: test-unit ## Run all tests (unit + integration)

test-all: test-unit test-integration ## Run ALL tests (unit + integration)
	@echo "✓ All tests completed"

test-integration: test-integration-check-vms test-integration-db-config ## Run all integration tests
	@echo "✓ All integration tests completed"

test-integration-check-vms: ## Verify test VMs are accessible
	@echo "Checking test VM connectivity..."
	@if [ ! -f "tests/integration/inventory/test.ini" ]; then \
		echo "ERROR: tests/integration/inventory/test.ini not found"; \
		echo "Create test.ini from test.ini.example and configure your test VMs"; \
		echo "See tests/integration/vm-providers/README.md for setup instructions"; \
		exit 1; \
	fi
	@$(VENV_ACTIVATE) && ansible all -i tests/integration/inventory/test.ini -m ping
	@echo "✓ Test VMs are accessible"

test-integration-db-config: test-integration-check-vms ## Run database configuration integration tests
	@echo "Running database configuration integration tests..."
	@$(VENV_ACTIVATE) && tests/integration/test-database-config.sh
	@echo "✓ Database configuration integration tests passed"

test-unit: test-ubuntu test-rocky test-certbot ## Run all unit tests (Molecule)
	@echo "✓ All unit tests completed"

test-certbot: ## Test certbot role (Ubuntu only)
	@echo "Testing certbot role..."
	@$(VENV_ACTIVATE) && cd roles/certbot && molecule test

test-mattermost: ## Test mattermost role (Ubuntu - default scenario)
	@echo "Testing mattermost role (Ubuntu)..."
	@$(VENV_ACTIVATE) && cd roles/mattermost && molecule test -s default

test-mattermost-boards: ## Test mattermost role with Boards plugin
	@echo "Testing mattermost role with Boards plugin..."
	@$(VENV_ACTIVATE) && cd roles/mattermost && molecule test -s with-boards

test-mattermost-calls: ## Test mattermost role with Calls/rtcd configuration
	@echo "Testing mattermost role with Calls enabled..."
	@$(VENV_ACTIVATE) && cd roles/mattermost && molecule test -s with-calls

test-mattermost-db-config: ## Test mattermost role with database config storage
	@echo "Testing mattermost role with database config storage..."
	@$(VENV_ACTIVATE) && cd roles/mattermost && molecule test -s database-config

test-mattermost-migrate-to-db: ## Test file to database config migration
	@echo "Testing migration from file to database config..."
	@$(VENV_ACTIVATE) && cd roles/mattermost && molecule test -s migrate-to-db

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

test-ubuntu: test-postgresql test-mattermost test-mattermost-boards test-mattermost-calls test-nginx test-rtcd ## Run all Ubuntu tests (default scenarios)
	@echo "✓ All Ubuntu tests completed"

vault-create: ## Create vault file from example template
	@if [ -f "group_vars/all.yml" ]; then \
		echo "ERROR: group_vars/all.yml already exists"; \
		echo "Use 'make vault-edit' to modify it or remove it first"; \
		exit 1; \
	fi
	@echo "Creating vault file from template..."
	@cp group_vars/all.yml.example group_vars/all.yml
	@echo "✓ Vault file created at group_vars/all.yml"
	@echo "Edit the file with your secrets, then run 'make vault-encrypt'"
	@echo ""
	@echo "TIP: Use 'make vault-create-secure' to auto-generate strong passwords"

vault-create-secure: ## Create vault file with auto-generated secure passwords
	@if [ -f "group_vars/all.yml" ]; then \
		echo "ERROR: group_vars/all.yml already exists"; \
		echo "Use 'make vault-edit' to modify it or remove it first"; \
		exit 1; \
	fi
	@echo "Creating vault file with auto-generated secure passwords..."
	@$(VENV_ACTIVATE) && \
	LOCAL_PASS=$$(python3 scripts/generate_secret.py 32) && \
	PROD_PASS=$$(python3 scripts/generate_secret.py 32) && \
	printf '%s\n' \
		'---' \
		'# Ansible Vault encrypted secrets' \
		'# Generated on '"`date`" \
		'# All variables prefixed with vault_ are referenced from group_vars files' \
		'' \
		'# Local environment database password (used by mattermost.yml)' \
		"vault_local_db_password: \"$$LOCAL_PASS\"" \
		'' \
		'# Production environment database password (used by production.yml)' \
		"vault_production_db_password: \"$$PROD_PASS\"" \
		> group_vars/all.yml
	@echo "✓ Vault file created at group_vars/all.yml with secure passwords"
	@echo "Review the file with 'cat group_vars/all.yml', then run 'make vault-encrypt'"

vault-decrypt: ## Decrypt the vault file (WARNING: removes encryption)
	@if [ ! -f "group_vars/all.yml" ]; then \
		echo "ERROR: group_vars/all.yml not found"; \
		exit 1; \
	fi
	@echo "Decrypting vault file..."
	@$(VENV_ACTIVATE) && ansible-vault decrypt group_vars/all.yml $(VAULT_PASS_ARG)

vault-edit: ## Edit the encrypted vault file
	@if [ ! -f "group_vars/all.yml" ]; then \
		echo "ERROR: group_vars/all.yml not found"; \
		echo "Run 'make vault-create' first"; \
		exit 1; \
	fi
	@$(VENV_ACTIVATE) && ansible-vault edit group_vars/all.yml $(VAULT_PASS_ARG)

vault-encrypt: ## Encrypt the vault file
	@if [ ! -f "group_vars/all.yml" ]; then \
		echo "ERROR: group_vars/all.yml not found"; \
		echo "Run 'make vault-create' first"; \
		exit 1; \
	fi
	@echo "Encrypting vault file..."
	@$(VENV_ACTIVATE) && ansible-vault encrypt group_vars/all.yml $(VAULT_PASS_ARG)

vault-rekey: ## Change the vault password
	@if [ ! -f "group_vars/all.yml" ]; then \
		echo "ERROR: group_vars/all.yml not found"; \
		exit 1; \
	fi
	@echo "Changing vault password..."
	@$(VENV_ACTIVATE) && ansible-vault rekey group_vars/all.yml $(VAULT_PASS_ARG)

vault-view: ## View the encrypted vault file contents
	@if [ ! -f "group_vars/all.yml" ]; then \
		echo "ERROR: group_vars/all.yml not found"; \
		exit 1; \
	fi
	@$(VENV_ACTIVATE) && ansible-vault view group_vars/all.yml $(VAULT_PASS_ARG)
