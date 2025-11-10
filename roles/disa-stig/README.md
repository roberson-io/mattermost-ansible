# DISA STIG Role

This role provides DISA STIG (Security Technical Implementation Guide) hardening for RHEL/Rocky/AlmaLinux and Ubuntu systems. It supports multiple STIG role providers with different characteristics.

## Provider Comparison

### disa-official (Recommended for DoD)

- **Source**: Official DISA STIG roles from dl.dod.cyber.mil
- **Behavior**: Always applies STIG configurations (remediation mode)
- **Audit Mode**: Not supported - role always remediates
- **Control**: Individual rules via `rhel9STIG_stigrule_XXXXX_Manage: true/false`
- **Rules**: 286 controllable rules (263 applicable to typical server configs)
- **Best For**: DoD/Government production deployments

**Installation**:
```bash
./scripts/install_disa_stig_roles.py
```

**Configuration Example**:
```yaml
disa_stig_enabled: true
disa_stig_provider: "disa-official"

# Disable specific rules (e.g., USG banner for non-government systems)
rhel9STIG_stigrule_257779_Manage: false  # USG login banner

# See roles/rhel9STIG/defaults/main.yml for all available rules
```

### ansible-lockdown (Community)

- **Source**: Community-maintained on Ansible Galaxy
- **Behavior**: Separate audit and remediate modes
- **Audit Mode**: Fully supported - generates reports without changes
- **Control**: Category-based (CAT I/II/III) and disruption level
- **Rules**: Variable based on categories enabled
- **Best For**: Testing, non-DoD environments, flexible auditing

**Installation**:
```bash
ansible-galaxy install ansible-lockdown.RHEL9-STIG
```

**Configuration Example**:
```yaml
disa_stig_enabled: true
disa_stig_provider: "ansible-lockdown"
disa_stig_mode: "audit"  # or "remediate"
disa_stig_cat_1_patch: true   # Critical
disa_stig_cat_2_patch: true   # High  
disa_stig_cat_3_patch: false  # Medium
disa_stig_disruption_high: false
```

### redhat-official (ComplianceAsCode)

- **Source**: Red Hat ComplianceAsCode project
- **Behavior**: Applies configurations directly
- **Audit Mode**: Limited support
- **Control**: Profile-based
- **Best For**: Red Hat Enterprise Linux environments

**Installation**:
```bash
ansible-galaxy install RedHatOfficial.rhel9_stig
```

## Important Notes

### Variables That Only Work with ansible-lockdown

These variables are **ignored** by `disa-official` and `redhat-official`:

- `disa_stig_mode` (audit/remediate)
- `disa_stig_cat_1_patch`
- `disa_stig_cat_2_patch`
- `disa_stig_cat_3_patch`
- `disa_stig_disruption_high`

### Controlling disa-official Rules

With `disa-official` provider, control rules individually:

```yaml
# Example: Customize for non-government testing
rhel9STIG_stigrule_257779_Manage: false  # Disable USG banner
rhel9STIG_stigrule_257849_Manage: false  # Disable autofs requirement
```

Find all rules in `roles/rhel9STIG/defaults/main.yml` (286 rules available).

## Compliance Reports

### disa-official

- Generates XCCDF XML report via callback plugin
- Report saved to `compliance-reports/` automatically
- Single consolidated report for all hosts
- Shows pass/fail for 263+ rules

### ansible-lockdown  

- Generates per-host reports in JSON/YAML format
- Requires separate audit run
- Detailed rule-by-rule results

## Recommendations

1. **For DoD/Government deployments**: Use `disa-official`
   - Most authoritative source
   - Direct from DISA
   - Always applies compliant configurations

2. **For testing/development**: Use `ansible-lockdown` 
   - True audit mode (no changes)
   - More flexible control
   - Better for iterative testing

3. **For vendor/contractor testing**: Use `disa-official` with selective rule disabling
   - Disable rules inappropriate for testing (USG banners, etc.)
   - Document which rules customers should enable
   - Provide compliant baseline

## Example: Vendor Test Configuration

```yaml
# For testing STIG compliance without government-specific settings
disa_stig_enabled: true
disa_stig_provider: "disa-official"

# Disable government-specific rules
rhel9STIG_stigrule_257779_Manage: false  # USG login banner

# Document for customers:
# "Government customers should set rhel9STIG_stigrule_257779_Manage: true
#  and configure appropriate agency banner text"
```
