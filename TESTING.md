# Testing Guide

This project uses Molecule for testing Ansible roles with Docker containers.

## Quick Start

Run all tests (Ubuntu + Rocky Linux):
```bash
make test-all
```

Run Ubuntu tests only:
```bash
make test  # or make test-ubuntu
```

Run individual role tests:
```bash
make test-postgresql          # PostgreSQL role (Ubuntu)
make test-mattermost          # Mattermost role (Ubuntu)
make test-mattermost-calls    # Mattermost with Calls configuration (Ubuntu)
make test-mattermost-db-config # Mattermost with database config storage (Ubuntu)
make test-nginx               # Nginx role (Ubuntu)
make test-rtcd                # RTCD service role (Ubuntu)
make test-certbot             # Certbot role (Ubuntu)
```

## Test Status

| Role | Scenarios | Status | Notes |
|------|-----------|--------|-------|
| postgresql | default (Ubuntu), rocky (Rocky Linux) | ✅ **PASSING** | Full test coverage including idempotence |
| mattermost | default (Ubuntu), rocky (Rocky Linux), with-calls (Ubuntu), database-config (Ubuntu) | ✅ **PASSING** | Installation, configuration, license, Calls, and database config storage |
| nginx | default (Ubuntu), rocky (Rocky Linux) | ✅ **PASSING** | Configuration and service setup |
| rtcd | default (Ubuntu) | ✅ **PASSING** | Service installation, firewall, and configuration |
| certbot | default (Ubuntu) | ✅ **PASSING** | Certificate management |

## Prerequisites

- Docker installed and running
- Python 3.8+
- Virtual environment activated

## Setup

1. **Create and activate virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On macOS/Linux
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

## Test Results Summary

### PostgreSQL Role ✅
**Status:** All tests passing

Tests verify:
- PostgreSQL installation and service
- Database creation (mattermost)
- User creation (mmuser) with proper privileges
- Schema permissions
- Idempotence (safe to run multiple times)

### Mattermost Role ⚠️
**Status:** Partial coverage

Tests verify:
- Binary installation
- User creation
- File permissions
- Configuration file updates
- Systemd service file creation

**Known Limitations:**
- Service startup requires actual database connection (integration test scope)
- Service start made non-failing for unit testing purposes

### Nginx Role ⚠️
**Status:** Partial coverage

Tests verify:
- Nginx installation
- Configuration file generation
- Site enablement

**Known Limitations:**
- Service requires upstream backend to start successfully
- Full functionality testing requires integration with Mattermost

## Running Tests

### Using Makefile (Recommended)

The project includes a Makefile with convenient test targets:

**Run all tests:**
```bash
make test-all  # Ubuntu + Rocky + certbot
```

**Run platform-specific tests:**
```bash
make test-ubuntu  # All Ubuntu-based tests
make test-rocky   # All Rocky Linux tests
```

**Run individual role tests:**
```bash
make test-postgresql          # PostgreSQL (Ubuntu)
make test-postgresql-rocky    # PostgreSQL (Rocky Linux)
make test-mattermost          # Mattermost (Ubuntu)
make test-mattermost-calls    # Mattermost with Calls (Ubuntu)
make test-mattermost-rocky    # Mattermost (Rocky Linux)
make test-nginx               # Nginx (Ubuntu)
make test-nginx-rocky         # Nginx (Rocky Linux)
make test-rtcd                # RTCD service (Ubuntu)
make test-certbot             # Certbot (Ubuntu)
```

### Direct Molecule Commands

Each role has its own Molecule test scenario in `roles/<role_name>/molecule/<scenario>/`.

**Test specific scenario:**
```bash
cd roles/mattermost
molecule test -s default      # Ubuntu scenario
molecule test -s rocky        # Rocky Linux scenario
molecule test -s with-calls   # Calls configuration scenario
```

### Molecule Commands

```bash
# Full test lifecycle (create, converge, verify, destroy)
molecule test

# Create test containers
molecule create

# Apply the role (run playbook)
molecule converge

# Run verification tests
molecule verify

# Test idempotence (run twice, should have no changes on second run)
molecule idempotence

# Destroy test containers
molecule destroy

# Login to test container for debugging
molecule login

# Run linting
molecule lint
```

### Test Workflow

The default test sequence is:
1. **dependency** - Install role dependencies
2. **cleanup** - Clean up from previous runs
3. **destroy** - Destroy existing test containers
4. **syntax** - Check playbook syntax
5. **create** - Create test containers
6. **prepare** - Run preparation playbook (if exists)
7. **converge** - Apply the role
8. **idempotence** - Run again and verify no changes
9. **side_effect** - Run side effect playbook (if exists)
10. **verify** - Run verification tests
11. **cleanup** - Clean up
12. **destroy** - Destroy test containers

## Test Structure

### PostgreSQL Role Tests

**Container**: Ubuntu 22.04 with Ansible pre-installed

**Verifies**:
- PostgreSQL is installed and running
- Database `mattermost` is created
- User `mmuser` is created with proper privileges
- Schema permissions are correctly set

### Mattermost Role Tests

**Containers**:
- PostgreSQL 14 database
- Ubuntu 22.04 application server

**Verifies**:
- Mattermost binary is installed
- Mattermost user is created
- Systemd service is configured and running
- Database connection is configured correctly

### Nginx Role Tests

**Container**: Ubuntu 22.04 with Ansible pre-installed

**Verifies**:
- Nginx is installed and running
- Mattermost configuration is created
- Reverse proxy is configured correctly

### RTCD Role Tests

**Container**: Ubuntu 22.04 with Ansible pre-installed

**Verifies**:
- RTCD binary is downloaded and installed
- rtcd user and directories are created
- Configuration file is properly templated
- Systemd service is configured and enabled
- Firewall rules are applied (ufw/firewalld)

### Mattermost with Calls Tests

**Scenario**: `with-calls` in mattermost role

**Containers**:
- PostgreSQL 14 database
- Ubuntu 22.04 application server

**Configuration**:
- `enable_calls: true`
- `mattermost_rtcd_host: "192.168.1.100"`

**Verifies**:
- All standard Mattermost installation steps
- RTCD service URL is configured in config.json at path:
  `PluginSettings.Plugins.com.mattermost.calls.rtcdserviceurl`
- Configuration is idempotent (no changes on subsequent runs)

### Mattermost with Database Config Tests

**Scenario**: `database-config` in mattermost role

**Containers**:
- PostgreSQL 14 database
- Ubuntu 22.04 application server

**Configuration**:
- `mattermost_config_storage: "database"`
- Database connection configuration

**Verifies**:
- All standard Mattermost installation steps
- Environment file (`mattermost.environment`) exists with `MM_CONFIG` variable
- Systemd service configured with `EnvironmentFile` directive
- Mattermost API is accessible and responding
- Configuration is managed through database instead of config.json

## Continuous Integration

For CI/CD pipelines, you can run tests in parallel:

```bash
# Run all role tests in parallel
cd roles/postgresql && molecule test &
cd roles/mattermost && molecule test &
cd roles/nginx && molecule test &
wait
```

## Debugging Failed Tests

If tests fail:

1. **Keep containers running after failure:**
   ```bash
   molecule converge  # Run without destroy
   molecule login     # SSH into container
   ```

2. **Check container logs:**
   ```bash
   docker logs <container_name>
   ```

3. **Manually verify state:**
   ```bash
   molecule login
   # Inside container:
   systemctl status postgresql
   sudo -u postgres psql -l
   ```

4. **Run verification manually:**
   ```bash
   molecule verify
   ```

## Writing New Tests

### Adding Verification Tests

Edit `roles/<role>/molecule/default/verify.yml`:

```yaml
---
- name: Verify
  hosts: all
  gather_facts: false
  tasks:
    - name: Check service is running
      ansible.builtin.systemd:
        name: myservice
        state: started
      check_mode: yes
      register: svc_check
      failed_when: svc_check is changed
```

### Testing Different Scenarios

Create additional scenarios:

```bash
cd roles/postgresql
molecule init scenario production
```

Edit `roles/postgresql/molecule/production/molecule.yml` with production-like settings.

## Best Practices

1. **Keep tests fast** - Use Docker, not full VMs
2. **Test idempotence** - Roles should be safe to run multiple times
3. **Test different platforms** - Use multiple container images
4. **Verify actual behavior** - Don't just check files exist, verify services work
5. **Clean up** - Always destroy containers after tests

## Troubleshooting

**Docker permission errors:**
```bash
# Add your user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

**Container won't start:**
```bash
# Check Docker is running
docker ps

# Pull required images manually
docker pull geerlingguy/docker-ubuntu2204-ansible:latest
docker pull postgres:14
```

**Molecule command not found:**
```bash
# Ensure virtual environment is activated
source venv/bin/activate

# Verify installation
molecule --version
```

## Resources

- [Molecule Documentation](https://molecule.readthedocs.io/)
- [Ansible Testing Strategies](https://docs.ansible.com/ansible/latest/dev_guide/testing.html)
- [Testinfra Documentation](https://testinfra.readthedocs.io/)
