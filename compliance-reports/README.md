# DISA STIG Compliance Reports

This directory contains DISA STIG compliance audit reports generated from test deployments. These reports demonstrate the security posture and compliance status of the Mattermost deployment when STIG hardening is applied.

## Report Format

Reports are in **XCCDF 1.2 XML format** - the standard DoD/DISA compliance format. Each report contains:

- **STIG Rule Checks**: Individual security requirements (identified by vulnerability IDs like V-257779)
- **Pass/Fail Status**: Whether the system complies with each requirement
- **Severity**: CAT I (Critical), CAT II (High), CAT III (Medium)
- **Timestamps**: When the audit was performed
- **Target Host**: Which system was audited

## Viewing Reports

### Option 1: STIG Viewer (Recommended for DoD)
Download the official STIG Viewer from https://public.cyber.mil/stigs/srg-stig-tools/

### Option 2: Convert to HTML
```bash
# Install xsltproc if needed
brew install libxslt  # macOS
# or
sudo apt install xsltproc  # Ubuntu

# Convert XML to HTML (requires XCCDF stylesheet)
xsltproc -o report.html /path/to/xccdf-stylesheet.xsl hostname_rhel9_stig_audit.xml
```

### Option 3: Parse with Python
```python
import xml.etree.ElementTree as ET

tree = ET.parse('hostname_rhel9_stig_audit.xml')
root = tree.getroot()

# Extract results
for result in root.findall('.//{http://checklists.nist.gov/xccdf/1.2}rule-result'):
    rule_id = result.get('idref')
    status = result.find('{http://checklists.nist.gov/xccdf/1.2}result').text
    print(f"{rule_id}: {status}")
```

## Report Naming Convention

Reports are named: `{hostname}_{distro}_stig_audit.xml`

Examples:
- `postgresql-rocky_rhel9_stig_audit.xml` - PostgreSQL server audit
- `mattermost1-rocky_rhel9_stig_audit.xml` - Mattermost app server 1 audit
- `loadbalancer-rocky_rhel9_stig_audit.xml` - Load balancer audit

## Understanding Results

### Result Values
- **pass**: System complies with the STIG requirement
- **fail**: System does not comply (needs remediation)
- **notapplicable**: Requirement doesn't apply to this system
- **notchecked**: Check was skipped
- **error**: Unable to determine compliance

### Severity Levels
- **CAT I (high)**: Critical vulnerabilities - immediate remediation required
- **CAT II (medium)**: High risk - remediation required
- **CAT III (low)**: Medium risk - remediation recommended

## Iterating on Compliance

These reports help identify which STIG findings need attention:

1. **Review Reports**: Identify failing checks
2. **Analyze Findings**: Determine if remediation is appropriate for Mattermost
3. **Apply Fixes**: Update roles/configuration to address findings
4. **Re-audit**: Run deployment again to verify improvements
5. **Commit Updated Reports**: Track progress over time

Some findings may be risk-accepted if they conflict with Mattermost functionality.

## Generating Fresh Reports

To generate new audit reports:

```bash
# Enable STIG auditing in group_vars/local.yml:
# disa_stig_enabled: true
# disa_stig_mode: "audit"
# disa_stig_provider: "disa-official"

# Run deployment
make deploy-local

# Reports will be automatically fetched to this directory
```

## Current Status

Reports in this directory represent the compliance state of the **local test deployment** using OrbStack VMs with Rocky Linux 9.

Last updated: Check git commit history for latest audit date
