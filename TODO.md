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
- [ ] Review [Mattermost documentation for Elasticsearch server setup](https://docs.mattermost.com/administration-guide/scale/elasticsearch-setup.html)
- [ ] Review changes needed in Makefile to add Elasticsearch VM
- [ ] Create `roles/elasticsearch/` directory structure
- [ ] Implement Elasticsearch/OpenSearch installation
- [ ] Install and configure icu-analyzer plugin
- [ ] Create Elasticsearch configuration template
- [ ] Add systemd service management
- [ ] Configure firewall rules (ports 9200, 9300)
- [ ] Add Elasticsearch variables to `roles/mattermost/defaults/main.yml`
- [ ] Implement Mattermost Elasticsearch configuration via mmctl
- [ ] Add task to trigger initial index build
- [ ] Add `[elasticsearch]` host group to inventory examples
- [ ] Update Makefile with Elasticsearch VM targets
- [ ] Create Molecule tests for elasticsearch role
- [ ] Write `docs/elasticsearch-setup.md` documentation

---

## Phase 2: High Availability Clustering

### Multi-Node Inventory Support
- [ ] Update inventory examples to support multiple app nodes
- [ ] Add `[loadbalancer]` host group to inventories
- [ ] Create example 3-node cluster inventory

### Mattermost Cluster Configuration
- [ ] Add cluster variables to `roles/mattermost/defaults/main.yml`:
  - `mattermost_enable_cluster`
  - `mattermost_cluster_name`
  - `mattermost_cluster_bind_address`
  - `mattermost_cluster_advertise_address`
  - `mattermost_gossip_port`
  - `mattermost_streaming_port`
- [ ] Add cluster prerequisite validation (database config mode, S3 storage)
- [ ] Implement cluster configuration via mmctl
- [ ] Add cluster node discovery/registration logic
- [ ] Update site.yml to handle multi-node deployments

### nginx Load Balancer for HA
- [ ] Extend existing `roles/nginx/` for load balancing mode
- [ ] Add nginx upstream configuration for multiple app nodes
- [ ] Configure round-robin or least-connected load balancing
- [ ] Add health check support (`/api/v4/system/ping`)
- [ ] Configure sticky sessions for WebSocket (ip_hash or sticky cookie)
- [ ] Add load balancer-specific templates
- [ ] Configure TLS termination at load balancer
- [ ] Update nginx role variables for LB mode:
  - `nginx_mode: "reverse_proxy"` or `"load_balancer"`
  - `nginx_upstream_servers: []` (list of Mattermost nodes)
- [ ] Create Molecule tests for nginx load balancer mode

### Documentation & Testing
- [ ] Update Makefile with HA cluster VM targets
- [ ] Create integration tests for 3-node cluster
- [ ] Write `docs/high-availability.md` documentation
- [ ] Document PostgreSQL HA considerations (external/managed DB recommended)

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
