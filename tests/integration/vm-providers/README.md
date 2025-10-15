# VM Provider Helpers

These scripts help you quickly set up test VMs for integration testing.

## Quick Start

### OrbStack (macOS)
```bash
./orbstack.sh create
make test-integration-check-vms
make test-integration
```

### Multipass (Linux/macOS/Windows)
```bash
./multipass.sh create
make test-integration-check-vms
make test-integration
```

### Vagrant
```bash
cd vagrant/
vagrant up
# Manually create tests/integration/inventory/test.ini
```

### Manual Setup
1. Create 3 VMs with your preferred tool:
   - test-postgresql
   - test-mattermost
   - test-rtcd
2. Copy `tests/integration/inventory/test.ini.example` to `test.ini`
3. Update with your VM connection details
4. Run: `make test-integration-check-vms`

## VM Requirements

- **OS**: Rocky Linux 9 or Ubuntu 22.04
- **Resources**: 2 CPU, 2GB RAM, 10GB disk minimum
- **Network**: VMs must be able to reach each other
- **SSH**: Accessible from your machine running Ansible

## Helper Script Commands

Each provider script supports:
- `create` - Create VMs and generate test.ini
- `delete` - Remove test VMs
- `setup-inventory` - Regenerate test.ini (VMs must exist)
- `verify` - Check if VMs are running

Example:
```bash
./orbstack.sh create    # Set up everything
./orbstack.sh verify    # Check VMs are running
./orbstack.sh delete    # Clean up when done
```

## Troubleshooting

### VMs won't start
```bash
# OrbStack
orb list
orb logs test-postgresql

# Multipass
multipass list
multipass info test-postgresql
```

### Ansible can't connect
```bash
# Test connectivity
make test-integration-check-vms

# Check inventory
cat ../inventory/test.ini

# Test SSH manually
ssh user@test-postgresql@orb  # OrbStack
ssh ubuntu@<IP>               # Multipass
```

### Clean slate
```bash
# Delete and recreate
./orbstack.sh delete
./orbstack.sh create
```
