.PHONY: help ci clean clean-all deploy-local deploy-local-check deploy-production deploy-production-check deploy-staging deploy-staging-check install lint lint-fix orb-create-vm-calls-offloader-rocky orb-create-vm-calls-offloader-ubuntu orb-create-vm-coturn-rocky orb-create-vm-coturn-ubuntu orb-create-vm-loadbalancer-rocky orb-create-vm-loadbalancer-ubuntu orb-create-vm-monitoring-rocky orb-create-vm-monitoring-ubuntu orb-create-vm-nfs-rocky orb-create-vm-nfs-ubuntu orb-create-vms orb-create-vms-ha-cluster-rocky orb-create-vms-ha-cluster-ubuntu orb-create-vms-rocky orb-create-vms-ubuntu orb-delete-vm-calls-offloader-rocky orb-delete-vm-calls-offloader-ubuntu orb-delete-vm-coturn-rocky orb-delete-vm-coturn-ubuntu orb-delete-vm-loadbalancer-rocky orb-delete-vm-loadbalancer-ubuntu orb-delete-vm-monitoring-rocky orb-delete-vm-monitoring-ubuntu orb-delete-vm-nfs-rocky orb-delete-vm-nfs-ubuntu orb-delete-vms orb-delete-vms-ha-cluster-rocky orb-delete-vms-ha-cluster-ubuntu orb-delete-vms-rocky orb-delete-vms-ubuntu ping-local ping-production ping-staging safety-check setup syntax-check test test-all test-certbot test-integration test-integration-check-vms test-integration-db-config test-mattermost test-mattermost-boards test-mattermost-calls test-mattermost-db-config test-mattermost-migrate-to-db test-mattermost-rocky test-nginx test-nginx-rocky test-postgresql test-postgresql-rocky test-rocky test-rtcd test-ubuntu test-unit vault-create vault-create-secure vault-decrypt vault-edit vault-encrypt vault-rekey vault-view

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

deploy-local: ## Deploy to local VMs (single-node or HA cluster via inventory/local.ini)
	@echo "Deploying to local environment..."
	@$(VENV_ACTIVATE) && ansible-playbook -i inventory/local.ini site.yml $(VAULT_PASS_ARG)

deploy-local-check: ## Dry-run deploy to local VMs (single-node or HA)
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

deploy-staging: ## Deploy to staging (inventory/staging.ini)
	@echo "Deploying to staging environment..."
	@read -p "Are you sure you want to deploy to STAGING? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(VENV_ACTIVATE) && ansible-playbook -i inventory/staging.ini site.yml $(VAULT_PASS_ARG); \
	else \
		echo "Deployment cancelled."; \
	fi

deploy-staging-check: ## Dry-run deploy to staging
	@echo "Checking staging deployment (dry-run)..."
	@$(VENV_ACTIVATE) && ansible-playbook -i inventory/staging.ini site.yml --check --diff $(VAULT_PASS_ARG)

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

orb-create-vm-keycloak-rocky: ## Create Keycloak VM (Rocky Linux 9)
	@echo "Creating Keycloak VM (Rocky Linux 9)..."
	@orb create -a amd64 rocky:9 keycloak-rocky || echo "keycloak-rocky may already exist"
	@echo "✓ Keycloak VM created. Add to inventory: [keycloak] $(USER)@keycloak-rocky@orb"

orb-create-vm-keycloak-ubuntu: ## Create Keycloak VM (Ubuntu)
	@echo "Creating Keycloak VM (Ubuntu)..."
	@orb create -a amd64 ubuntu keycloak-ubuntu || echo "keycloak-ubuntu may already exist"
	@echo "✓ Keycloak VM created. Add to inventory: [keycloak] $(USER)@keycloak-ubuntu@orb"

orb-create-vm-app%-rocky: ## Create Mattermost app node VM (Rocky Linux 9) - Usage: make orb-create-vm-app1-rocky
	@echo "Creating Mattermost app$* VM (Rocky Linux 9)..."
	@orb create -a amd64 rocky:9 mattermost$*-rocky || echo "mattermost$*-rocky may already exist"
	@echo "✓ Mattermost app$* VM created. Add to inventory: [app$*] $(USER)@mattermost$*-rocky@orb"

orb-create-vm-app%-ubuntu: ## Create Mattermost app node VM (Ubuntu) - Usage: make orb-create-vm-app1-ubuntu
	@echo "Creating Mattermost app$* VM (Ubuntu)..."
	@orb create -a amd64 ubuntu mattermost$*-ubuntu || echo "mattermost$*-ubuntu may already exist"
	@echo "✓ Mattermost app$* VM created. Add to inventory: [app$*] $(USER)@mattermost$*-ubuntu@orb"

orb-create-vm-calls-offloader-rocky: ## Create calls-offloader VM (Rocky Linux 9)
	@echo "Creating calls-offloader VM (Rocky Linux 9)..."
	@orb create -a amd64 rocky:9 calls-offloader-rocky || echo "calls-offloader-rocky may already exist"
	@echo "✓ calls-offloader VM created. Add to inventory: [calls_offloader] $(USER)@calls-offloader-rocky@orb"

orb-create-vm-calls-offloader-ubuntu: ## Create calls-offloader VM (Ubuntu)
	@echo "Creating calls-offloader VM (Ubuntu)..."
	@orb create -a amd64 ubuntu calls-offloader-ubuntu || echo "calls-offloader-ubuntu may already exist"
	@echo "✓ calls-offloader VM created. Add to inventory: [calls_offloader] $(USER)@calls-offloader-ubuntu@orb"

orb-create-vm-coturn-rocky: ## Create coturn VM (Rocky Linux 9)
	@echo "Creating coturn VM (Rocky Linux 9)..."
	@orb create -a amd64 rocky:9 coturn-rocky || echo "coturn-rocky may already exist"
	@echo "✓ coturn VM created. Add to inventory: [coturn] $(USER)@coturn-rocky@orb"

orb-create-vm-coturn-ubuntu: ## Create coturn VM (Ubuntu)
	@echo "Creating coturn VM (Ubuntu)..."
	@orb create -a amd64 ubuntu coturn-ubuntu || echo "coturn-ubuntu may already exist"
	@echo "✓ coturn VM created. Add to inventory: [coturn] $(USER)@coturn-ubuntu@orb"

orb-create-vm-ldap%-rocky: ## Create OpenLDAP VM (Rocky Linux 9) - Usage: make orb-create-vm-ldap1-rocky
	@echo "Creating OpenLDAP $* VM (Rocky Linux 9)..."
	@orb create -a amd64 rocky:9 ldap$*-rocky || echo "ldap$*-rocky may already exist"
	@echo "✓ OpenLDAP $* VM created. Add to inventory: [ldap$*] $(USER)@ldap$*-rocky@orb"

orb-create-vm-ldap%-ubuntu: ## Create OpenLDAP VM (Ubuntu) - Usage: make orb-create-vm-ldap1-ubuntu
	@echo "Creating OpenLDAP $* VM (Ubuntu)..."
	@orb create -a amd64 ubuntu ldap$*-ubuntu || echo "ldap$*-ubuntu may already exist"
	@echo "✓ OpenLDAP $* VM created. Add to inventory: [ldap$*] $(USER)@ldap$*-ubuntu@orb"

orb-create-vm-loadbalancer-rocky: ## Create load balancer VM (Rocky Linux 9)
	@echo "Creating load balancer VM (Rocky Linux 9)..."
	@orb create -a amd64 rocky:9 loadbalancer-rocky || echo "loadbalancer-rocky may already exist"
	@echo "✓ Load balancer VM created. Add to inventory: [loadbalancer] $(USER)@loadbalancer-rocky@orb"

orb-create-vm-loadbalancer-ubuntu: ## Create load balancer VM (Ubuntu)
	@echo "Creating load balancer VM (Ubuntu)..."
	@orb create -a amd64 ubuntu loadbalancer-ubuntu || echo "loadbalancer-ubuntu may already exist"
	@echo "✓ Load balancer VM created. Add to inventory: [loadbalancer] $(USER)@loadbalancer-ubuntu@orb"

orb-create-vm-monitoring-rocky: ## Create monitoring VM (Rocky Linux 9)
	@echo "Creating monitoring VM (Rocky Linux 9)..."
	@orb create -a amd64 rocky:9 monitoring-rocky || echo "monitoring-rocky may already exist"
	@echo "✓ Monitoring VM created. Add to inventory: [monitoring] $(USER)@monitoring-rocky@orb"

orb-create-vm-monitoring-ubuntu: ## Create monitoring VM (Ubuntu)
	@echo "Creating monitoring VM (Ubuntu)..."
	@orb create -a amd64 ubuntu monitoring-ubuntu || echo "monitoring-ubuntu may already exist"
	@echo "✓ Monitoring VM created. Add to inventory: [monitoring] $(USER)@monitoring-ubuntu@orb"

orb-create-vm-minio-rocky: ## Create MinIO VM (Rocky Linux 9)
	@echo "Creating MinIO VM (Rocky Linux 9)..."
	@orb create -a amd64 rocky:9 minio-rocky || echo "minio-rocky may already exist"
	@echo "✓ MinIO VM created. Add to inventory: [minio] $(USER)@minio-rocky@orb"

orb-create-vm-minio-ubuntu: ## Create MinIO VM (Ubuntu)
	@echo "Creating MinIO VM (Ubuntu)..."
	@orb create -a amd64 ubuntu minio-ubuntu || echo "minio-ubuntu may already exist"
	@echo "✓ MinIO VM created. Add to inventory: [minio] $(USER)@minio-ubuntu@orb"

orb-create-vm-nfs-rocky: ## Create NFS server VM (Rocky Linux 9)
	@echo "Creating NFS server VM (Rocky Linux 9)..."
	@orb create -a amd64 rocky:9 nfs-rocky || echo "nfs-rocky may already exist"
	@echo "✓ NFS server VM created. Add to inventory: [nfs] $(USER)@nfs-rocky@orb"

orb-create-vm-nfs-ubuntu: ## Create NFS server VM (Ubuntu)
	@echo "Creating NFS server VM (Ubuntu)..."
	@orb create -a amd64 ubuntu nfs-ubuntu || echo "nfs-ubuntu may already exist"
	@echo "✓ NFS server VM created. Add to inventory: [nfs] $(USER)@nfs-ubuntu@orb"

orb-create-vm-postgresql-rocky: ## Create PostgreSQL VM (Rocky Linux 9)
	@echo "Creating PostgreSQL VM (Rocky Linux 9)..."
	@orb create -a amd64 rocky:9 postgresql-rocky || echo "postgresql-rocky may already exist"
	@echo "✓ PostgreSQL VM created. Add to inventory: [database] $(USER)@postgresql-rocky@orb"

orb-create-vm-postgresql-ubuntu: ## Create PostgreSQL VM (Ubuntu)
	@echo "Creating PostgreSQL VM (Ubuntu)..."
	@orb create -a amd64 ubuntu postgresql-ubuntu || echo "postgresql-ubuntu may already exist"
	@echo "✓ PostgreSQL VM created. Add to inventory: [database] $(USER)@postgresql-ubuntu@orb"

orb-create-vm-redis-rocky: ## Create Redis VM (Rocky Linux 9)
	@echo "Creating Redis VM (Rocky Linux 9)..."
	@orb create -a amd64 rocky:9 redis-rocky || echo "redis-rocky may already exist"
	@echo "✓ Redis VM created. Add to inventory: [redis] $(USER)@redis-rocky@orb"

orb-create-vm-redis-ubuntu: ## Create Redis VM (Ubuntu)
	@echo "Creating Redis VM (Ubuntu)..."
	@orb create -a amd64 ubuntu redis-ubuntu || echo "redis-ubuntu may already exist"
	@echo "✓ Redis VM created. Add to inventory: [redis] $(USER)@redis-ubuntu@orb"

orb-create-vm-elasticsearch-rocky: orb-create-vm-elasticsearch1-rocky ## Create single Elasticsearch VM (Rocky Linux 9)

orb-create-vm-elasticsearch-ubuntu: orb-create-vm-elasticsearch1-ubuntu ## Create single Elasticsearch VM (Ubuntu)

orb-create-vm-elasticsearch1-rocky: ## Create Elasticsearch node 1 VM (Rocky Linux 9)
	@echo "Creating Elasticsearch node 1 VM (Rocky Linux 9)..."
	@orb create -a amd64 rocky:9 elasticsearch1-rocky || echo "elasticsearch1-rocky may already exist"
	@echo "✓ Elasticsearch node 1 VM created. Add to inventory: [elasticsearch1] $(USER)@elasticsearch1-rocky@orb"

orb-create-vm-elasticsearch1-ubuntu: ## Create Elasticsearch node 1 VM (Ubuntu)
	@echo "Creating Elasticsearch node 1 VM (Ubuntu)..."
	@orb create -a amd64 ubuntu elasticsearch1-ubuntu || echo "elasticsearch1-ubuntu may already exist"
	@echo "✓ Elasticsearch node 1 VM created. Add to inventory: [elasticsearch1] $(USER)@elasticsearch1-ubuntu@orb"

orb-create-vm-elasticsearch2-rocky: ## Create Elasticsearch node 2 VM (Rocky Linux 9)
	@echo "Creating Elasticsearch node 2 VM (Rocky Linux 9)..."
	@orb create -a amd64 rocky:9 elasticsearch2-rocky || echo "elasticsearch2-rocky may already exist"
	@echo "✓ Elasticsearch node 2 VM created. Add to inventory: [elasticsearch2] $(USER)@elasticsearch2-rocky@orb"

orb-create-vm-elasticsearch2-ubuntu: ## Create Elasticsearch node 2 VM (Ubuntu)
	@echo "Creating Elasticsearch node 2 VM (Ubuntu)..."
	@orb create -a amd64 ubuntu elasticsearch2-ubuntu || echo "elasticsearch2-ubuntu may already exist"
	@echo "✓ Elasticsearch node 2 VM created. Add to inventory: [elasticsearch2] $(USER)@elasticsearch2-ubuntu@orb"

orb-create-vm-elasticsearch3-rocky: ## Create Elasticsearch node 3 VM (Rocky Linux 9)
	@echo "Creating Elasticsearch node 3 VM (Rocky Linux 9)..."
	@orb create -a amd64 rocky:9 elasticsearch3-rocky || echo "elasticsearch3-rocky may already exist"
	@echo "✓ Elasticsearch node 3 VM created. Add to inventory: [elasticsearch3] $(USER)@elasticsearch3-rocky@orb"

orb-create-vm-elasticsearch3-ubuntu: ## Create Elasticsearch node 3 VM (Ubuntu)
	@echo "Creating Elasticsearch node 3 VM (Ubuntu)..."
	@orb create -a amd64 ubuntu elasticsearch3-ubuntu || echo "elasticsearch3-ubuntu may already exist"
	@echo "✓ Elasticsearch node 3 VM created. Add to inventory: [elasticsearch3] $(USER)@elasticsearch3-ubuntu@orb"

orb-create-vms-elasticsearch-cluster-rocky: orb-create-vm-elasticsearch1-rocky orb-create-vm-elasticsearch2-rocky orb-create-vm-elasticsearch3-rocky ## Create 3-node Elasticsearch cluster (Rocky Linux 9)
	@echo "✓ Elasticsearch cluster VMs created. Configure inventory with [elasticsearch:children] pattern"

orb-create-vms-elasticsearch-cluster-ubuntu: orb-create-vm-elasticsearch1-ubuntu orb-create-vm-elasticsearch2-ubuntu orb-create-vm-elasticsearch3-ubuntu ## Create 3-node Elasticsearch cluster (Ubuntu)
	@echo "✓ Elasticsearch cluster VMs created. Configure inventory with [elasticsearch:children] pattern"

orb-create-vms-ha-cluster-rocky: orb-create-vm-app1-rocky orb-create-vm-app2-rocky orb-create-vm-loadbalancer-rocky orb-create-vm-minio-rocky orb-create-vm-redis-rocky ## Create HA cluster VMs (Rocky: 2 app nodes, LB, MinIO, Redis)
	@echo "✓ HA cluster VMs created (Rocky Linux 9)"
	@echo ""
	@echo "Update inventory/local.ini for HA cluster:"
	@echo "  [app1]"
	@echo "  $(USER)@mattermost1-rocky@orb"
	@echo "  [app2]"
	@echo "  $(USER)@mattermost2-rocky@orb"
	@echo "  [app:children]"
	@echo "  app1"
	@echo "  app2"
	@echo "  [loadbalancer]"
	@echo "  $(USER)@loadbalancer-rocky@orb"
	@echo "  [minio]"
	@echo "  $(USER)@minio-rocky@orb"
	@echo "  [redis]"
	@echo "  $(USER)@redis-rocky@orb"
	@echo ""
	@echo "Configure group_vars/local.yml:"
	@echo "  mattermost_config_storage: database"
	@echo "  enable_minio: true"
	@echo "  mattermost_enable_s3: true"
	@echo "  enable_redis: true"
	@echo "  mattermost_enable_cluster: true"

orb-create-vms-ha-cluster-ubuntu: orb-create-vm-app1-ubuntu orb-create-vm-app2-ubuntu orb-create-vm-loadbalancer-ubuntu orb-create-vm-minio-ubuntu orb-create-vm-redis-ubuntu ## Create HA cluster VMs (Ubuntu: 2 app nodes, LB, MinIO, Redis)
	@echo "✓ HA cluster VMs created (Ubuntu)"
	@echo ""
	@echo "Update inventory/local.ini for HA cluster:"
	@echo "  [app1]"
	@echo "  $(USER)@mattermost1-ubuntu@orb"
	@echo "  [app2]"
	@echo "  $(USER)@mattermost2-ubuntu@orb"
	@echo "  [app:children]"
	@echo "  app1"
	@echo "  app2"
	@echo "  [loadbalancer]"
	@echo "  $(USER)@loadbalancer-ubuntu@orb"
	@echo "  [minio]"
	@echo "  $(USER)@minio-ubuntu@orb"
	@echo "  [redis]"
	@echo "  $(USER)@redis-ubuntu@orb"
	@echo ""
	@echo "Configure group_vars/local.yml:"
	@echo "  mattermost_config_storage: database"
	@echo "  enable_minio: true"
	@echo "  mattermost_enable_s3: true"
	@echo "  enable_redis: true"
	@echo "  mattermost_enable_cluster: true"

orb-create-vm-rtcd-rocky: ## Create RTCD VM (Rocky Linux 9)
	@echo "Creating RTCD VM (Rocky Linux 9)..."
	@orb create -a amd64 rocky:9 rtcd-rocky || echo "rtcd-rocky may already exist"
	@echo "✓ RTCD VM created. Add to inventory: [rtcd] $(USER)@rtcd-rocky@orb"

orb-create-vm-rtcd-ubuntu: ## Create RTCD VM (Ubuntu)
	@echo "Creating RTCD VM (Ubuntu)..."
	@orb create -a amd64 ubuntu rtcd-ubuntu || echo "rtcd-ubuntu may already exist"
	@echo "✓ RTCD VM created. Add to inventory: [rtcd] $(USER)@rtcd-ubuntu@orb"

orb-create-vms: orb-create-vms-rocky ## Create core OrbStack VMs (default: Rocky)

orb-create-vms-all-rocky: orb-create-vms-rocky orb-create-vm-calls-offloader-rocky orb-create-vm-coturn-rocky orb-create-vm-elasticsearch-rocky orb-create-vm-keycloak-rocky orb-create-vm-minio-rocky orb-create-vm-redis-rocky orb-create-vm-rtcd-rocky ## Create all Rocky VMs including optional services

orb-create-vms-all-ubuntu: orb-create-vms-ubuntu orb-create-vm-calls-offloader-ubuntu orb-create-vm-coturn-ubuntu orb-create-vm-elasticsearch-ubuntu orb-create-vm-keycloak-ubuntu orb-create-vm-minio-ubuntu orb-create-vm-redis-ubuntu orb-create-vm-rtcd-ubuntu ## Create all Ubuntu VMs including optional services

orb-create-vms-rocky: orb-create-vm-postgresql-rocky ## Create core Rocky Linux 9 AMD64 VMs (postgresql, mattermost only)
	@echo "Creating core Rocky Linux 9 AMD64 VMs..."
	@orb create -a amd64 rocky:9 mattermost-rocky || echo "mattermost-rocky may already exist"
	@echo "✓ Core Rocky VMs created"
	@echo ""
	@echo "Update inventory/local.ini:"
	@echo "  [database]"
	@echo "  $(USER)@postgresql-rocky@orb"
	@echo "  [app]"
	@echo "  $(USER)@mattermost-rocky@orb"
	@echo ""
	@echo "Optional services:"
	@echo "  make orb-create-vm-keycloak-rocky orb-create-vm-minio-rocky orb-create-vm-redis-rocky orb-create-vm-elasticsearch-rocky orb-create-vm-rtcd-rocky"
	@echo "  make orb-create-vm-ldap1-rocky orb-create-vm-ldap2-rocky ..."

orb-create-vms-ubuntu: orb-create-vm-postgresql-ubuntu ## Create core Ubuntu AMD64 VMs (postgresql, mattermost only)
	@echo "Creating core Ubuntu AMD64 VMs..."
	@orb create -a amd64 ubuntu mattermost-ubuntu || echo "mattermost-ubuntu may already exist"
	@echo "✓ Core Ubuntu VMs created"
	@echo ""
	@echo "Update inventory/local.ini:"
	@echo "  [database]"
	@echo "  $(USER)@postgresql-ubuntu@orb"
	@echo "  [app]"
	@echo "  $(USER)@mattermost-ubuntu@orb"
	@echo ""
	@echo "Optional services:"
	@echo "  make orb-create-vm-keycloak-ubuntu orb-create-vm-minio-ubuntu orb-create-vm-redis-ubuntu orb-create-vm-elasticsearch-ubuntu orb-create-vm-rtcd-ubuntu"
	@echo "  make orb-create-vm-ldap1-ubuntu orb-create-vm-ldap2-ubuntu ..."

orb-delete-vm-calls-offloader-rocky: ## Delete calls-offloader VM (Rocky)
	@orb delete -f calls-offloader-rocky 2>/dev/null || true
	@echo "✓ calls-offloader VM deleted"

orb-delete-vm-calls-offloader-ubuntu: ## Delete calls-offloader VM (Ubuntu)
	@orb delete -f calls-offloader-ubuntu 2>/dev/null || true
	@echo "✓ calls-offloader VM deleted"

orb-delete-vm-coturn-rocky: ## Delete coturn VM (Rocky)
	@orb delete -f coturn-rocky 2>/dev/null || true
	@echo "✓ coturn VM deleted"

orb-delete-vm-coturn-ubuntu: ## Delete coturn VM (Ubuntu)
	@orb delete -f coturn-ubuntu 2>/dev/null || true
	@echo "✓ coturn VM deleted"

orb-delete-vm-elasticsearch-rocky: ## Delete Elasticsearch VM (Rocky)
	@orb delete -f elasticsearch-rocky 2>/dev/null || true
	@echo "✓ Elasticsearch VM deleted"

orb-delete-vm-elasticsearch-ubuntu: ## Delete Elasticsearch VM (Ubuntu)
	@orb delete -f elasticsearch-ubuntu 2>/dev/null || true
	@echo "✓ Elasticsearch VM deleted"

orb-delete-vm-keycloak-rocky: ## Delete Keycloak VM (Rocky)
	@orb delete -f keycloak-rocky 2>/dev/null || true
	@echo "✓ Keycloak VM deleted"

orb-delete-vm-keycloak-ubuntu: ## Delete Keycloak VM (Ubuntu)
	@orb delete -f keycloak-ubuntu 2>/dev/null || true
	@echo "✓ Keycloak VM deleted"

orb-delete-vm-ldap%-rocky: ## Delete OpenLDAP VM (Rocky) - Usage: make orb-delete-vm-ldap1-rocky
	@orb delete -f ldap$*-rocky 2>/dev/null || true
	@echo "✓ OpenLDAP $* VM deleted"

orb-delete-vm-ldap%-ubuntu: ## Delete OpenLDAP VM (Ubuntu) - Usage: make orb-delete-vm-ldap1-ubuntu
	@orb delete -f ldap$*-ubuntu 2>/dev/null || true
	@echo "✓ OpenLDAP $* VM deleted"

orb-delete-vm-loadbalancer-rocky: ## Delete load balancer VM (Rocky)
	@orb delete -f loadbalancer-rocky 2>/dev/null || true
	@echo "✓ Load balancer VM deleted"

orb-delete-vm-loadbalancer-ubuntu: ## Delete load balancer VM (Ubuntu)
	@orb delete -f loadbalancer-ubuntu 2>/dev/null || true
	@echo "✓ Load balancer VM deleted"

orb-delete-vm-monitoring-rocky: ## Delete monitoring VM (Rocky)
	@orb delete -f monitoring-rocky 2>/dev/null || true
	@echo "✓ Monitoring VM deleted"

orb-delete-vm-monitoring-ubuntu: ## Delete monitoring VM (Ubuntu)
	@orb delete -f monitoring-ubuntu 2>/dev/null || true
	@echo "✓ Monitoring VM deleted"

orb-delete-vm-app%-rocky: ## Delete Mattermost app node VM (Rocky) - Usage: make orb-delete-vm-app1-rocky
	@orb delete -f mattermost$*-rocky 2>/dev/null || true
	@echo "✓ Mattermost app$* VM deleted"

orb-delete-vm-app%-ubuntu: ## Delete Mattermost app node VM (Ubuntu) - Usage: make orb-delete-vm-app1-ubuntu
	@orb delete -f mattermost$*-ubuntu 2>/dev/null || true
	@echo "✓ Mattermost app$* VM deleted"

orb-delete-vm-minio-rocky: ## Delete MinIO VM (Rocky)
	@orb delete -f minio-rocky 2>/dev/null || true
	@echo "✓ MinIO VM deleted"

orb-delete-vm-minio-ubuntu: ## Delete MinIO VM (Ubuntu)
	@orb delete -f minio-ubuntu 2>/dev/null || true
	@echo "✓ MinIO VM deleted"

orb-delete-vm-nfs-rocky: ## Delete NFS server VM (Rocky)
	@orb delete -f nfs-rocky 2>/dev/null || true
	@echo "✓ NFS server VM deleted"

orb-delete-vm-nfs-ubuntu: ## Delete NFS server VM (Ubuntu)
	@orb delete -f nfs-ubuntu 2>/dev/null || true
	@echo "✓ NFS server VM deleted"

orb-delete-vm-postgresql-rocky: ## Delete PostgreSQL VM (Rocky)
	@orb delete -f postgresql-rocky 2>/dev/null || true
	@echo "✓ PostgreSQL VM deleted"

orb-delete-vm-postgresql-ubuntu: ## Delete PostgreSQL VM (Ubuntu)
	@orb delete -f postgresql-ubuntu 2>/dev/null || true
	@echo "✓ PostgreSQL VM deleted"

orb-delete-vm-redis-rocky: ## Delete Redis VM (Rocky)
	@orb delete -f redis-rocky 2>/dev/null || true
	@echo "✓ Redis VM deleted"

orb-delete-vm-redis-ubuntu: ## Delete Redis VM (Ubuntu)
	@orb delete -f redis-ubuntu 2>/dev/null || true
	@echo "✓ Redis VM deleted"

orb-delete-vm-elasticsearch-rocky: orb-delete-vm-elasticsearch1-rocky ## Delete single Elasticsearch VM (Rocky)

orb-delete-vm-elasticsearch-ubuntu: orb-delete-vm-elasticsearch1-ubuntu ## Delete single Elasticsearch VM (Ubuntu)

orb-delete-vm-elasticsearch1-rocky: ## Delete Elasticsearch node 1 VM (Rocky)
	@orb delete -f elasticsearch1-rocky 2>/dev/null || true
	@echo "✓ Elasticsearch node 1 VM deleted"

orb-delete-vm-elasticsearch1-ubuntu: ## Delete Elasticsearch node 1 VM (Ubuntu)
	@orb delete -f elasticsearch1-ubuntu 2>/dev/null || true
	@echo "✓ Elasticsearch node 1 VM deleted"

orb-delete-vm-elasticsearch2-rocky: ## Delete Elasticsearch node 2 VM (Rocky)
	@orb delete -f elasticsearch2-rocky 2>/dev/null || true
	@echo "✓ Elasticsearch node 2 VM deleted"

orb-delete-vm-elasticsearch2-ubuntu: ## Delete Elasticsearch node 2 VM (Ubuntu)
	@orb delete -f elasticsearch2-ubuntu 2>/dev/null || true
	@echo "✓ Elasticsearch node 2 VM deleted"

orb-delete-vm-elasticsearch3-rocky: ## Delete Elasticsearch node 3 VM (Rocky)
	@orb delete -f elasticsearch3-rocky 2>/dev/null || true
	@echo "✓ Elasticsearch node 3 VM deleted"

orb-delete-vm-elasticsearch3-ubuntu: ## Delete Elasticsearch node 3 VM (Ubuntu)
	@orb delete -f elasticsearch3-ubuntu 2>/dev/null || true
	@echo "✓ Elasticsearch node 3 VM deleted"

orb-delete-vms-elasticsearch-cluster-rocky: orb-delete-vm-elasticsearch1-rocky orb-delete-vm-elasticsearch2-rocky orb-delete-vm-elasticsearch3-rocky ## Delete 3-node Elasticsearch cluster (Rocky)

orb-delete-vms-elasticsearch-cluster-ubuntu: orb-delete-vm-elasticsearch1-ubuntu orb-delete-vm-elasticsearch2-ubuntu orb-delete-vm-elasticsearch3-ubuntu ## Delete 3-node Elasticsearch cluster (Ubuntu)

orb-delete-vms-ha-cluster-rocky: orb-delete-vm-postgresql-rocky orb-delete-vm-app1-rocky orb-delete-vm-app2-rocky orb-delete-vm-loadbalancer-rocky orb-delete-vm-minio-rocky orb-delete-vm-redis-rocky orb-delete-vm-keycloak-rocky orb-delete-vm-ldap1-rocky ## Delete HA cluster VMs (Rocky: DB, 2 app nodes, LB, MinIO, Redis, Keycloak, LDAP)
	@echo "✓ HA cluster VMs deleted (Rocky Linux 9)"

orb-delete-vms-ha-cluster-ubuntu: orb-delete-vm-postgresql-ubuntu orb-delete-vm-app1-ubuntu orb-delete-vm-app2-ubuntu orb-delete-vm-loadbalancer-ubuntu orb-delete-vm-minio-ubuntu orb-delete-vm-redis-ubuntu orb-delete-vm-keycloak-ubuntu orb-delete-vm-ldap1-ubuntu ## Delete HA cluster VMs (Ubuntu: DB, 2 app nodes, LB, MinIO, Redis, Keycloak, LDAP)
	@echo "✓ HA cluster VMs deleted (Ubuntu)"

orb-delete-vm-rtcd-rocky: ## Delete RTCD VM (Rocky)
	@orb delete -f rtcd-rocky 2>/dev/null || true
	@echo "✓ RTCD VM deleted"

orb-delete-vm-rtcd-ubuntu: ## Delete RTCD VM (Ubuntu)
	@orb delete -f rtcd-ubuntu 2>/dev/null || true
	@echo "✓ RTCD VM deleted"

orb-delete-vms: orb-delete-vms-rocky ## Delete core OrbStack VMs (default: Rocky)

orb-delete-vms-all-rocky: orb-delete-vms-rocky orb-delete-vm-calls-offloader-rocky orb-delete-vm-coturn-rocky orb-delete-vm-elasticsearch-rocky orb-delete-vm-keycloak-rocky orb-delete-vm-ldap1-rocky orb-delete-vm-minio-rocky orb-delete-vm-nfs-rocky orb-delete-vm-redis-rocky orb-delete-vm-rtcd-rocky orb-delete-vm-monitoring-rocky ## Delete all Rocky VMs including optional services

orb-delete-vms-all-ubuntu: orb-delete-vms-ubuntu orb-delete-vm-calls-offloader-ubuntu orb-delete-vm-coturn-ubuntu orb-delete-vm-elasticsearch-ubuntu orb-delete-vm-keycloak-ubuntu orb-delete-vm-ldap1-ubuntu orb-delete-vm-minio-ubuntu orb-delete-vm-nfs-ubuntu orb-delete-vm-redis-ubuntu orb-delete-vm-rtcd-ubuntu orb-delete-vm-monitoring-ubuntu ## Delete all Ubuntu VMs including optional services

orb-delete-vms-rocky: orb-delete-vm-postgresql-rocky ## Delete core Rocky Linux VMs
	@echo "Deleting core Rocky Linux VMs..."
	@orb delete -f mattermost-rocky 2>/dev/null || true
	@orb delete -f mattermost1-rocky 2>/dev/null || true
	@orb delete -f mattermost2-rocky 2>/dev/null || true
	@echo "✓ Core Rocky VMs deleted"

orb-delete-vms-ubuntu: orb-delete-vm-postgresql-ubuntu ## Delete core Ubuntu VMs
	@echo "Deleting core Ubuntu VMs..."
	@orb delete -f mattermost-ubuntu 2>/dev/null || true
	@orb delete -f mattermost1-ubuntu 2>/dev/null || true
	@orb delete -f mattermost2-ubuntu 2>/dev/null || true
	@echo "✓ Core Ubuntu VMs deleted"

ping-local: ## Test connectivity to local VMs
	@$(VENV_ACTIVATE) && ansible all -i inventory/local.ini -m ping

ping-production: ## Test connectivity to production servers
	@$(VENV_ACTIVATE) && ansible all -i inventory/production.ini -m ping

ping-staging: ## Test connectivity to staging servers
	@$(VENV_ACTIVATE) && ansible all -i inventory/staging.ini -m ping

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

test-mattermost-minio: ## Test mattermost role with MinIO object storage
	@echo "Testing mattermost role with MinIO..."
	@$(VENV_ACTIVATE) && cd roles/mattermost && molecule test -s with-minio

test-mattermost-rocky: ## Test mattermost role (Rocky Linux)
	@echo "Testing mattermost role (Rocky Linux)..."
	@$(VENV_ACTIVATE) && cd roles/mattermost && molecule test -s rocky

test-minio: ## Test minio role (Ubuntu - default scenario)
	@echo "Testing minio role (Ubuntu)..."
	@$(VENV_ACTIVATE) && cd roles/minio && molecule test -s default

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

test-ubuntu: test-postgresql test-mattermost test-mattermost-boards test-mattermost-calls test-mattermost-minio test-nginx test-rtcd test-minio ## Run all Ubuntu tests (default scenarios)
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

vault-create-secure: ## Create vault file with auto-generated secure passwords (environment-specific)
	@if [ -f "group_vars/all.yml" ]; then \
		echo "ERROR: group_vars/all.yml already exists"; \
		echo "Use 'make vault-edit' to modify it or remove it first"; \
		exit 1; \
	fi
	@$(VENV_ACTIVATE) && python3 scripts/generate_vault.py > group_vars/all.yml
	@echo "✓ Vault file created at group_vars/all.yml with environment-specific secure passwords"
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

# DISA STIG targets

stig-install: stig-install-all ## Install all official DISA STIG roles (alias for stig-install-all)

stig-install-all: ## Download and install all official DISA STIG roles from dl.dod.cyber.mil
	@echo "Installing all official DISA STIG roles..."
	@$(VENV_ACTIVATE) && python3 scripts/install_disa_stig_roles.py all

stig-install-rhel8: ## Download and install RHEL 8 official DISA STIG role
	@echo "Installing RHEL 8 official DISA STIG role..."
	@$(VENV_ACTIVATE) && python3 scripts/install_disa_stig_roles.py rhel8

stig-install-rhel9: ## Download and install RHEL 9 official DISA STIG role
	@echo "Installing RHEL 9 official DISA STIG role..."
	@$(VENV_ACTIVATE) && python3 scripts/install_disa_stig_roles.py rhel9

stig-install-ubuntu20: ## Download and install Ubuntu 20.04 official DISA STIG role
	@echo "Installing Ubuntu 20.04 official DISA STIG role..."
	@$(VENV_ACTIVATE) && python3 scripts/install_disa_stig_roles.py ubuntu20

stig-install-ubuntu22: ## Download and install Ubuntu 22.04 official DISA STIG role
	@echo "Installing Ubuntu 22.04 official DISA STIG role..."
	@$(VENV_ACTIVATE) && python3 scripts/install_disa_stig_roles.py ubuntu22
