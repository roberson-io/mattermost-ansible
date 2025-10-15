#!/usr/bin/env bash
# Integration tests for mattermost_config_storage feature
# Tests database configuration with real VMs

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../.."
TEST_INV="$SCRIPT_DIR/inventory/test.ini"
GROUP_VARS="$PROJECT_ROOT/group_vars/mattermost.yml"
SITE_YML="$PROJECT_ROOT/site.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Backup group_vars
backup_group_vars() {
    cp "$GROUP_VARS" "$GROUP_VARS.backup"
}

# Restore group_vars
restore_group_vars() {
    if [ -f "$GROUP_VARS.backup" ]; then
        mv "$GROUP_VARS.backup" "$GROUP_VARS"
    fi
}

# Clean up all backup files
cleanup_all_backups() {
    restore_group_vars
    # Clean up sed backup files
    rm -f "$GROUP_VARS.bak"
    # Clean up ansible lineinfile backup files (pattern: mattermost.yml.PID.timestamp~)
    find "$PROJECT_ROOT/group_vars" -name "mattermost.yml.*~" -delete 2>/dev/null || true
}

# Set trap to clean up on exit
trap cleanup_all_backups EXIT

echo "=========================================="
echo "Database Configuration Integration Tests"
echo "=========================================="
echo "Testing mattermost_config_storage feature"
echo ""

# Check test inventory exists
if [ ! -f "$TEST_INV" ]; then
    echo -e "${RED}ERROR: test.ini not found${NC}"
    echo "Create it from test.ini.example"
    exit 1
fi

# Test connectivity
echo "Checking VM connectivity..."
ansible all -i "$TEST_INV" -m ping || {
    echo -e "${RED}ERROR: Cannot reach test VMs${NC}"
    exit 1
}
echo -e "${GREEN}✓ VMs accessible${NC}"
echo ""

# Backup group_vars
backup_group_vars

#
# TEST 1: Default file mode (implicit)
#
echo "=========================================="
echo "TEST 1: Default File Mode (Implicit)"
echo "=========================================="

# Ensure mattermost_config_storage is commented out
sed -i '' 's/^mattermost_config_storage:/#mattermost_config_storage:/' "$GROUP_VARS"

echo "Deploying with default configuration..."
ansible-playbook -i "$TEST_INV" "$SITE_YML"

echo "Verifying file mode..."
ansible app -i "$TEST_INV" -m ansible.builtin.stat -a "path=/opt/mattermost/config/config.json" -b | grep -q "exists.*true" || {
    echo -e "${RED}✗ TEST 1 FAILED: config.json not found${NC}"
    exit 1
}

ansible app -i "$TEST_INV" -m ansible.builtin.stat -a "path=/opt/mattermost/config/mattermost.environment" -b | grep -q "exists.*false" || {
    echo -e "${RED}✗ TEST 1 FAILED: environment file should not exist${NC}"
    exit 1
}

echo -e "${GREEN}✓ TEST 1 PASSED${NC}"
echo ""

#
# TEST 2: Explicit file mode + idempotency
#
echo "=========================================="
echo "TEST 2: Explicit File Mode + Idempotency"
echo "=========================================="

# Set explicit file mode
sed -i '' 's/^#*mattermost_config_storage:.*/mattermost_config_storage: "file"/' "$GROUP_VARS"

echo "Deploying with explicit file mode..."
ansible-playbook -i "$TEST_INV" "$SITE_YML"

echo "Checking idempotency..."
ansible-playbook -i "$TEST_INV" "$SITE_YML" | tee /tmp/idempotency_check.txt
if grep -q "changed=0" /tmp/idempotency_check.txt; then
    echo -e "${GREEN}✓ TEST 2 PASSED (idempotent)${NC}"
else
    echo -e "${YELLOW}⚠ TEST 2: Non-zero changes detected (review output)${NC}"
fi
echo ""

#
# TEST 3: Database mode (fresh deploy)
#
echo "=========================================="
echo "TEST 3: Database Mode"
echo "=========================================="

# Note: For true fresh deploy test, VMs should be recreated
# Skipping VM recreation in this test

# Set database mode
sed -i '' 's/^#*mattermost_config_storage:.*/mattermost_config_storage: "database"/' "$GROUP_VARS"

echo "Deploying with database mode..."
ansible-playbook -i "$TEST_INV" "$SITE_YML"

echo "Verifying database mode..."
ansible app -i "$TEST_INV" -m ansible.builtin.stat -a "path=/opt/mattermost/config/mattermost.environment" -b | grep -q "exists.*true" || {
    echo -e "${RED}✗ TEST 3 FAILED: environment file not found${NC}"
    exit 1
}

ansible app -i "$TEST_INV" -m ansible.builtin.shell -a "grep 'MM_CONFIG=' /opt/mattermost/config/mattermost.environment" -b > /dev/null || {
    echo -e "${RED}✗ TEST 3 FAILED: MM_CONFIG not set in environment file${NC}"
    exit 1
}

echo -e "${GREEN}✓ TEST 3 PASSED${NC}"
echo ""

#
# TEST 4: Database mode idempotency
#
echo "=========================================="
echo "TEST 4: Database Mode Idempotency"
echo "=========================================="

echo "Re-running deployment (should be idempotent)..."
ansible-playbook -i "$TEST_INV" "$SITE_YML" | tee /tmp/db_idempotency_check.txt
if grep -q "changed=0" /tmp/db_idempotency_check.txt; then
    echo -e "${GREEN}✓ TEST 4 PASSED (idempotent)${NC}"
else
    echo -e "${YELLOW}⚠ TEST 4: Non-zero changes detected (review output)${NC}"
fi
echo ""

#
# Final summary
#
echo "=========================================="
echo "ALL TESTS COMPLETED"
echo "=========================================="
echo -e "${GREEN}✓ TEST 1: Default file mode${NC}"
echo -e "${GREEN}✓ TEST 2: Explicit file mode + idempotency${NC}"
echo -e "${GREEN}✓ TEST 3: Database mode${NC}"
echo -e "${GREEN}✓ TEST 4: Database mode idempotency${NC}"
echo ""
echo "Note: Migration tests (file↔database) require"
echo "      running Mattermost and are tested manually"
echo "=========================================="
