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

### Docker Prerequisites
- [ ] Create `roles/docker/` if not exists
- [ ] Implement Docker engine installation
- [ ] Configure Docker daemon
- [ ] Add Docker user/group management

### Calls Offloader Service
- [ ] Create `roles/calls-offloader/` directory structure
- [ ] Implement Go build process from source
- [ ] Create TOML configuration template
- [ ] Add systemd service management
- [ ] Configure integration with RTCD
- [ ] Add job queue configuration
- [ ] Add firewall rules
- [ ] Create Molecule tests for calls-offloader role

### Calls Recorder Integration
- [ ] Create `roles/calls-recorder/` directory structure
- [ ] Implement Docker container deployment
- [ ] Create environment variable configuration
- [ ] Add Docker Compose file or systemd unit for container
- [ ] Configure bot user credentials
- [ ] Integrate with calls-offloader
- [ ] Add Molecule tests for calls-recorder role

### Calls Transcriber Integration
- [ ] Create `roles/calls-transcriber/` directory structure
- [ ] Implement Docker container deployment
- [ ] Create environment variable configuration
- [ ] Add Docker Compose file or systemd unit for container
- [ ] Configure transcription service settings
- [ ] Integrate with calls-offloader
- [ ] Add Molecule tests for calls-transcriber role

### Mattermost Calls Plugin Configuration
- [ ] Extend Calls plugin configuration variables
- [ ] Add recording bot credentials configuration
- [ ] Add transcription service URL configuration
- [ ] Add offloader service URL configuration
- [ ] Implement configuration via mmctl
- [ ] Update existing RTCD configuration for offloader integration

### Infrastructure
- [ ] Add `[calls-offloader]` host group to inventories
- [ ] Update Makefile with Calls VM targets
- [ ] Write `docs/calls-advanced.md` documentation

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
