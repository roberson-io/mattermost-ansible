# Mattermost Ansible - TODO

## Overview
This document tracks the implementation of enterprise-scale features for the Mattermost Ansible playbook.

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
- [x] Add basic Calls plugin configuration variables (verified from plugin source)
- [x] Configure rtcdserviceurl via mmctl
- [x] Configure enablerecordings via mmctl
- [x] Configure jobserviceurl via mmctl
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

## Documentation & Cleanup

- [ ] Update main `README.md` with new feature overview
- [ ] Add architecture diagrams for HA setup
- [ ] Create example inventory files for each deployment type:
  - Single node (current)
  - With Redis and Elasticsearch
  - 3-node HA cluster with nginx load balancer
  - Full enterprise setup
- [ ] Update troubleshooting guide
- [ ] Add performance tuning recommendations

---

## Notes

### Design Principles
- Follow existing patterns (MinIO, RTCD examples)
- Optional features controlled by `enable_*` flags
- Configuration stored in database (editable via System Console)
- Environment-specific variables in `group_vars/{environment}.yml`
- Comprehensive Molecule tests for each role
- Clear documentation with examples

### Key Dependencies
- **Phase 2 requires Phase 1**: HA needs Redis and S3 (MinIO already implemented)
- **Phase 3 requires Docker**: Recorder and transcriber are containerized
- **All phases**: Require Enterprise license for some features

### nginx Load Balancing Strategy
- Extend existing nginx role rather than create separate load balancer role
- Use nginx upstream module for multi-node support
- Support both single-node reverse proxy and multi-node load balancer modes
- WebSocket sticky sessions via `ip_hash` or `sticky` directive
- Health checks via `max_fails` and `fail_timeout` parameters

### Testing Environments
- Local: OrbStack VMs (amd64)
- Staging: Cloud VMs (example)
- Production: Cloud VMs with HA (example)
