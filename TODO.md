# Mattermost Ansible - TODO

## Overview
This document tracks the implementation of enterprise-scale features for the Mattermost Ansible playbook, with a focus on US DoD/government customer requirements including DISA STIG compliance, AWS staging environments, and automated CI/CD pipelines.

---

## Phase 1: Foundation Services (Redis & Elasticsearch)

### Redis Cache Support
- [x] Review [Deployment guide for Redis in Mattermost](https://docs.mattermost.com/administration-guide/scale/redis.html)
- [x] Review changes needed in Makefile to add separate Redis VM
- [x] Create `roles/redis/` directory structure
- [x] Implement Redis installation (7.4.2 compiled from source, not package repos)
- [x] Create Redis configuration template
- [x] Add systemd service management
- [x] Configure firewall rules (port 6379) - conditional based on firewalld availability
- [x] Add Redis variables to `roles/mattermost/defaults/main.yml`
- [x] Implement Mattermost Redis configuration via mmctl
- [x] Add `[redis]` host group to inventory examples
- [x] Update Makefile with Redis VM targets
- [x] Add Redis password authentication using vault pattern
- [x] Update all environment example files with Redis configuration
- [ ] Create Molecule tests for redis role
- [ ] Write `docs/redis-setup.md` documentation

### Elasticsearch/OpenSearch Support
- [x] Review [Mattermost documentation for Elasticsearch server setup](https://docs.mattermost.com/administration-guide/scale/elasticsearch-setup.html)
- [x] Review changes needed in Makefile to add Elasticsearch VM
- [x] Create `roles/elasticsearch/` directory structure
- [x] Implement Elasticsearch/OpenSearch installation
- [x] Install and configure icu-analyzer plugin
- [x] Create Elasticsearch configuration template
- [x] Add systemd service management
- [x] Configure firewall rules (ports 9200, 9300)
- [x] Add Elasticsearch variables to `roles/mattermost/defaults/main.yml`
- [x] Implement Mattermost Elasticsearch configuration via mmctl
- [x] Add task to trigger initial index build
- [x] Add `[elasticsearch]` host group to inventory examples
- [x] Update Makefile with Elasticsearch VM targets
- [ ] Create Molecule tests for elasticsearch role
- [ ] Write `docs/elasticsearch-setup.md` documentation

---

## Phase 2: High Availability Clustering

### Multi-Node Inventory Support
- [x] Review Mattermost [High availability cluster-based deployment](https://docs.mattermost.com/administration-guide/scale/high-availability-cluster-based-deployment.html) documentation for details on required Mattermost, proxy server, and database configurations.
- [x] Update inventory examples to support multiple Mattermost app nodes
- [x] Add `[loadbalancer]` host group to inventories
- [x] Create example multi-node cluster inventory pattern

### Mattermost Cluster Configuration
- [x] Add cluster variables to `roles/mattermost/defaults/main.yml`:
  - `mattermost_enable_cluster`
  - `mattermost_cluster_name`
  - `mattermost_cluster_use_ip_address`
  - `mattermost_cluster_override_hostname`
  - `mattermost_gossip_port`
  - `mattermost_streaming_port`
  - `mattermost_cluster_read_only_config`
- [x] Add cluster prerequisite validation (database config mode, S3 storage)
- [x] Implement cluster configuration via mmctl
- [x] Add cluster node discovery/registration logic
- [x] Update site.yml to handle multi-node deployments
- [x] Configure firewall rules for gossip and streaming ports

### nginx Load Balancer for HA
- [x] Extend existing `roles/nginx/` for load balancing mode
- [x] Add nginx upstream configuration for multiple app nodes
- [x] Configure load balancing algorithms (round_robin, least_conn, ip_hash)
- [x] Add health check support (max_fails, fail_timeout)
- [x] Configure sticky sessions for WebSocket (ip_hash)
- [x] Update nginx template for multi-node upstream configuration
- [x] Configure TLS termination at load balancer (already supported)
- [x] Update nginx role variables for LB mode:
  - `nginx_mode: "reverse_proxy"` or `"load_balancer"`
  - `nginx_upstream_servers: []` (list of Mattermost nodes)
  - `nginx_lb_algorithm`, `nginx_max_fails`, `nginx_fail_timeout`
- [ ] Create Molecule tests for nginx load balancer mode

### PostgreSQL HA Configuration
- [x] Add PostgreSQL performance tuning variables (max_connections, shared_buffers, etc.)
- [x] Configure PostgreSQL memory settings (work_mem, maintenance_work_mem, effective_cache_size)
- [x] Configure PostgreSQL query planner (random_page_cost for SSD)
- [x] Configure PostgreSQL autovacuum and worker processes
- [x] Configure PostgreSQL WAL settings for replication readiness
- [x] Add replica-specific settings (hot_standby, hot_standby_feedback)
- [x] Add support for DataSourceReplicas (read replicas for load balancing)
- [x] Add support for DataSourceSearchReplicas (dedicated search replicas)
- [x] Configure mmctl to set replica connection strings
- [x] Document database load balancer / managed database recommendations

### System Configuration
- [x] Add system limits configuration (max open files: 65536, max processes: 8192)
- [x] Configure ulimits via /etc/security/limits.conf
- [x] Add NTP time synchronization validation
- [x] Add TCP/IP network optimizations (tcp_tw_reuse, port ranges, keepalive, etc.)
- [x] Configure sysctl parameters for HA cluster performance

### Documentation & Testing
- [x] Update Makefile with HA cluster VM targets
- [x] Document PostgreSQL HA tuning parameters in group_vars examples
- [x] Document system limits and network optimizations in group_vars examples
- [ ] Create integration tests for multi-node cluster
- [ ] Write `docs/high-availability.md` documentation

---

## Phase 3: Advanced Calls Features

> **Architecture Note**: The calls-offloader runs as a native Go binary (systemd service) and requires Docker API access to spawn recorder/transcriber jobs on-demand. The recorder and transcriber are Docker containers managed by the offloader - they are NOT deployed as separate services.
>
> **TURN Server Note**: TURN (Traversal Using Relays around NAT) is needed as a fallback when clients cannot connect through UDP due to restrictive firewalls. Mattermost officially recommends [coturn](https://github.com/coturn/coturn) for TURN services. TURN should be avoided when possible due to increased latency, but is essential for corporate networks that block direct UDP connections.

### TURN Server (coturn) - Optional
- [x] Review [Mattermost Calls deployment documentation](https://docs.mattermost.com/administration-guide/configure/calls-deployment.html) for TURN requirements
- [x] Review [coturn configuration example](https://github.com/mattermost/mattermost-webrtc/blob/master/vagrant/coturn/turnserver.conf)
- [x] Create `roles/coturn/` directory structure
- [x] Implement coturn installation (from package repos)
- [x] Create coturn configuration template (`turnserver.conf`) with all required settings
- [x] Add systemd service management
- [x] Configure firewall rules (ports 3478, 5349, and relay port range)
- [x] Add coturn variables to defaults (all standard coturn settings)
- [x] Document when TURN is needed vs optional (in README)
- [ ] Create Molecule tests for coturn role

### Docker Prerequisites
- [x] Review [calls-offloader documentation](https://github.com/mattermost/calls-offloader/blob/master/docs/getting_started.md) for Docker requirements
- [x] Create `roles/docker/` directory structure
- [x] Implement Docker Engine installation (latest stable)
- [x] Configure Docker daemon settings
- [x] Add Docker group management for service users
- [ ] Create Molecule tests for docker role

### Calls Offloader Service
- [x] Create `roles/calls-offloader/` directory structure
- [x] Implement binary download from GitHub releases
- [x] Create TOML configuration template (verified settings from config.sample.toml)
- [x] Create systemd service unit file
- [x] Add user to docker group in service setup
- [x] Add calls-offloader service management tasks
- [x] Add variables to role defaults (verified from config.sample.toml)
- [ ] Create Molecule tests for calls-offloader role

### RTCD TURN Integration
- [x] Add TURN static auth secret variables to `roles/rtcd/defaults/main.yml` (verified from config.sample.toml)
- [x] Update rtcd configuration template to include TURN settings in `[rtc.turn]` section
- [x] Add logic to automatically configure ICE servers when coturn is deployed
- [ ] Document TURN static auth secret sharing between rtcd and coturn

### Mattermost Calls Plugin Configuration
- [x] Add comprehensive Calls plugin configuration variables (verified from plugin source)
- [x] Configure rtcdserviceurl via mmctl config patch
- [x] Configure enablerecordings via mmctl config patch
- [x] Configure jobserviceurl via mmctl config patch
- [x] Configure recording quality, transcription, and live captions via mmctl config patch
- [x] Add auto-configuration logic for ICE servers from coturn deployment
- [ ] Document Enterprise license requirement for recordings/transcriptions

### Infrastructure
- [x] Add `[coturn]` host group to inventory examples
- [x] Add `[calls_offloader]` host group to inventory examples
- [x] Update Makefile with coturn and calls-offloader VM targets
- [x] Update group_vars examples with coturn and calls-offloader configuration
- [x] Add coturn and calls-offloader plays to site.yml
- [ ] Write `docs/calls-advanced.md` documentation covering:
  - [ ] Architecture overview (RTCD, coturn, offloader + Docker containers)
  - [ ] When TURN is needed vs optional
  - [ ] Docker requirements and network configuration
  - [ ] TURN static auth secret configuration
  - [ ] Troubleshooting Docker and TURN connectivity issues

---

## Phase 4: Prometheus and Grafana Monitoring

> **Monitoring Note**: This phase implements performance monitoring for Mattermost deployments using Prometheus for metrics collection and Grafana for visualization. Mattermost exposes custom metrics at `/metrics` endpoint (requires Enterprise license). This initial implementation focuses on Mattermost application monitoring as described in the official documentation.

### Prometheus Deployment
- [x] Review [Mattermost Prometheus/Grafana documentation](https://docs.mattermost.com/administration-guide/scale/deploy-prometheus-grafana-for-performance-monitoring.html)
- [x] Review [Mattermost performance monitoring metrics](https://docs.mattermost.com/scale/performance-monitoring-metrics.html)
- [x] Create `roles/prometheus/` directory structure
- [x] Implement Prometheus installation (binary download from official releases)
- [x] Create Prometheus configuration template (`prometheus.yml`)
  - [x] Configure scrape_interval: 5s (Mattermost recommendation)
  - [x] Configure evaluation_interval: 5s
  - [x] Add job for Mattermost metrics endpoint (port 8067)
  - [x] Add job for node_exporter on Mattermost app servers
- [x] Create systemd service unit file for Prometheus
- [x] Add Prometheus user and group management
- [x] Configure data retention policies (default 15 days, configurable)
- [x] Configure firewall rules (port 9090 for Prometheus web UI)
- [x] Add Prometheus variables to `roles/prometheus/defaults/main.yml`

### Grafana Deployment
- [x] Create `roles/grafana/` directory structure
- [x] Implement Grafana installation (binary download or package repo)
- [x] Create Grafana configuration template (`grafana.ini`)
  - [x] Configure server settings (port 3000, domain)
  - [x] Configure database (PostgreSQL for HA-ready deployments)
  - [x] Configure database connection (host, port, database name, credentials)
  - [x] Configure authentication (local admin user)
  - [x] Configure security settings (admin password via vault)
- [x] Create Grafana database and user in PostgreSQL
- [x] Create systemd service unit file for Grafana
- [x] Add Grafana user and group management
- [x] Configure firewall rules (port 3000 for Grafana web UI)
- [x] Add Grafana variables to `roles/grafana/defaults/main.yml`:
  - `grafana_database_type: "postgres"`
  - `grafana_database_host`, `grafana_database_port`, `grafana_database_name`
  - `grafana_database_user`, `grafana_database_password` (via vault)
- [x] Provision Prometheus data source automatically via configuration file
- [x] Provision Mattermost dashboards automatically from JSON files

### Node Exporter Deployment
- [x] Create `roles/node_exporter/` directory structure
- [x] Implement node_exporter installation (binary download from Prometheus releases)
- [x] Create systemd service unit file for node_exporter
- [x] Configure node_exporter to expose system metrics (port 9100)
- [x] Configure firewall rules (port 9100, restricted to Prometheus server)
- [x] Add node_exporter variables to defaults
- [x] Deploy node_exporter to Mattermost app servers

### Mattermost Metrics Configuration
- [x] Add performance monitoring variables to `roles/mattermost/defaults/main.yml`:
  - `mattermost_enable_performance_monitoring: false` (opt-in)
  - `mattermost_performance_monitoring_listen_address: ":8067"`
- [x] Configure Mattermost metrics endpoint via mmctl
- [x] Document Enterprise license requirement for /metrics endpoint
- [x] Configure firewall rules (port 8067, restricted to Prometheus server)
- [x] Test metrics endpoint: `curl http://<mattermost-ip>:8067/metrics`

### Grafana Dashboards
- [x] Download official Mattermost Grafana dashboards from Grafana.com:
  - [x] Mattermost Performance Monitoring v2 (ID: 15582)
  - [x] Mattermost Notification Health Monitoring (ID: 21305)
  - [x] Mattermost Web App Performance Metrics (ID: 21460)
  - [x] Mattermost Desktop App Performance Metrics (ID: 22736)
  - [x] Mattermost Mobile App Performance Metrics (ID: 21695)
  - [x] Mattermost Performance KPI Metrics (ID: 2539)
  - [x] Mattermost Bonus Metrics (ID: 2545)
- [x] Store dashboard JSON files in `roles/grafana/files/dashboards/`
- [x] Provision dashboards automatically via Grafana provisioning API
- [x] Fix datasource template variables in provisioned dashboards (${DS_PROMETHEUS}, ${DS_MATTERMOST})

### Alerting Configuration
- [x] Create Prometheus alerting rules file (`alerts.yml`)
- [x] Add critical alerts for Mattermost:
  - [x] Mattermost instance down
  - [x] High API response times (> 1 second)
  - [x] High memory usage (> 90%)
  - [x] High CPU usage (> 80%)
  - [x] Disk space low (< 10% free)
  - [x] WebSocket connections monitoring
  - [x] Database connection monitoring
  - [x] Cache performance monitoring
  - [x] Cluster health monitoring
  - [x] System resource alerts (load, disk I/O, network errors)
- [ ] Configure Alertmanager (optional, for advanced alerting)
- [ ] Add Grafana alert notifications (email, Slack, Mattermost webhook)
- [ ] Test alert firing and notification delivery

### Infrastructure Integration
- [x] Add `[monitoring]` host group to inventory examples
- [x] Update Makefile with monitoring VM targets:
  - [x] `orb-create-vm-monitoring-ubuntu`
  - [x] `orb-create-vm-monitoring-rocky`
  - [x] `orb-delete-vm-monitoring-ubuntu`
  - [x] `orb-delete-vm-monitoring-rocky`
- [x] Update group_vars examples with monitoring configuration
- [x] Add monitoring play to site.yml (deploy Prometheus, Grafana, node_exporter)
- [x] Add conditional logic to deploy node_exporter to Mattermost app servers
- [ ] Document recommended server sizing for monitoring host (2 CPU, 4GB RAM minimum)

### Security and Access Control
- [x] Configure Grafana authentication (admin user via vault)
- [ ] Configure Grafana user roles and permissions
- [x] Restrict Mattermost /metrics endpoint to monitoring server IP
- [x] Use TLS for Grafana (integrate with nginx reverse proxy)
- [x] Use TLS for Prometheus (integrate with nginx reverse proxy)
- [x] Secure node_exporter endpoints (restrict to Prometheus server only)
- [ ] Document security best practices for monitoring stack

### Testing and Validation
- [ ] Create Molecule tests for prometheus role
- [ ] Create Molecule tests for grafana role
- [ ] Create Molecule tests for node_exporter role
- [x] Verify metrics collection from Mattermost endpoints
- [x] Verify dashboard rendering in Grafana
- [ ] Test alert firing and notifications

### Documentation
- [ ] Write `docs/monitoring-setup.md` covering:
  - [ ] Architecture overview (Prometheus, Grafana, node_exporter)
  - [ ] Deployment steps and configuration
  - [ ] Dashboard usage guide
  - [ ] Metrics reference (Mattermost-specific metrics)
  - [ ] Alerting configuration and customization
  - [ ] Troubleshooting monitoring issues
  - [ ] Performance tuning for Prometheus (retention, scrape intervals)
  - [ ] Integration with external monitoring systems (Grafana Cloud, Datadog)
  - [ ] Enterprise license requirement for Mattermost /metrics endpoint
  - [ ] Future enhancements (PostgreSQL, nginx, Redis exporters)

---

## Phase 5: DISA STIG Security Hardening

> **DoD Compliance Note**: This phase implements DISA Security Technical Implementation Guides (STIGs) for US Department of Defense customers. STIGs provide security configuration baselines for government and DoD systems. Findings are categorized as CAT I (critical), CAT II (high), and CAT III (medium) severity.

### STIG Role Selection and Research
- [ ] Evaluate ansible-lockdown STIG roles vs RedHat Official roles
- [ ] Test ansible-lockdown RHEL8-STIG and RHEL9-STIG roles in local environment
- [ ] Test RedHatOfficial.rhel9_stig role in local environment
- [ ] Compare disruption levels and remediation coverage
- [ ] Select primary STIG role approach (recommend: ansible-lockdown + RedHat official as alternative)
- [ ] Document STIG role selection rationale and trade-offs

### STIG Hardening Implementation
- [ ] Install STIG roles via Ansible Galaxy: `ansible-galaxy install ansible-lockdown.RHEL9-STIG RedHatOfficial.rhel9_stig`
- [ ] Create `roles/stig-hardening/` wrapper role for STIG application
- [ ] Add STIG variables to `roles/stig-hardening/defaults/main.yml`:
  - `stig_enabled: false` (opt-in, disabled by default)
  - `stig_provider: "ansible-lockdown"` or `"redhat-official"`
  - `stig_disruption_high: false` (enable disruptive findings)
  - `stig_cat_1_patch: true`, `stig_cat_2_patch: true`, `stig_cat_3_patch: false`
  - `stig_audit_only: false` (scan only, no remediation)
- [ ] Integrate STIG role into site.yml (conditional based on `stig_enabled`)
- [ ] Add STIG configuration to group_vars examples (local.yml, staging.yml, production.yml)
- [ ] Test STIG hardening in local OrbStack VMs
- [ ] Verify Mattermost functionality after STIG hardening

### OpenSCAP Integration
- [ ] Install scap-security-guide package on target systems
- [ ] Add OpenSCAP pre-hardening scan tasks (baseline compliance check)
- [ ] Generate Ansible playbooks from SCAP profiles: `oscap xccdf generate fix --fix-type ansible --profile stig`
- [ ] Add OpenSCAP post-hardening scan tasks (verify compliance)
- [ ] Store compliance reports in `artifacts/scap-reports/` directory
- [ ] Create compliance report parsing and summary tasks
- [ ] Add SCAP scan scheduling capability (cron jobs for continuous compliance)

### STIG Roles for Services
- [ ] Research PostgreSQL STIG hardening requirements
- [ ] Research nginx/web server STIG requirements (consider APACHE-2.4-STIG applicability)
- [ ] Research Docker/container STIG considerations (DISA Container Platform STIG)
- [ ] Research Redis security hardening (no official STIG, use CIS benchmarks)
- [ ] Research Elasticsearch security hardening
- [ ] Document application-level STIG compliance for Mattermost

### Makefile Targets
- [ ] Add `make stig-apply` target (apply STIG hardening to staging/production)
- [ ] Add `make stig-scan` target (run OpenSCAP compliance scan)
- [ ] Add `make stig-report` target (generate and display compliance reports)
- [ ] Add `make stig-audit` target (audit-only mode, no remediation)

### Documentation
- [ ] Write `docs/stig-hardening.md` covering:
  - [ ] Overview of DISA STIGs and DoD compliance requirements
  - [ ] STIG role selection guide (ansible-lockdown vs RedHat official)
  - [ ] CAT I/II/III finding severity levels and risk acceptance
  - [ ] Disruptive vs non-disruptive findings
  - [ ] OpenSCAP scanning and compliance reporting
  - [ ] STIG hardening workflow (scan → harden → verify)
  - [ ] Rollback procedures if hardening breaks functionality
  - [ ] Known limitations and excluded findings
  - [ ] Integration with staging/production deployments

---

## Phase 6: AWS Staging Environment

> **Infrastructure Note**: This phase provisions a realistic staging environment in AWS using Terraform for infrastructure-as-code. The staging environment mirrors production architecture for accurate testing while using cost-optimized resources (spot instances, smaller instance types, auto-stop schedules).

### Terraform Infrastructure Setup
- [ ] Create `terraform/` directory structure (modules/, environments/, backend.tf)
- [ ] Configure Terraform S3 backend with DynamoDB state locking
- [ ] Enable S3 backend encryption for state files
- [ ] Create Terraform workspaces for dev/staging/prod
- [ ] Define reusable Terraform modules (vpc, ec2, security_groups, alb, rds, elasticache)
- [ ] Document Terraform version requirements and provider versions

### AWS Network Infrastructure
- [ ] Define VPC with CIDR ranges (e.g., 10.0.0.0/16)
- [ ] Create public subnets across 2-3 availability zones (for ALB, NAT gateways)
- [ ] Create private subnets across 2-3 availability zones (for app servers, database)
- [ ] Configure internet gateway and NAT gateways
- [ ] Set up route tables for public/private subnets
- [ ] Enable VPC Flow Logs for network traffic monitoring
- [ ] Configure VPC endpoints for S3 (reduce NAT costs)

### AWS Security Groups
- [ ] Create security group for Application Load Balancer (ports 80, 443 from 0.0.0.0/0)
- [ ] Create security group for Mattermost app servers (port 8065 from ALB SG)
- [ ] Create security group for PostgreSQL database (port 5432 from app SG)
- [ ] Create security group for Redis (port 6379 from app SG)
- [ ] Create security group for Elasticsearch (ports 9200, 9300 from app SG)
- [ ] Create security group for SSH bastion (port 22 from trusted IPs)
- [ ] Create security group for RTCD (port 8443 from ALB SG)
- [ ] Create security group for coturn (ports 3478, 5349, 49152-65535 from 0.0.0.0/0)
- [ ] Enable security group logging and monitoring

### AWS Compute Resources
- [ ] Define EC2 instance types per environment (t3.medium for staging, m5.large for prod)
- [ ] Create EC2 launch templates with user_data for initial setup
- [ ] Configure Auto Scaling Groups for app servers (min 1, max 3 for staging)
- [ ] Create spot instance configurations for non-production environments
- [ ] Add EBS volumes with encryption enabled (gp3 for performance)
- [ ] Configure EC2 instance profiles with IAM roles (S3 access, CloudWatch logs)
- [ ] Enable detailed CloudWatch monitoring for EC2 instances
- [ ] Add auto-stop/start schedules for dev environment (save costs)

### AWS Load Balancer and DNS
- [ ] Create Application Load Balancer (ALB) with HTTP/HTTPS listeners
- [ ] Configure ALB target groups for Mattermost (port 8065)
- [ ] Configure ALB health checks (/api/v4/system/ping)
- [ ] Request ACM certificate for domain (*.staging.example.com)
- [ ] Configure HTTPS listener with ACM certificate
- [ ] Set up Route53 hosted zone for domain
- [ ] Create Route53 A record pointing to ALB
- [ ] Configure ALB access logs to S3

### AWS Managed Services (Optional Alternatives)
- [ ] Create RDS PostgreSQL instance (alternative to self-managed PostgreSQL)
  - [ ] Multi-AZ deployment for HA
  - [ ] Automated backups (7-day retention for staging, 30-day for production)
  - [ ] Encryption at rest enabled
  - [ ] Performance Insights enabled
- [ ] Create ElastiCache Redis cluster (alternative to self-managed Redis)
  - [ ] Cluster mode enabled for HA
  - [ ] Encryption in transit and at rest
  - [ ] Automatic failover
- [ ] Document trade-offs: managed services vs self-managed (cost, control, compliance)

### AWS Storage and Backups
- [ ] Create S3 buckets for Mattermost file storage (staging-mattermost-files)
- [ ] Create S3 bucket for backups (staging-mattermost-backups)
- [ ] Create S3 bucket for Terraform state (terraform-state-bucket)
- [ ] Create S3 bucket for ALB access logs
- [ ] Enable S3 bucket encryption (AES-256 or KMS)
- [ ] Configure S3 lifecycle policies (transition to Glacier, expiration)
- [ ] Enable S3 versioning for critical buckets

### Terraform + Ansible Integration
- [ ] Generate dynamic Ansible inventory from Terraform output
- [ ] Create `terraform/outputs.tf` with instance IPs, ALB DNS, security group IDs
- [ ] Write script to populate `inventory/staging.ini` from Terraform output
- [ ] Pass Terraform outputs to Ansible as extra vars
- [ ] Create combined deployment workflow script: `deploy-aws-staging.sh`
  - Step 1: `terraform apply` (provision infrastructure)
  - Step 2: Wait for instances to be ready
  - Step 3: `ansible-playbook -i inventory/staging.ini site.yml` (configure services)
- [ ] Add validation checks between Terraform and Ansible steps

### Cost Optimization
- [ ] Use t3.medium spot instances for staging (70% cost savings)
- [ ] Implement auto-stop schedule for dev environment (Mon-Fri 8am-6pm)
- [ ] Right-size instances based on Mattermost performance requirements
- [ ] Use gp3 EBS volumes instead of gp2 (20% cost savings)
- [ ] Enable S3 Intelligent-Tiering for file storage
- [ ] Set up AWS Cost Explorer tags (Environment:staging, Project:mattermost)
- [ ] Configure AWS Budgets alerts (notify at 80% of monthly budget)
- [ ] Document estimated monthly costs:
  - Dev: ~$50-100/month (with auto-stop)
  - Staging: ~$200-300/month (always-on, spot instances)
  - Production: ~$500-1000/month (always-on, on-demand instances)

### IAM and Security
- [ ] Create IAM roles for EC2 instances (S3 access, CloudWatch, Systems Manager)
- [ ] Create IAM policy for Terraform (least privilege for resource provisioning)
- [ ] Create IAM policy for Ansible (SSM Session Manager access)
- [ ] Enable AWS CloudTrail for audit logging
- [ ] Configure AWS Config rules for compliance checking
- [ ] Enable AWS GuardDuty for threat detection
- [ ] Store AWS credentials in GitHub Secrets (for CI/CD)
- [ ] Document IAM policy requirements in `docs/aws-deployment.md`

### Makefile Targets
- [ ] Add `make aws-init` (initialize Terraform backend)
- [ ] Add `make aws-plan-staging` (Terraform plan for staging)
- [ ] Add `make aws-apply-staging` (Terraform apply for staging)
- [ ] Add `make aws-destroy-staging` (Terraform destroy for staging)
- [ ] Add `make aws-outputs` (display Terraform outputs)
- [ ] Add `make deploy-aws-staging` (full Terraform + Ansible workflow)

### Documentation
- [ ] Write `docs/aws-deployment.md` covering:
  - [ ] AWS architecture diagrams (VPC, subnets, security groups, ALB)
  - [ ] Prerequisites (AWS account, credentials, permissions)
  - [ ] IAM policy requirements (JSON policy documents)
  - [ ] Terraform backend setup (S3 + DynamoDB)
  - [ ] Terraform workspace management (dev/staging/prod)
  - [ ] Cost optimization strategies
  - [ ] Security best practices (encryption, security groups, IAM)
  - [ ] Deployment workflow (terraform apply → ansible deploy)
  - [ ] Troubleshooting common AWS issues (security groups, IAM, network)
  - [ ] Disaster recovery and backup procedures
  - [ ] Managed services trade-offs (RDS vs self-managed PostgreSQL)

---

## Phase 7: CI/CD Pipeline with GitHub Actions

> **Automation Note**: This phase implements continuous integration and continuous deployment (CI/CD) using GitHub Actions. All code changes trigger automated testing (linting, syntax, security, Molecule tests). Deployments to staging are automatic on merge to main, while production deployments require manual approval.

### GitHub Actions Workflow Files
- [ ] Create `.github/workflows/` directory
- [ ] Create `.github/workflows/lint.yml` (ansible-lint on every PR)
  - [ ] Run on pull_request and push to main/develop branches
  - [ ] Use `ansible/ansible-lint-action@main`
  - [ ] Fail PR if linting errors found
  - [ ] Upload lint results as artifacts
- [ ] Create `.github/workflows/test.yml` (Molecule tests on PR/push)
  - [ ] Matrix strategy: Rocky 9, Ubuntu 22.04, Ubuntu 24.04
  - [ ] Run Molecule tests for all roles in parallel
  - [ ] Use Docker driver for fast testing
  - [ ] Cache Docker images to speed up tests
  - [ ] Upload test results as artifacts
- [ ] Create `.github/workflows/security.yml` (security checks)
  - [ ] Check for unencrypted vault files
  - [ ] Run `ansible-vault` validation
  - [ ] Run `pip-audit` or `safety` for Python dependency vulnerabilities
  - [ ] Scan for secrets with `truffleHog` or `gitleaks`
  - [ ] Fail PR if security issues found
- [ ] Create `.github/workflows/stig-scan.yml` (STIG compliance scan)
  - [ ] Deploy to ephemeral staging environment
  - [ ] Run OpenSCAP compliance scan
  - [ ] Generate compliance report
  - [ ] Upload SCAP report as artifact
  - [ ] Comment PR with compliance summary
  - [ ] Destroy ephemeral environment after scan

### Deployment Workflows
- [ ] Create `.github/workflows/deploy-staging.yml` (auto-deploy to AWS staging)
  - [ ] Trigger on push to main branch
  - [ ] Run Terraform plan and apply for staging
  - [ ] Wait for infrastructure to be ready
  - [ ] Run Ansible playbook to configure services
  - [ ] Run smoke tests (health check endpoints)
  - [ ] Send Slack notification on success/failure
  - [ ] Rollback on deployment failure
- [ ] Create `.github/workflows/deploy-production.yml` (manual production deploy)
  - [ ] Trigger on workflow_dispatch (manual trigger)
  - [ ] Require approval from GitHub Environments (production approval gate)
  - [ ] Run Terraform plan and apply for production
  - [ ] Run Ansible playbook with production inventory
  - [ ] Run comprehensive smoke tests
  - [ ] Send Slack/email notification on success/failure
  - [ ] Include rollback instructions in notification

### Terraform Workflows
- [ ] Create `.github/workflows/terraform-validate.yml`
  - [ ] Run `terraform fmt -check` (fail if not formatted)
  - [ ] Run `terraform validate` (validate syntax)
  - [ ] Run `tflint` for Terraform linting
  - [ ] Run `checkov` for Terraform security scanning
- [ ] Create `.github/workflows/terraform-plan.yml`
  - [ ] Run Terraform plan on PR
  - [ ] Comment PR with plan output
  - [ ] Detect resource changes (additions, modifications, deletions)
  - [ ] Require approval if destroying resources
- [ ] Create `.github/workflows/terraform-apply.yml`
  - [ ] Run on merge to main (staging) or manual trigger (production)
  - [ ] Apply Terraform changes
  - [ ] Store plan outputs as artifacts

### Molecule Testing in CI
- [ ] Install Molecule and dependencies in CI: `pip install molecule molecule-docker ansible-lint`
- [ ] Configure Docker-in-Docker for GitHub Actions
- [ ] Use matrix strategy for parallel testing across distributions
- [ ] Cache Docker images: `actions/cache@v4` with key based on Dockerfiles
- [ ] Run Molecule tests for each role:
  - [ ] `cd roles/postgresql && molecule test`
  - [ ] `cd roles/mattermost && molecule test`
  - [ ] `cd roles/nginx && molecule test`
  - [ ] `cd roles/redis && molecule test`
  - [ ] `cd roles/elasticsearch && molecule test`
  - [ ] `cd roles/coturn && molecule test`
  - [ ] `cd roles/rtcd && molecule test`
  - [ ] `cd roles/calls-offloader && molecule test`
- [ ] Generate test coverage reports (if applicable)
- [ ] Upload test results to GitHub Pages or artifacts

### CI/CD Best Practices
- [ ] Configure branch protection rules for main branch:
  - [ ] Require pull request reviews (minimum 1 approval)
  - [ ] Require status checks to pass (lint, test, security)
  - [ ] Dismiss stale PR reviews when new commits pushed
  - [ ] Require linear history (rebase or squash)
  - [ ] Require signed commits (optional)
- [ ] Use GitHub Environments for deployment approval:
  - [ ] Create "staging" environment (auto-deploy, no approval)
  - [ ] Create "production" environment (manual approval required, protected reviewers)
  - [ ] Configure environment secrets (AWS credentials, vault password)
  - [ ] Set deployment branch rules (only main can deploy to production)
- [ ] Store secrets in GitHub Secrets:
  - [ ] `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
  - [ ] `ANSIBLE_VAULT_PASSWORD`
  - [ ] `SLACK_WEBHOOK_URL` (for notifications)
  - [ ] `MATTERMOST_LICENSE_KEY` (for testing)
- [ ] Add status badges to README.md:
  - [ ] Build status badge (lint and test)
  - [ ] Deployment status badge (staging and production)
  - [ ] STIG compliance badge

### Notifications and Monitoring
- [ ] Send Slack notifications on deployment success/failure
- [ ] Send email notifications for production deployments
- [ ] Create GitHub Issue on deployment failure (auto-assign to team)
- [ ] Post deployment summary to Mattermost channel (dogfooding)
- [ ] Track deployment frequency and failure rate metrics

### Rollback Capability
- [ ] Implement automated rollback on failed deployments
- [ ] Store previous Terraform state for rollback
- [ ] Tag Docker images and artifacts with commit SHA
- [ ] Create manual rollback workflow: `.github/workflows/rollback.yml`
  - [ ] Accept previous commit SHA as input
  - [ ] Checkout previous version
  - [ ] Run Terraform apply with previous state
  - [ ] Run Ansible playbook with previous version
  - [ ] Notify team of rollback

### Testing and Validation
- [ ] Test CI/CD workflows in feature branch before merging
- [ ] Verify Terraform state locking (prevent concurrent applies)
- [ ] Test manual approval gates for production
- [ ] Verify rollback procedures work correctly
- [ ] Test notification integrations (Slack, email)

### Makefile Targets
- [ ] Add `make ci-local` (run CI checks locally before pushing)
- [ ] Add `make workflow-test` (test GitHub Actions workflows locally with act)
- [ ] Add `make deploy-staging-ci` (trigger staging deployment from CLI)
- [ ] Add `make deploy-production-ci` (trigger production deployment from CLI)

### Documentation
- [ ] Write `docs/ci-cd.md` covering:
  - [ ] GitHub Actions workflow overview (lint, test, deploy)
  - [ ] Workflow triggers (pull_request, push, workflow_dispatch)
  - [ ] Matrix strategy for parallel testing
  - [ ] Secrets management (GitHub Secrets, AWS credentials)
  - [ ] Deployment approval gates (GitHub Environments)
  - [ ] Rollback procedures (manual and automated)
  - [ ] Notification setup (Slack, email)
  - [ ] Troubleshooting CI failures (logs, artifacts, debugging)
  - [ ] Local testing with `act` (GitHub Actions CLI)
  - [ ] Best practices (branch protection, signed commits, linear history)
- [ ] Add CI/CD architecture diagram to `docs/`
- [ ] Document deployment frequency recommendations:
  - [ ] Staging: Deploy on every merge to main (continuous deployment)
  - [ ] Production: Weekly scheduled deployments + emergency hotfixes
- [ ] Include example workflow YAML files with comments

---

## Documentation & Cleanup

- [ ] Update main `README.md` with new feature overview
- [ ] Add architecture diagrams for HA setup
- [ ] Add DISA STIG compliance badge and documentation links
- [ ] Add AWS deployment instructions and architecture diagrams
- [ ] Add CI/CD pipeline status badges
- [ ] Create example inventory files for each deployment type:
  - Single node (current)
  - With Redis and Elasticsearch
  - 3-node HA cluster with nginx load balancer
  - Full enterprise setup with STIG hardening
  - AWS staging/production environments
- [ ] Update troubleshooting guide
- [ ] Add performance tuning recommendations
- [ ] Document cost optimization strategies for AWS

---

## Notes

### Design Principles
- Follow existing patterns (MinIO, RTCD examples)
- Optional features controlled by `enable_*` flags
- Configuration stored in database (editable via System Console)
- Environment-specific variables in `group_vars/{environment}.yml`
- Comprehensive Molecule tests for each role
- Clear documentation with examples
- Security and compliance by default (opt-in STIG hardening)
- Infrastructure as Code (Terraform for AWS)
- Continuous Integration and Deployment (GitHub Actions)

### Key Dependencies
- **Phase 2 requires Phase 1**: HA needs Redis and S3 (MinIO already implemented)
- **Phase 3 requires Docker**: Recorder and transcriber are containerized
- **Phase 4 (Monitoring) is independent**: Can be deployed to any environment, requires Enterprise license for Mattermost /metrics
- **Phase 5 (STIG) is independent**: Can be applied to any environment
- **Phase 6 requires Terraform**: AWS staging environment needs IaC
- **Phase 7 requires Phase 6**: CI/CD deploys to AWS staging
- **All phases**: Require Enterprise license for some features

### nginx Load Balancing Strategy
- Extend existing nginx role rather than create separate load balancer role
- Use nginx upstream module for multi-node support
- Support both single-node reverse proxy and multi-node load balancer modes
- WebSocket sticky sessions via `ip_hash` or `sticky` directive
- Health checks via `max_fails` and `fail_timeout` parameters

### Testing Environments
- **Local**: OrbStack VMs (amd64) for development and testing
- **Staging**: AWS environment (mirrors production architecture, cost-optimized)
- **Production**: AWS environment (on-demand instances, HA configuration, STIG hardened)

### DoD/Government Compliance Considerations
- **DISA STIGs**: Apply security hardening based on Defense Information Systems Agency guidelines
- **CAT I/II/III Findings**: Critical, high, and medium severity security findings
- **OpenSCAP**: Automated compliance scanning and reporting
- **Risk Acceptance**: Some STIG findings may be too disruptive; document exceptions
- **Continuous Compliance**: Regular SCAP scans (weekly/monthly) to detect drift
- **Audit Logs**: Enable AWS CloudTrail, VPC Flow Logs, application logs for audit trail
- **Encryption**: At-rest and in-transit encryption for all data (databases, S3, EBS)
- **Network Segmentation**: Use security groups and NACLs to isolate tiers

### AWS Architecture Considerations
- **Multi-AZ**: Distribute resources across availability zones for HA
- **Auto Scaling**: Scale Mattermost app servers based on CPU/memory metrics
- **Managed Services**: Trade-off between RDS/ElastiCache (easier) vs self-managed (more control, STIG compliance)
- **Cost vs HA**: Balance cost (single-AZ for staging) vs high availability (multi-AZ for production)
- **Backup Strategy**: RDS automated backups, S3 versioning, EBS snapshots
- **Disaster Recovery**: Document RTO (Recovery Time Objective) and RPO (Recovery Point Objective)

### CI/CD Pipeline Principles
- **Shift Left Security**: Run security checks early in PR process
- **Fast Feedback**: Parallel testing, fast linting, cached dependencies
- **Deployment Automation**: Staging auto-deploys, production requires approval
- **Rollback Safety**: Always have a working previous version to roll back to
- **Observability**: Logs, metrics, notifications for every deployment
- **Infrastructure as Code**: All changes via Terraform (no manual changes in AWS console)
